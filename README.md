# Kgoro — Ke ya hao, ke ya rona (Yours, ours)

A groceries + food + cab super-app built exclusively for **Thaba Nchu**, Free State — combining an Uber/SweepSouth-style multi-service model with a residency-gated marketplace and a fairness-first driver matching system designed to create real income opportunities for local, including unskilled, residents.

Thaba Nchu is a historic Barolong Boo-Seleka town roughly 60–70km east of Bloemfontein, with high unemployment and limited formal-economy access — which is the direct reason this app is scoped to one town instead of trying to be a generic national platform.

---

## 1. What's in this zip

```
kgoro/
├── lib/
│   ├── core/            theme, constants (Thaba Nchu geofence, local areas), validators/geo utils
│   ├── models/           AppUser, DriverProfile, Vendor, Product, KgoroOrder, RideRequest
│   ├── services/          MatchingAlgorithm, PricingService, ResidencyVerificationService,
│   │                      AuthService, FirestoreService
│   ├── providers/         Riverpod state (auth, cart, driver profile, etc.)
│   ├── screens/           splash, onboarding, auth (OTP), home, groceries, food, cab,
│   │                      checkout, orders, profile, driver application/dashboard, admin
│   └── widgets/           shared UI components
├── test/                  unit tests for the matching algorithm & pricing logic
├── functions/             Node.js Cloud Functions skeleton (server-side dispatch)
├── firestore.rules        security rules (role-based, residency-aware)
├── storage.rules          security rules for uploaded ID/proof-of-address documents
├── pubspec.yaml
└── README.md              ← you are here
```

---

## 2. The name & identity

**Kgoro** (Setswana/Sesotho) means *gateway* — the entrance to a homestead or a community gathering place. It reads as "the way in" to everything Thaba Nchu has to offer. Colour palette is drawn directly from the town: **terracotta/maroon** for Thaba 'Nchu itself ("Black Mountain"), **gold** for Naledi ("star" — after the well-known Naledi Sun hotel), and **deep green** for the surrounding farmland.

---

## 3. The core idea: three services, one app

| Service | Status | Notes |
|---|---|---|
| **Groceries** | UI complete, demo data | Vendor list from Firestore; product catalogue is currently a hardcoded demo list per vendor (see §6) |
| **Food** | UI complete, demo data | Same pattern as groceries, filtered by `ServiceType.food` |
| **Cab** | UI complete, simplified fare calc | Area-to-area dropdown booking; needs real geocoding for accurate fares/routing (see §6) |

---

## 4. What makes this *Thaba Nchu's* app, not a generic clone

### Residency gating (`lib/services/residency_service.dart`)
South African ID numbers don't encode a hometown, and there's no public API to confirm "this person lives in Thaba Nchu." So the app layers several weaker, checkable signals instead of relying on one:

1. **GPS bounding box** at signup — device must be physically near town (generous box covering Selosesha, Kromdraai, Rietfontein, Sediba, Setlogelo, Ratlou, etc.)
2. **Fixed local-area dropdown** instead of free-text address (faster on low-end phones, harder to fake casually)
3. **Uploaded proof of address** (municipal bill, ward/Kgotla letter, school letter) — reviewed by an admin
4. **SA ID document upload + format/checksum validation**
5. **Community vouching** — two existing verified users vouch for a new driver applicant, which matters in a town this size where people generally know each other

Customers get a light-touch check (mostly GPS + area selection) so genuinely local people aren't locked out over a GPS hiccup. **Driver applicants** need the fuller stack because they're trusted with deliveries, cash, and community trust — this is enforced both in the app UI and in `firestore.rules` (a user cannot set their own `approvalStatus` to `approved`; only an admin custom-claim can).

### Fairness-capped surge pricing (`lib/services/pricing_service.dart`)
Surge is capped at **1.3×** (vs the 2–5× common on Uber-style platforms) because this app exists to serve one town's residents, not to extract maximum revenue during a taxi strike or bad-weather spike — exactly the moments locals can least afford it. The multiplier is a transparent demand/supply ratio, not an opaque model, so it can be explained.

### The fair-match algorithm (`lib/services/matching_algorithm.dart`) — see §5

---

## 5. The job-creation algorithm (the part you specifically asked about)

A naive "closest driver wins" matcher — what most gig apps use — consistently starves everyone except the top 10–15% of drivers, usually the ones who already own a car and can afford to sit near the busiest pickup point all day. In a town where the explicit goal is creating opportunity for **unskilled, currently unemployed** residents (some of whom may only have a bicycle), that's the opposite of the mission.

Instead, every open job scores each *online, approved* driver on four weighted factors:

```
score = 0.40 × proximity + 0.25 × fairness + 0.25 × reliability + 0.10 × vehicleFit
```

