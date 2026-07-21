/**
 * Cloud Functions — Complete production implementation
 *
 * Deploy:  cd functions && npm install && cd .. && firebase deploy --only functions
 *
 * Functions:
 *   onOrderCreated    — match driver, deduct stock, send FCM offers to top 3
 *   onRideCreated     — match driver, send FCM offers to top 3
 *   onDriverAccept    — driver accepts a job (callable), transactional assignment
 *   setAdminClaim     — callable (existing-admin only) to grant admin custom claim
 *   onVendorApproved  — notify vendor owner via FCM when their app is approved
 */

const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { onCall, HttpsError }                   = require('firebase-functions/v2/https');
const { initializeApp }                         = require('firebase-admin/app');
const { getFirestore, FieldValue }              = require('firebase-admin/firestore');
const { getMessaging }                          = require('firebase-admin/messaging');
const { getAuth }                               = require('firebase-admin/auth');

initializeApp();
const db  = getFirestore();
const fcm = getMessaging();
const auth = getAuth();

// ─── Constants ───────────────────────────────────────────────────────────────

const MAX_RADIUS_KM  = 12;
const OFFER_WINDOW_S = 45; // seconds drivers have to accept before next offer
const TOP_N_DRIVERS  = 3;

const WEIGHTS = {
  proximity:   0.40,
  fairness:    0.25,
  reliability: 0.25,
  vehicleFit:  0.10,
};

// ─── Helpers ─────────────────────────────────────────────────────────────────

