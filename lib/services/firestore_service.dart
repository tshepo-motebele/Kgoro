import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import '../core/constants.dart';

/// Firestore collection map:
///   users/{uid}
///   drivers/{uid}
///   vendors/{vendorId}
///   vendors/{vendorId}/products/{productId}
///   orders/{orderId}
///   rides/{rideId}
///   vouches/{voucherUid}_{applicantUid}
///   fcm_tokens/{uid}
class FirestoreService {
  final _db = FirebaseFirestore.instance;

  // ---- Users ----
  Future<void> upsertUser(AppUser user) =>
      _db.collection('users').doc(user.id).set(user.toMap(), SetOptions(merge: true));

  Stream<AppUser?> watchUser(String uid) => _db
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((d) => d.exists ? AppUser.fromMap(d.id, d.data()!) : null);

  Stream<List<AppUser>> watchAllUsers() => _db
      .collection('users')
      .snapshots()
      .map((s) => s.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList());

  Future<void> deleteUser(String uid) => _db.collection('users').doc(uid).delete();

  // ---- Drivers ----
  Future<void> submitDriverApplication(DriverProfile profile) => _db
      .collection('drivers')
      .doc(profile.userId)
      .set(profile.toMap(), SetOptions(merge: true));

  Stream<DriverProfile?> watchDriverProfile(String uid) => _db
      .collection('drivers')
      .doc(uid)
      .snapshots()
      .map((d) => d.exists ? DriverProfile.fromMap(d.id, d.data()!) : null);