- **Proximity** — closer drivers are still preferred (this isn't charity, customers still want fast delivery)
- **Fairness** — drivers who haven't worked recently get a boost, capped at 6 hours idle, so jobs spread across the *whole* active pool instead of a small clique
- **Reliability** — rating + historical acceptance rate, so quality still matters
- **Vehicle fit** — a bicycle courier isn't offered a 12km grocery run; a car/bakkie is favoured in bad weather

This is a **simple, explainable weighted-sum model, not a black-box ML ranker**, deliberately — so town admins (and drivers themselves, via "How jobs are matched to you" on the dashboard) can understand *why* a job went where it did. That transparency matters in a small community where people will compare notes.

**Dispatch pattern:** rather than offering a job to driver #1, waiting for a timeout, then trying #2 (which wastes minutes when there might only be a handful of drivers online at 9pm on a Tuesday), the top 3 ranked candidates are offered the job simultaneously; first to accept wins, the others are notified it's taken. The Dart version (`MatchingAlgorithm.rankDrivers`) is what powers in-app estimates and is fully unit-tested (`test/matching_and_pricing_test.dart`); the Node.js mirror in `functions/index.js` is what should actually run the real assignment server-side once deployed, since client code must never be trusted to pick its own driver.

### Where AI could extend this (not yet built — see §7)
- A **demand-prediction model** trained on historical order timestamps/areas to pre-position drivers before predictable rushes (month-end, weekends, school pickup times) — currently `PricingService.demandMultiplier` uses a live ratio, not a forecast
- **Fraud/anomaly detection** on repeated GPS spoofing patterns at signup, flagged for admin review rather than auto-rejected
- A **document OCR/verification assist** (e.g. calling a vision model) to pre-screen uploaded ID/proof-of-address quality before it reaches a human reviewer, cutting approval turnaround
- **Route optimisation** for multi-stop grocery/food runs during busy periods

These are deliberately left as documented extension points rather than half-built, because dropping in a real ML pipeline needs real historical data this app doesn't have yet — see §8.

---

## 6. Working vs. not-yet-working features

### ✅ Fully working (logic-complete, unit-tested where relevant)
- Theme, branding, navigation shell, onboarding (App uses new Light Blue/White visual identity)
- `MatchingAlgorithm` — ranks drivers, excludes unapproved/out-of-range drivers, fairness behaviour verified by tests
- `PricingService` — fare/delivery-fee estimation, surge cap verified by tests
- `ResidencyVerificationService` — layered scoring for customer vs. driver-applicant checks
- `Validators` — SA ID checksum validation, SA phone format validation (E.164 verified)
- `GeoUtils` — Haversine distance, bounding-box residency pre-check (unit-tested)
- Cart state management (add/remove/quantity, vendor-switch clears cart)
- All screen UIs render and navigate correctly with real types and safe casting (`KgoroOrder`, `Vendor`)
- Driver Jobs Dashboard — Dispatch logic integration, Offers Tab, Job acceptance tracking
- Vendor Dashboard — Image uploads to Firebase Storage (`vendor.imageUrl`), Menu management via CSV/manual entry
- Live Order Tracking — View real-time order status updates via `OrderTrackingScreen`
- Password Reset Flow (`sendPasswordResetEmail`) in Login screen
- App Icon configuration via `flutter_launcher_icons` (Run `flutter pub run flutter_launcher_icons` to generate)

### ⚠️ Wired to Firebase but **requires you to add your own project** to actually run
Everything touching `FirebaseAuth`, `Firestore`, or `FirebaseStorage` is written against the real Firebase SDKs and will compile, but **will not connect to any backend** until you run `flutterfire configure` and replace `lib/firebase_options.dart` (currently a placeholder with fake keys, deliberately, per your request):
- Phone OTP sign-in and Email/Password flows
- User profile creation/reads/edits
- Driver application submission + document upload
- Vendor/product listing streams (with Banner Image uploads)
- Order and ride creation
- Admin approval actions
- Online/offline toggle + location updates
- Real-time order tracking and driver dispatch streams

### ❌ Not yet implemented (stubbed or simplified — flagged in code comments)
- **Live driver tracking on a map** — `google_maps_flutter` is a dependency but no map view is built yet; cab booking and order tracking are currently area-dropdown based, not pin-drop/live-location based.
- **Push notifications** — `firebase_messaging` is a dependency; no FCM token registration or notification handling is implemented yet. The "offer job to top 3 drivers simultaneously" dispatch pattern needs this to actually notify anyone.
- **Payments** — no payment gateway integrated (cash-on-delivery is implicit). South African options to evaluate: Yoco, PayFast, Ozow, or SnapScan.
- **Server-side dispatch is a skeleton, not deployed** — `functions/index.js` shows the intended pattern but the accept/reject transaction and push-notification step are marked `TODO`.
- **Admin auth gating** — the in-app Admin screen has **no access control** yet; it's reachable from any Profile screen for demo purposes. Firestore rules correctly block non-admins from *writing* approval decisions, but you must add a real role check (custom claims) before shipping, and ideally hide the UI entry point too.
- **Rate limiting / abuse prevention** — no protection yet against spam order creation, repeated OTP requests, or fake vouching rings.
- **Offline support / local caching** — Firestore's default offline persistence isn't explicitly configured or tested here.
- **Localisation** — UI text is in English only; Setswana/Sesotho translations would matter a lot for genuine local adoption.
- **Accessibility pass** — no explicit screen-reader labelling/contrast audit done yet.

---

## 7. Honest assessment: what to improve next (priority order)

1. **Deploy Firebase + test the auth → order → driver-match loop end-to-end** with real (even if fake/test) data. Nothing above has been run against a live backend — it's written correctly but unverified in practice.
2. **Lock down the Admin screen** behind a real role check before anyone else touches this code — right now it's a visible menu item for any signed-in user.
3. **Build the vendor product catalogue properly** (Firestore-backed, with a way for vendors/admins to add products) — the demo list will look obviously fake to real users immediately.
4. **Wire up `google_maps_flutter` and `geocoding`** for real pickup/drop-off pins and accurate fare distances — the area-dropdown approach is a reasonable v1 but caps how good the cab experience can be.
5. **Deploy the Cloud Function dispatch + FCM push** — right now "fair matching" is provably correct in isolation (unit tests pass) but nothing actually notifies a driver of a new job in the running app.
6. **Add a lightweight vendor onboarding flow** (even just an admin-assisted Google Form → manual Firestore entry initially) so real Thaba Nchu shops/kitchens can get listed without needing their own dashboard on day one.
7. **Payment integration** — decide cash-on-delivery-only for v1 (simplest, matches how many informal-economy transactions already happen locally) vs. adding a SA payment gateway.
8. **Once there's 2-3 months of real order data**, revisit §5's "where AI could extend this" list — demand prediction genuinely needs historical patterns to be useful; building it before you have data would just be guessing.
9. **Community trust-building features**: in-app driver photos/names (once approved), a simple ratings-and-review loop, and a visible "X jobs completed by Thaba Nchu residents this month" counter — small things that reinforce this is a community platform, not an anonymous extraction platform.
10. **Load-test the fairness algorithm's weights** once real usage exists — 0.40/0.25/0.25/0.10 is a reasonable starting point, not something empirically tuned yet.

---

## 8. Firebase & keys setup (the "human touch" parts you mentioned)

You said you'll add Firebase keys yourself — here's exactly what's needed and where:

1. **Create a Firebase project** at console.firebase.google.com
2. Enable **Authentication → Phone** sign-in method
3. Enable **Firestore Database** (start in production mode, then deploy `firestore.rules` from this repo)
4. Enable **Storage** (deploy `storage.rules` from this repo)
5. Install the FlutterFire CLI and run it from the project root:
   ```
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   This overwrites the placeholder `lib/firebase_options.dart` with real values and downloads `google-services.json` (Android) / `GoogleService-Info.plist` (iOS) automatically.
6. For Android phone-auth silent verification, add your debug **and** release **SHA-1/SHA-256** fingerprints in Project Settings → Your Android app.
7. **Google Maps API key** (once you wire up `google_maps_flutter`, see §6/§7): add to `android/app/src/main/AndroidManifest.xml` under `com.google.android.geo.API_KEY`, and to `ios/Runner/AppDelegate.swift`.
8. **Set the first admin** manually via the Firebase Admin SDK (cannot be done from the client, by design):
   ```js
   admin.auth().setCustomUserClaims(uid, { admin: true });
   ```
9. Deploy Cloud Functions once you're ready to move dispatch server-side:
   ```
   cd functions && npm install
   firebase deploy --only functions,firestore:rules,storage
   ```

---

## 9. Running the app

```bash
flutter pub get
flutter test              # run the algorithm/pricing unit tests
flutter run                # after Firebase is configured per §8
```

Without Firebase configured, the app will build and the UI/navigation/onboarding will work, but sign-in and any data screens will fail to connect — that's expected and by design per your request to add real keys yourself.

---

## 10. Philosophy recap (for anyone reviewing this later)

This isn't "Uber but smaller." The scoping decisions throughout — the residency gate, the capped surge pricing, the fairness term in matching, the vouching system, the explainable (non-black-box) algorithm — all trace back to one goal: **a platform that puts real income in the hands of Thaba Nchu residents who might otherwise have no formal-economy access, without becoming another app that quietly funnels most of the value to whoever already had an advantage.** Where that goal conflicts with "maximum growth" or "maximum revenue" playbook decisions, this build chose the town over the metric.