function haversineKm(lat1, lng1, lat2, lng2) {
  const R    = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLng = ((lng2 - lng1) * Math.PI) / 180;
  const a    = Math.sin(dLat / 2) ** 2 +
               Math.cos((lat1 * Math.PI) / 180) *
               Math.cos((lat2 * Math.PI) / 180) *
               Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function vehicleFitScore(vehicleType, jobDistanceKm) {
  switch (vehicleType) {
    case 0: // footOrBicycle
      if (jobDistanceKm <= 2) return 1.0;
      if (jobDistanceKm <= 4) return 0.5;
      return 0.05;
    case 1: // motorbike
      return jobDistanceKm <= 8 ? 1.0 : 0.4;
    case 2: // car
      return 0.85;
    case 3: // bakkie
      return jobDistanceKm > 6 ? 1.0 : 0.7;
    default:
      return 0.5;
  }
}

function scoreDriver(driverDoc, pickupLat, pickupLng, jobDistanceKm) {
  const d = driverDoc.data();
  if (!d.currentLat || !d.currentLng) return null;

  const distance = haversineKm(pickupLat, pickupLng, d.currentLat, d.currentLng);
  if (distance > MAX_RADIUS_KM) return null;

  const proximity   = 1 - Math.min(distance / MAX_RADIUS_KM, 1);
  const idleMinutes = d.lastJobCompletedAt
    ? Math.min((Date.now() - d.lastJobCompletedAt.toMillis()) / 60000, 360)
    : 360;
  const fairness    = idleMinutes / 360;
  const totalOffers = d.totalOffers || 1;
  const acceptance  = (d.acceptedOffers || 0) / totalOffers;
  const reliability = ((d.rating || 5) / 5) * 0.6 + acceptance * 0.4;
  const fit         = vehicleFitScore(d.vehicleType ?? 2, jobDistanceKm);

  const score = WEIGHTS.proximity   * proximity  +
                WEIGHTS.fairness    * fairness   +
                WEIGHTS.reliability * reliability +
                WEIGHTS.vehicleFit  * fit;

  return { driverId: driverDoc.id, score, distance };
}

/**
 * Sends an FCM push offer to an array of driver UIDs.
 * Looks up each driver's FCM token from /fcm_tokens/{uid}.
 */
async function sendJobOffers(driverIds, payload) {
  const tokenDocs = await Promise.all(
    driverIds.map((id) => db.collection('fcm_tokens').doc(id).get())
  );
  const tokens = tokenDocs
    .filter((d) => d.exists && d.data().token)
    .map((d) => d.data().token);

  if (tokens.length === 0) return;

  await fcm.sendEachForMulticast({
    tokens,
    notification: { title: payload.title, body: payload.body },
    data:         payload.data,
    android:      { priority: 'high' },
    apns:         { payload: { aps: { sound: 'default', badge: 1 } } },
  });
}

// ─── 1. New Order → match + stock deduct + FCM ───────────────────────────────

exports.onOrderCreated = onDocumentCreated('orders/{orderId}', async (event) => {
  const orderId  = event.params.orderId;
  const orderRef = event.data.ref;
  const order    = event.data.data();

  const vendorRef = db.collection('vendors').doc(order.vendorId);

  // ── Atomic stock check + deduction ──────────────────────────────────────────
  try {
    await db.runTransaction(async (tx) => {
      for (const item of order.items) {
        const productRef = vendorRef.collection('products').doc(item.productId);
        const productDoc = await tx.get(productRef);
        if (!productDoc.exists) throw new Error(`Product ${item.productId} not found`);

        const qty = productDoc.data().quantity ?? 0;
        if (qty < item.qty) {
          throw new Error(`Insufficient stock for ${item.name}: only ${qty} left`);
        }
        tx.update(productRef, { quantity: FieldValue.increment(-item.qty) });
      }
      // Mark stock confirmed
      tx.update(orderRef, { stockConfirmed: true });
    });
  } catch (err) {
    // Stock unavailable — cancel order immediately
    await orderRef.update({
      status:            6, // cancelled
      cancellationReason: err.message,
    });
    return;
  }

  // ── Driver matching ──────────────────────────────────────────────────────────
  const pickupLat    = order.vendorLat  ?? -29.2;
  const pickupLng    = order.vendorLng  ?? 26.8;
  const jobDistance  = order.jobDistanceKm ?? 3;

  const driversSnap = await db.collection('drivers')
    .where('isOnline', '==', true)
    .where('approvalStatus', '==', 1)
    .get();

  const scored = driversSnap.docs
    .map((d) => scoreDriver(d, pickupLat, pickupLng, jobDistance))
    .filter(Boolean)
    .sort((a, b) => b.score - a.score)
    .slice(0, TOP_N_DRIVERS);

  const candidateIds = scored.map((s) => s.driverId);

  await orderRef.update({
    candidateDriverIds: candidateIds,
    dispatchedAt:       new Date().toISOString(),
    offerExpiresAt:     new Date(Date.now() + OFFER_WINDOW_S * 1000).toISOString(),
  });

  // ── FCM push to top drivers ──────────────────────────────────────────────────
  if (candidateIds.length > 0) {
    await sendJobOffers(candidateIds, {
      title: '🚀 New delivery job',
      body:  `Pickup at ${order.vendorName ?? 'a store'} — R${order.total?.toFixed(2)} delivery`,
      data: {
        type:    'NEW_ORDER',
        orderId,
        vendorId: order.vendorId,
      },
    });
  }
});

// ─── 2. New Ride → match + FCM ───────────────────────────────────────────────

exports.onRideCreated = onDocumentCreated('rides/{rideId}', async (event) => {
  const rideId  = event.params.rideId;
  const rideRef = event.data.ref;
  const ride    = event.data.data();

  const pickupLat   = ride.pickupLat   ?? -29.2;
  const pickupLng   = ride.pickupLng   ?? 26.8;
  const jobDistance = ride.estimatedKm ?? 5;

  const driversSnap = await db.collection('drivers')
    .where('isOnline', '==', true)
    .where('approvalStatus', '==', 1)
    .get();

  const scored = driversSnap.docs
    .map((d) => scoreDriver(d, pickupLat, pickupLng, jobDistance))
    .filter(Boolean)
    .sort((a, b) => b.score - a.score)
    .slice(0, TOP_N_DRIVERS);

  const candidateIds = scored.map((s) => s.driverId);

  await rideRef.update({
    candidateDriverIds: candidateIds,
    dispatchedAt:       new Date().toISOString(),
    offerExpiresAt:     new Date(Date.now() + OFFER_WINDOW_S * 1000).toISOString(),
  });

  if (candidateIds.length > 0) {
    await sendJobOffers(candidateIds, {
      title: '🚕 New ride request',
      body:  `${ride.pickupArea} → ${ride.dropoffArea} · est. R${ride.estimatedFare?.toFixed(2)}`,
      data: {
        type:   'NEW_RIDE',
        rideId,
      },
    });
  }
});

// ─── 3. Driver accepts a job (callable) ──────────────────────────────────────

exports.acceptJob = onCall(async (request) => {
  const { orderId, rideId } = request.data;
  const driverId = request.auth?.uid;
  if (!driverId) throw new HttpsError('unauthenticated', 'Must be signed in');

  if (orderId) {
    const orderRef = db.collection('orders').doc(orderId);
    await db.runTransaction(async (tx) => {
      const doc = await tx.get(orderRef);
      if (!doc.exists) throw new HttpsError('not-found', 'Order not found');
      const data = doc.data();
      if (data.status !== 0) throw new HttpsError('failed-precondition', 'Order already taken');
      if (!data.candidateDriverIds?.includes(driverId)) {
        throw new HttpsError('permission-denied', 'You were not offered this job');
      }
      tx.update(orderRef, {
        driverId,
        status:    1, // matched
        acceptedAt: new Date().toISOString(),
      });
    });

    // Notify customer
    const orderDoc = await db.collection('orders').doc(orderId).get();
    const customerId = orderDoc.data()?.customerId;
    if (customerId) {
      await sendJobOffers([customerId], {
        title: '✅ Driver found!',
        body:  'Your order has been accepted and is being prepared.',
        data:  { type: 'ORDER_ACCEPTED', orderId },
      });
    }
    return { success: true };
  }

  if (rideId) {
    const rideRef = db.collection('rides').doc(rideId);
    await db.runTransaction(async (tx) => {
      const doc = await tx.get(rideRef);
      if (!doc.exists) throw new HttpsError('not-found', 'Ride not found');
      const data = doc.data();
      if (data.status !== 0) throw new HttpsError('failed-precondition', 'Ride already taken');
      if (!data.candidateDriverIds?.includes(driverId)) {
        throw new HttpsError('permission-denied', 'You were not offered this ride');
      }
      tx.update(rideRef, {
        driverId,
        status:     1, // matched
        acceptedAt: new Date().toISOString(),
      });
    });

    const rideDoc    = await db.collection('rides').doc(rideId).get();
    const customerId = rideDoc.data()?.customerId;
    if (customerId) {
      await sendJobOffers([customerId], {
        title: '🚕 Driver on the way!',
        body:  'Your driver has accepted your ride.',
        data:  { type: 'RIDE_ACCEPTED', rideId },
      });
    }
    return { success: true };
  }

  throw new HttpsError('invalid-argument', 'Must provide orderId or rideId');
});

// ─── 4. Admin claim setter (callable — existing admins only) ─────────────────

exports.setAdminClaim = onCall(async (request) => {
  // Only existing admins may grant the admin claim
  if (!request.auth?.token?.admin) {
    throw new HttpsError('permission-denied', 'Only admins may grant admin claims');
  }

  const { targetUid } = request.data;
  if (!targetUid) throw new HttpsError('invalid-argument', 'targetUid required');

  await auth.setCustomUserClaims(targetUid, { admin: true });

  // Persist in Firestore so the claim survives token refresh
  await db.collection('users').doc(targetUid).update({ role: 3 }); // 3 = admin
  return { success: true };
});

// ─── 5. Bootstrap first admin (HTTP — delete after first use!) ───────────────
// Call once: curl -X POST https://<REGION>-<PROJECT>.cloudfunctions.net/bootstrapAdmin
// Then IMMEDIATELY delete this export and redeploy.
// exports.bootstrapAdmin = require('firebase-functions/v2/https').onRequest(async (req, res) => {
//   const uid = req.query.uid;  // pass ?uid=YOUR_FIREBASE_UID
//   if (!uid) { res.status(400).send('uid required'); return; }
//   await auth.setCustomUserClaims(uid, { admin: true });
//   await db.collection('users').doc(uid).update({ role: 3 });
//   res.send(`Admin claim set for ${uid}. Delete this function now.`);
// });

// ─── 6. Vendor approved → notify owner ──────────────────────────────────────

exports.onVendorApproved = onDocumentUpdated('vendors/{vendorId}', async (event) => {
  const before = event.data.before.data();
  const after  = event.data.after.data();

  // Fire only when transitioning from pendingReview(0) → approved(1)
  if (before.approvalStatus !== 0 || after.approvalStatus !== 1) return;

  const ownerId = after.ownerId;
  if (!ownerId) return;

  await sendJobOffers([ownerId], {
    title: '🎉 Your store is approved!',
    body:  `${after.name} is now live on Kgoro. Start adding your products!`,
    data:  { type: 'VENDOR_APPROVED', vendorId: event.params.vendorId },
  });
});