  Stream<List<DriverProfile>> watchOnlineApprovedDrivers() => _db
      .collection('drivers')
      .where('isOnline', isEqualTo: true)
      .where('approvalStatus', isEqualTo: ApprovalStatus.approved.index)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => DriverProfile.fromMap(d.id, d.data())).toList());

  Future<void> setDriverOnlineStatus(String uid, bool online) =>
      _db.collection('drivers').doc(uid).update({'isOnline': online});

  Future<void> updateDriverLocation(String uid, double lat, double lng) =>
      _db.collection('drivers').doc(uid).update({
        'currentLat': lat,
        'currentLng': lng,
      });

  // ---- Admin: driver approval queue ----
  Stream<List<DriverProfile>> watchPendingDriverApplications() => _db
      .collection('drivers')
      .where('approvalStatus', isEqualTo: ApprovalStatus.pendingReview.index)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => DriverProfile.fromMap(d.id, d.data())).toList());

  Future<void> setDriverApprovalStatus(String uid, ApprovalStatus status) =>
      _db.collection('drivers').doc(uid).update({
        'approvalStatus': status.index,
      });

  Stream<List<DriverProfile>> watchAllDrivers() => _db
      .collection('drivers')
      .snapshots()
      .map((s) => s.docs.map((d) => DriverProfile.fromMap(d.id, d.data())).toList());

  Future<void> deleteDriver(String uid) => _db.collection('drivers').doc(uid).delete();

  // ---- Vouching ----
  Future<void> addVouch(
      {required String voucherUid, required String applicantUid}) async {
    await _db.collection('vouches').doc('${voucherUid}_$applicantUid').set({
      'voucherUid': voucherUid,
      'applicantUid': applicantUid,
      'createdAt': DateTime.now().toIso8601String(),
    });
    await _db.collection('drivers').doc(applicantUid).update({
      'vouchedByUserIds': FieldValue.arrayUnion([voucherUid]),
    });
  }

  // ---- Vendors (customer-facing reads) ----
  Stream<List<Vendor>> watchVendorsByType(ServiceType type) => _db
      .collection('vendors')
      .where('type', isEqualTo: type.index)
      .where('approvalStatus', isEqualTo: ApprovalStatus.approved.index)
      .snapshots()
      .map((s) => s.docs.map((d) => Vendor.fromMap(d.id, d.data())).toList());

  Stream<List<Product>> watchVendorProducts(String vendorId) => _db
      .collection('vendors')
      .doc(vendorId)
      .collection('products')
      .snapshots()
      .map((s) => s.docs.map((d) => Product.fromMap(d.id, vendorId, d.data())).toList());

  // ---- Vendors (vendor self-service) ----

  /// Submits a new vendor application (creates the vendors doc pending approval).
  Future<DocumentReference> submitVendorApplication(Map<String, dynamic> data) =>
      _db.collection('vendors').add(data);

  /// Returns the vendor doc owned by [ownerUid], or null if none exists yet.
  Stream<Vendor?> watchVendorByOwner(String ownerUid) => _db
      .collection('vendors')
      .where('ownerId', isEqualTo: ownerUid)
      .limit(1)
      .snapshots()
      .map((s) => s.docs.isEmpty ? null : Vendor.fromMap(s.docs.first.id, s.docs.first.data()));

  /// Live stream of this vendor's incoming orders.
  Stream<List<KgoroOrder>> watchVendorOrders(String vendorId) => _db
      .collection('orders')
      .where('vendorId', isEqualTo: vendorId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => KgoroOrder.fromMap(d.id, d.data())).toList());

  // ---- Admin: vendor approval queue ----
  Stream<List<Vendor>> watchPendingVendorApplications() => _db
      .collection('vendors')
      .where('approvalStatus', isEqualTo: ApprovalStatus.pendingReview.index)
      .snapshots()
      .map((s) => s.docs.map((d) => Vendor.fromMap(d.id, d.data())).toList());

  Future<void> setVendorApprovalStatus(String vendorId, ApprovalStatus status) =>
      _db.collection('vendors').doc(vendorId).update({
        'approvalStatus': status.index,
      });

  Stream<List<Vendor>> watchAllVendors() => _db
      .collection('vendors')
      .snapshots()
      .map((s) => s.docs.map((d) => Vendor.fromMap(d.id, d.data())).toList());

  Future<void> deleteVendor(String vendorId) => _db.collection('vendors').doc(vendorId).delete();

  // ---- Products (vendor CRUD) ----
  Future<DocumentReference> addProduct(String vendorId, Map<String, dynamic> data) =>
      _db.collection('vendors').doc(vendorId).collection('products').add(data);

  Future<void> updateProduct(String vendorId, String productId, Map<String, dynamic> data) =>
      _db.collection('vendors').doc(vendorId).collection('products').doc(productId).update(data);

  Future<void> deleteProduct(String vendorId, String productId) =>
      _db.collection('vendors').doc(vendorId).collection('products').doc(productId).delete();

  /// Updates store settings fields on the vendor doc.
  Future<void> updateVendorSettings(String vendorId, Map<String, dynamic> data) =>
      _db.collection('vendors').doc(vendorId).update(data);

  Stream<List<KgoroOrder>> watchAllOrders() => _db
      .collection('orders')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => KgoroOrder.fromMap(d.id, d.data())).toList());

  // ---- Orders ----
  Future<DocumentReference> createOrder(Map<String, dynamic> orderData) =>
      _db.collection('orders').add(orderData);

  /// Returns a typed live stream of all orders for [uid] as customer.
  Stream<List<KgoroOrder>> watchCustomerOrders(String uid) => _db
      .collection('orders')
      .where('customerId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => KgoroOrder.fromMap(d.id, d.data())).toList());

  /// Returns a typed live stream of a single order document.
  Stream<KgoroOrder?> watchOrder(String orderId) =>
      _db.collection('orders').doc(orderId).snapshots().map(
            (d) => d.exists ? KgoroOrder.fromMap(d.id, d.data()!) : null,
          );

  Future<void> updateOrderStatus(String orderId, OrderStatus status) =>
      _db.collection('orders').doc(orderId).update({'status': status.index});

  /// Cancels an order — only valid while status is still [OrderStatus.pending].
  Future<void> cancelOrder(String orderId, {String? reason}) =>
      _db.collection('orders').doc(orderId).update({
        'status': OrderStatus.cancelled.index,
        if (reason != null) 'cancellationReason': reason,
      });

  // ---- Rides ----
  Future<DocumentReference> createRideRequest(Map<String, dynamic> data) =>
      _db.collection('rides').add(data);

  /// Returns a typed live stream of a single ride document.
  Stream<RideRequest?> watchRide(String rideId) =>
      _db.collection('rides').doc(rideId).snapshots().map(
            (d) => d.exists ? RideRequest.fromMap(d.id, d.data()!) : null,
          );

  /// Returns a typed live stream of all rides requested by [uid].
  Stream<List<RideRequest>> watchCustomerRides(String uid) => _db
      .collection('rides')
      .where('customerId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => RideRequest.fromMap(d.id, d.data())).toList());

  Future<void> updateRideStatus(String rideId, OrderStatus status) =>
      _db.collection('rides').doc(rideId).update({'status': status.index});

  // ---- FCM Token management ----
  /// Deletes the FCM token document for [uid]. Call on sign-out to prevent
  /// the Cloud Function from sending notifications to a stale device.
  Future<void> deleteToken(String uid) async {
    try {
      await _db.collection('fcm_tokens').doc(uid).delete();
    } catch (_) {
      // Token may not exist if this is a new device or already deleted.
    }
  }
}
