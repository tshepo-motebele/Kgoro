# Kgoro — Feature Audit & Recommended Fixes

**Scope of this audit:** every file in `Kgoro-main.zip` was read directly (not inferred from the README/planning docs, which are stale in places — noted below). This covers `lib/`, `functions/index.js`, `firestore.rules`, `storage.rules`, `pubspec.yaml`, `android/`, and the test suite.

---

## 🚨 Build-blocking issues (fix these first — the app cannot run at all right now)

| # | Issue | Where | Why it blocks everything |
|---|---|---|---|
| 1 | **`lib/firebase_options.dart` does not exist anywhere in the zip** | `lib/main.dart` imports it and calls `DefaultFirebaseOptions.currentPlatform` | This is a straight compile error (`Target of URI doesn't exist`). The README claims this file exists as "a placeholder with fake keys" — it doesn't; it's simply missing. Run `flutterfire configure` to generate it. |
| 2 | **`.env` does not exist — only `.env.template` does** | `pubspec.yaml` lists `.env` as a required asset; `main.dart` calls `await dotenv.load(fileName: '.env')` before `runApp()` | `flutter pub get`/build will fail asset bundling because a declared asset file is missing, and even if that were bypassed, `dotenv.load` throws on a missing file, crashing the app before Firebase even initializes. **Fix:** `cp .env.template .env` and fill in real values (Firebase keys aren't needed here since those live in `firebase_options.dart`, but `GOOGLE_MAPS_API_KEY`, PayFast keys, and support contact fields do live here). |

Until both of these are fixed, `flutter run` will not get past startup — this isn't a "some features are stubbed" situation, it's "the app doesn't launch."

---

## ✅ Fully working (real logic, not stubs)

These are implemented completely and, once the two blockers above are fixed and a real Firebase project is wired up, should work as-is:

- **Theme & branding** — light-blue/white identity (`lib/core/theme.dart`) is fully implemented for light and dark mode, with legacy color aliases so old screens still compile.
- **Onboarding, splash, auth UI** — email/password sign-up and login, forgot-password flow (`sendPasswordResetEmail`), role dropdown correctly excludes "Administrator" from public sign-up.
- **Residency verification** (`residency_service.dart`) — layered scoring for customers vs. driver applicants, fully implemented, no gaps.
- **Matching algorithm** (`matching_algorithm.dart`) — the fairness-weighted driver-ranking logic (proximity/fairness/reliability/vehicleFit) is complete and covered by `test/matching_and_pricing_test.dart` (12 test cases).
- **Pricing service** (`pricing_service.dart`) — fare/delivery-fee estimation and the 1.3× surge cap, also test-covered.
- **Validators & GeoUtils** (`core/utils.dart`) — SA ID checksum validation, SA phone regex, Haversine distance, bounding-box check. Solid.
- **Cart state** (Riverpod `CartNotifier`) — add/remove/quantity, vendor-switch clears cart, immutable state updates.
- **All 5 customer service tabs** (Groceries, Food, Liquor, Cab, Laundry) — each reads live Firestore streams, has loading/empty states, and pushes to a detail/booking screen. Genuinely no hardcoded/demo data left in these screens.
- **Vendor dashboard** — Orders tab (grouped by status, one-tap advance), Menu tab (add/edit/delete, low-stock badges, **CSV bulk import** via plain string parsing), Settings tab (open/closed, banner upload, contact/address). This is fully built, not a placeholder.
- **Vendor & driver onboarding → pending-approval → dashboard flow** (`app.dart` `_VendorGate`, `DriverDashboardScreen`) — mirrors correctly for both roles, including "rejected" and "more info needed" states.
- **Admin dashboard** — two tabs (Drivers, Vendors), approve/reject wired to Firestore, gated in the UI by `user.role == UserRole.admin` (see Security section for the caveat on this).
- **Cloud Functions** (`functions/index.js`) — this is much further along than the README states: real driver-matching + FCM push on order/ride creation, **atomic stock deduction via Firestore transaction** (cancels the order automatically if stock runs out), a transactional `acceptJob` callable (first driver to accept wins, others are locked out), an admin-claim setter restricted to existing admins, a vendor-approved push notification, and GDPR-style cleanup on account deletion. None of this is a skeleton — it's complete, just **not deployed** (see Wired-but-needs-setup below).
- **Firestore security rules** (`firestore.rules`) — genuinely well thought out: users can't self-elevate role/residency on *update*, drivers/vendors can't self-approve, vendor owners are scoped correctly, one real gap noted below under Security.
- **Storage rules** (`storage.rules`) — driver documents private, vendor images public-read/owner-write, all with file-size and content-type checks.
- **Live order tracking** (`order_tracking_screen.dart`) — real-time status banner + step timeline + driver info card, streamed from Firestore.
- **Cab booking map** — contrary to the README's claim that no map view exists, `cab_booking_screen.dart` **does** render a real `GoogleMap` widget with pickup/drop-off markers and camera bounds-fitting. It's area-based (not live GPS pins), but it is a real map, not a stub.
- **Driver job offers** (`driver_jobs_screen.dart`) — accept/decline UI correctly calls the `acceptJob` Cloud Function callable, not a local Firestore write, so the "first to accept wins" guarantee is actually enforced server-side.
- **App icon generation config** — `flutter_launcher_icons` is configured and points at a real asset.

---

## ⚠️ Wired correctly but needs your setup/deployment to actually run

- **All Firebase Auth/Firestore/Storage flows** — need a real Firebase project (`flutterfire configure`) plus the two blockers above fixed.
- **Cloud Functions dispatch/FCM/stock-transaction** — the code is complete (see above) but must be deployed: `cd functions && npm install && cd .. && firebase deploy --only functions,firestore:rules,storage`. Until deployed, orders/rides will sit with `candidateDriverIds` never populated and drivers will never see offers.
- **Google Maps** — `GoogleMap` widgets are wired but need `GOOGLE_MAPS_API_KEY` set in `android/local.properties` (read by `android/app/build.gradle.kts`) or the map will render blank/grey.
- **PayFast payment** (`payment_service.dart`) — the signature generation, ITN validation, and hosted-checkout redirect are all correctly implemented per PayFast's docs, and `AppConfig` already reads `PAYFAST_MERCHANT_ID`/`PAYFAST_MERCHANT_KEY`/`PAYFAST_PASSPHRASE` from `.env`. **However, `PaymentService` is never called from anywhere in the app** — `cart_screen.dart` creates the order directly with no payment step at all, so checkout is effectively cash-on-delivery today regardless of the PayFast code sitting ready to use.
- **First admin bootstrap** — `functions/index.js` has a commented-out `bootstrapAdmin` HTTP function with clear instructions to uncomment, call once, then delete. Needed once, currently inert by design.

---

## ❌ Not implemented / missing

- **No payment step in checkout** — see above; `PaymentService` exists but is dead code. Checkout goes straight from cart to order creation.
- **Live GPS driver tracking on a map** — order tracking shows a text timeline, not a moving pin. `google_maps_flutter` is only used in the cab-booking area-picker, not in `order_tracking_screen.dart`.
- **Ride history is invisible to customers** — `orders_screen.dart` ("My Orders") only streams `watchCustomerOrders` (groceries/food/liquor/laundry). It never touches `customerRidesProvider`/`watchCustomerRides`, so a customer who books a cab has no way to see that ride again after the initial booking snackbar — no history, no re-opening the tracking screen.
- **Address book** — checkout and cab booking both use a single area dropdown every time; no saved multiple addresses.
- **Ratings/reviews after delivery** — no post-delivery rating screen exists anywhere in `lib/screens/`.
- **Driver earnings drill-down** — dashboard shows a weekly total stat card only; no history/detail screen behind it.
- **Multi-branch chain-store stock** — `Vendor.isChainBrand` exists in the model but is hardcoded to `false` at onboarding with no UI toggle, and there is no `branches/{branchId}` subcollection or any code that reads/writes one. This is 100% unbuilt beyond the single boolean field.
- **Barcode/SKU scanning** — `Product.sku` is a plain text field with manual entry only; no `mobile_scanner`-style camera scanning.
- **Geocoding of real addresses** — the `geocoding` package is a pubspec dependency but is never imported or used anywhere in `lib/`. Every vendor's `lat`/`lng` is silently set to the exact town-centre coordinate at onboarding (see Bugs below), and delivery fees are computed from the fixed `areaCoordinates` map, not any real address.
- **Rate limiting / abuse prevention** — no protection against spam order creation, repeated OTP requests, or fake vouching rings, exactly as the original README flagged.
- **Offline support / local caching** — Firestore's offline persistence isn't explicitly configured.
- **Localisation** — English only; no Setswana/Sesotho strings despite the app being built specifically for a Setswana/Sesotho-speaking town.
- **Accessibility pass** — no screen-reader labelling/contrast audit.
- **Meaningful widget/integration tests** — `test/widget_test.dart` only asserts `expect(KgoroApp, isNotNull)`, which is trivially true and tests nothing about actual behaviour. The comment references an `integration_test/` directory that doesn't exist in the project. Only the pure-Dart algorithm/pricing logic has real test coverage.

---

## 🐛 Bugs & doc/code mismatches found while reading the code

1. **Checkout never decrements stock client-side, contrary to `BUILD_INSTRUCTIONS.md`.** That doc claims *"orders now decrement product stock atomically inside a Firestore transaction"* in `cart_screen.dart`/`firestore_service.dart`. In the actual code, `cart_screen.dart` just calls `createOrder()` with no stock logic at all. The real atomic stock-check/decrement now lives **server-side** in the `onOrderCreated` Cloud Function — which is architecturally the *correct* place for it (never trust the client with this), but it means **stock protection only works once Cloud Functions are deployed**. If you deploy Firestore/Auth/Storage but skip deploying Functions, two customers absolutely can buy the last unit of a product simultaneously with no protection at all.
2. **All vendors get pinned to the exact same coordinates.** `vendor_onboarding_screen.dart` hardcodes `'lat': AppConstants.townCentreLat, 'lng': AppConstants.townCentreLng` regardless of what the vendor typed into the physical-address field. Since `geocoding` is never invoked (see above), every vendor in the app sits at the identical point on the map, which makes delivery-fee-by-distance and "nearest vendor" logic meaningless in practice.
3. **Admin's vendor-approval card mislabels Laundry vendors as "Unknown".** In `admin_dashboard_screen.dart`, `_VendorApplicationCard._typeName` only has cases for `groceries`/`food`/`liquor` and falls through to `'Unknown'` for anything else — but `vendor_onboarding_screen.dart` explicitly offers Laundry as a fourth service type. An admin reviewing a laundry vendor's application sees a mislabeled "Unknown" badge. (`vendor_dashboard_screen.dart`'s own header label handles this correctly, so it's just the admin card that's wrong.)
4. **`README.md` §6 is now stale in the opposite direction** — it still describes push notifications, live tracking, and server-side dispatch as unbuilt ("TODO" / "skeleton, not deployed"). In reality the Cloud Functions file (§ above) fully implements dispatch + FCM push + stock transactions. The README needs a refresh to reflect this — right now it undersells what's actually built.
5. **`test/widget_test.dart` is a placeholder, not a real test**, as noted above — worth being honest about this rather than assuming "tests exist" means "tests verify behaviour."
6. **Android `namespace` still says `com.example.kgoro`** in `android/app/build.gradle.kts`, even though `applicationId` was correctly changed to `com.thabanchu.kgoro`. Cosmetic/leftover, but worth cleaning before a Play Store submission since the Kotlin package folder (`android/app/src/main/kotlin/com/example/kgoro/MainActivity.kt`) still reflects the old name too.

---

## 🔒 Security issues found

1. **A user can self-elevate to Administrator at account *creation* time, bypassing the UI entirely.** `firestore.rules` correctly blocks changing `role` on *update* (`request.resource.data.role == resource.data.role`), but the **create** rule for `users/{uid}` is just `allow create: if isOwner(uid);` — there is no restriction on what `role` value can be set the first time the document is written. The app's own sign-up form only offers Customer/Driver/Vendor, but that's a UI-level restriction only; anyone calling the Firestore SDK/REST API directly (trivial to do — API keys are not secrets) could create their own `users/{uid}` doc with `role: 3` (admin) and the rules would allow it. **Fix:** add a create-time restriction, e.g. `request.resource.data.role in [0, 1, 2]` (customer/driver/vendor only), mirroring how `drivers/{uid}` and `vendors/{vendorId}` already force `approvalStatus == 0` on create.
2. **The in-app admin gate checks Firestore's `role` field, not the custom claim the Cloud Functions rely on.** `app.dart`'s `_RoleGate` routes to `AdminDashboardScreen` based on `appUser.role == UserRole.admin` (a plain Firestore field), while `firestore.rules`'s `isAdmin()` and the Cloud Functions check `request.auth.token.admin == true` (a custom auth claim, set only via `setAdminClaim`). These two are supposed to be kept in sync by the `setAdminClaim` function (which does update both), but if issue #1 above is exploited, a user could get `role: 3` in Firestore (enough to see the Admin UI, since screens don't check the custom claim) *without* the custom claim — meaning they'd see the admin screens render, even though the underlying writes would still be correctly blocked by rules requiring the real claim. Net effect: not a full compromise (rules still protect the data), but it's a confusing/broken UI state and a sign the two authorization mechanisms aren't fully unified.
3. **Admin screen has no dedicated route guard beyond the role switch** — this matches the original README's flagged risk. There's no `if (!isReallyAdmin) redirect` check independent of the `_RoleGate` switch statement; it relies entirely on that one switch never being reachable incorrectly. Combined with issue #1, this is worth hardening.

---

## Recommended fixes — priority order

1. **Unblock the build.** Run `flutterfire configure` to generate `lib/firebase_options.dart`, and `cp .env.template .env` (filled with real values). Nothing else can be verified until this is done.
2. **Close the role-escalation gap** in `firestore.rules`: restrict the `users/{uid}` create rule to only allow `role in [0, 1, 2]`.
3. **Deploy Cloud Functions + rules together** (`firebase deploy --only functions,firestore:rules,storage`) — don't deploy Firestore/Storage without Functions, since stock-safety and driver dispatch both depend on Functions being live.
4. **Wire `PaymentService` into `cart_screen.dart`**, or explicitly document that v1 is cash-on-delivery-only and remove/hide the unused PayFast code path to avoid confusion — right now it's a fully-built feature nobody can reach.
5. **Fix vendor geocoding**: either integrate the already-installed `geocoding` package to resolve the typed address into real `lat`/`lng` at onboarding, or clearly cap expectations that all vendors share one coordinate for now.
6. **Add ride history to `orders_screen.dart`** — merge `customerOrdersProvider` and `customerRidesProvider` into one combined "My Orders" list, or add a second tab.
7. **Fix the Laundry mislabel** in `admin_dashboard_screen.dart`'s `_typeName` getter.
8. **Refresh `README.md` §6** so it accurately reflects that Cloud Functions/FCM/dispatch are built (not "skeleton"), while keeping the genuinely-unbuilt items (maps live-tracking, ratings, address book, multi-branch stock, rate limiting) listed as such.
9. **Write real widget/integration tests** — at minimum, a test that pumps `KgoroApp` with a mocked/faked auth state and asserts the correct screen renders per role, replacing the current no-op smoke test.
10. Once the above is stable: tackle the remaining `README.md` §7 roadmap items in the order it already lists (multi-branch stock, ratings, address book, localisation, rate limiting) — that prioritisation still holds up.

---

### Quick recap by status

| Status | Count (rough) |
|---|---|
| ✅ Fully working | 15 major features/systems |
| ⚠️ Wired, needs setup/deploy/connect | 5 |
| ❌ Not implemented | 12 |
| 🐛 Bugs / doc mismatches | 6 |
| 🔒 Security gaps | 3 |
