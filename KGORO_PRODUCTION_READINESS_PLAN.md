# Kgoro — Production-Readiness Plan (Routing, Vendor Services, Full Rollout)

This builds on `KGORO_FEATURE_AUDIT.md` and goes deep on three things you flagged: **(1)** correct dashboard routing right after sign-up and right after admin approval, **(2)** making sure Laundry and every other vendor type actually functions correctly, and **(3)** a phased path to 100% production-ready. Every fix below includes the exact code to change — nothing has been applied to your files; copy what you need into your own project.

---

## Part A — Dashboard routing: sign-up → approval → correct screen

### How routing works today (this part is already correct)

`lib/app.dart`'s `_RoleGate` watches a **live Firestore stream** of your user doc (`currentAppUserProvider`, a `StreamProvider`) and switches on `appUser.role`:

```dart
switch (appUser.role) {
  case UserRole.admin:   return const AdminDashboardScreen();
  case UserRole.driver:  return const DriverDashboardScreen();
  case UserRole.vendor:  return _VendorGate(ownerUid: appUser.id);
  case UserRole.customer: return const HomeShell();
}
```

Because this is a **stream**, not a one-time fetch, re-routing after an admin approves someone happens automatically and correctly:

- **Vendors**: `_VendorGate` streams `watchVendorByOwner(uid)`. The moment admin flips `approvalStatus` to `approved`, the stream re-fires and the UI swaps from the pending screen straight to `VendorDashboardScreen` — no restart, no manual refresh needed.
- **Drivers**: `DriverDashboardScreen` streams `currentDriverProfileProvider`. Same mechanism — admin approval instantly swaps `_PendingApprovalView` for the real dashboard.

**So: post-approval routing was already correct.** The bug was somewhere else — in what happens **right after sign-up, before** an application even exists.

### The actual bug: driver sign-up leads to a dead end

Your sign-up form (`login_screen.dart`) lets someone pick **"Driver Partner"** or **"Vendor / Store Owner"** as their account type immediately at registration — before they've filled in any ID documents, proof of address, or store details. That write happens instantly:

```dart
final newUser = AppUser(..., role: _selectedRole, ...);
await ref.read(firestoreServiceProvider).upsertUser(newUser);
```

The moment that Firestore doc exists with `role: driver`, `_RoleGate` sends them **straight into `DriverDashboardScreen`** — permanently, every time they open the app, with no bottom navigation and no way back to `HomeShell`. Since they haven't filled out `DriverApplicationScreen` yet, `DriverDashboardScreen` finds no `drivers/{uid}` doc and — in the current code — shows this:

```dart
if (profile == null) {
  return const Scaffold(
    body: EmptyState(
      icon: Icons.badge_outlined,
      title: 'No application found',
      subtitle: 'Apply to become a Kgoro driver from your profile page.',
    ),
  );
}
```

**That's a dead end.** There's no AppBar, no button, no bottom nav — the text tells the user to go to "your profile page," but there is no way to reach it from this screen. The same gap exists in several other places: none of `VendorOnboardingScreen`, the vendor `_PendingApprovalScreen`/`_RejectedScreen`, `AdminDashboardScreen`, the approved `VendorDashboardScreen`, or the approved `DriverDashboardScreen` have a sign-out option anywhere — because sign-out currently only lives inside `ProfileScreen`, which is only reachable through `HomeShell`, which only `role == customer` accounts ever see. **Any driver or vendor account is permanently cut off from `ProfileScreen`, `EditProfileScreen`, Help & Support, and Sign Out**, for the lifetime of the account.

### The fix

**1. Add one reusable sign-out action.** Drop this into `lib/widgets/common_widgets.dart` (needs `import 'package:flutter_riverpod/flutter_riverpod.dart';` and `import '../providers/providers.dart';` added to that file's imports):

```dart
class SignOutIconButton extends ConsumerWidget {
  const SignOutIconButton({super.key});

  Future<void> _signOut(WidgetRef ref) async {
    await ref.read(authServiceProvider).signOutAndCleanup();
    ref.invalidate(currentAppUserProvider);
    ref.invalidate(currentDriverProfileProvider);
    ref.invalidate(cartProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.logout_rounded),
      tooltip: 'Sign out',
      onPressed: () => _signOut(ref),
    );
  }
}
```

**2. Fix the actual dead end** — `DriverDashboardScreen`'s "no application" branch. Give it an AppBar and a direct button into the application form (add `import 'driver_application_screen.dart';` at the top of the file):

```dart
if (profile == null) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Driver dashboard'),
      actions: const [SignOutIconButton()],
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.badge_outlined, size: 56, color: AppColors.mountain),
            const SizedBox(height: 16),
            const Text('No application found',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Complete your driver application — ID, proof of address, and vehicle type — to start receiving job offers.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DriverApplicationScreen()),
              ),
              child: const Text('Apply now'),
            ),
          ],
        ),
      ),
    ),
  );
}
```

**3. Add `actions: const [SignOutIconButton()],` to every AppBar that currently lacks one**, so no account type is ever trapped:

| File | Where |
|---|---|
| `driver_dashboard_screen.dart` | the `_PendingApprovalView` AppBar, and the approved 2-tab dashboard's AppBar |
| `vendor/vendor_onboarding_screen.dart` | this screen has **no AppBar at all** — add `appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, actions: const [SignOutIconButton()])` |
| `app.dart` → `_PendingApprovalScreen` and `_RejectedScreen` | same — no AppBar today, add one the same way |
| `admin/admin_dashboard_screen.dart` | its existing AppBar (`title: const Text('Admin — Pending Applications')`) |
| `vendor/vendor_dashboard_screen.dart` | its existing AppBar (the one with the store name + tabs) |

Each of these files already imports `../../widgets/common_widgets.dart`, so `SignOutIconButton` will resolve without adding new imports (except in `vendor_onboarding_screen.dart`, which currently doesn't import it — add `import '../../widgets/common_widgets.dart';`).

### Worth deciding, not fixing blindly

Right now, choosing "Driver Partner" or "Vendor / Store Owner" at sign-up **permanently** routes that account away from the customer marketplace — they can never browse Groceries/Food/Liquor/Cab/Laundry as themselves, because `_RoleGate` only shows `HomeShell` to `role == customer`. Compare that to the *other* path already built into the app: sign up as a normal Customer, then later tap **Profile → "Become a driver"**, which does the application without ever changing `role` — so that person keeps full customer access *and* gets a driver dashboard tile in their profile. That second path is clearly the one the rest of the UI (the "Earn with Kgoro" card, the Profile tile) was designed around.

You have two reasonable options, and it's a product decision rather than a bug:
- **Option A (minimal):** keep the sign-up dropdown, ship the sign-out fixes above so nobody gets stuck. Simple, but you'll have two account types that can never see the marketplace.
- **Option B (cleaner):** remove "Driver Partner" / "Vendor / Store Owner" from the sign-up dropdown entirely — every account starts as `role: customer`, and people opt into driving/vending from Profile, same as the rest of the app already assumes. Less code to maintain, and no dead-end risk by construction.

---

## Part B — Making sure Laundry (and every vendor type) actually works

### The good news: Laundry was never actually broken at the customer-facing level

I checked every layer a Laundry order passes through, end to end:

- **Enum**: `enum ServiceType { groceries, food, cab, liquor, laundry }` — `laundry` is a first-class value, not bolted on.
- **Customer tile**: `home_dashboard_screen.dart`'s service grid has a full `Laundry` tile (icon, color, route to `LaundryScreen`) exactly like the other three.
- **`LaundryScreen`**: streams `watchVendorsByType(ServiceType.laundry)` — same pattern, same code shape, as `GroceriesScreen`/`FoodScreen`/`LiquorScreen`. No shortcuts, no missing states.
- **Vendor detail / product list / cart / checkout**: `VendorDetailScreen` and `CartScreen` are **completely service-agnostic** — they just take a `Vendor` and stream its `products` subcollection. There is no `if (type == groceries)` branching anywhere in that path that could silently exclude Laundry.
- **Vendor onboarding**: `VendorOnboardingScreen`'s type selector includes Laundry as one of four equal options, and it's stored the same way as the others.
- **Vendor dashboard header label**: correctly shows "Laundry" for laundry vendors.

**So a Laundry vendor signing up, getting approved, adding products, and a customer finding/ordering from them — that whole path already works exactly like Groceries/Food/Liquor.** There was one real, narrow bug, not a systemic one:

### The one real Laundry bug: admin approval screen mislabels it

`admin_dashboard_screen.dart`'s vendor-application card has a `_typeName` getter that's missing a case:

```dart
// BEFORE — falls through to 'Unknown' for laundry
String get _typeName {
  switch (vendor.type) {
    case ServiceType.groceries: return 'Groceries';
    case ServiceType.food: return 'Fast Food';
    case ServiceType.liquor: return 'Liquor';
    default: return 'Unknown';
  }
}
```

```dart
// AFTER
String get _typeName {
  switch (vendor.type) {
    case ServiceType.groceries: return 'Groceries';
    case ServiceType.food: return 'Fast Food';
    case ServiceType.liquor: return 'Liquor';
    case ServiceType.laundry: return 'Laundry';
    default: return 'Unknown';
  }
}
```

Cosmetic, but worth fixing before an admin reviewing a real laundry store's application sees a confusing "Unknown" badge and second-guesses whether to approve it.

### A related bug that affects Laundry the same as every other vendor type

`VendorOnboardingScreen` currently pins **every** vendor — regardless of type — to the exact same coordinate:

```dart
'lat': AppConstants.townCentreLat,
'lng': AppConstants.townCentreLng,
```

...no matter what the vendor typed into the address field. This means delivery-fee-by-distance and "nearest vendor" logic can't actually distinguish a laundromat on one side of Thaba Nchu from a grocery store on the other — they'd all show the same distance. Since `geocoding: ^3.0.0` is already a pubspec dependency but never used, wire it in:

```dart
double lat = AppConstants.townCentreLat;
double lng = AppConstants.townCentreLng;
final address = _addressController.text.trim();
if (address.isNotEmpty) {
  try {
    final results = await locationFromAddress(
      '$address, $_localArea, Thaba Nchu, Free State, South Africa',
    );
    if (results.isNotEmpty) {
      lat = results.first.latitude;
      lng = results.first.longitude;
    }
  } catch (_) {
    // No network, address not found, or geocoder unavailable — fall back
    // to the town-centre pin rather than blocking submission.
  }
}
// then use `lat`/`lng` instead of the hardcoded constants when building `data`
```

(Add `import 'package:geocoding/geocoding.dart';` at the top of `vendor_onboarding_screen.dart`.)

### One more gap that affects the "Cab" service specifically

`orders_screen.dart` ("My Orders") only streams `KgoroOrder`s (groceries/food/liquor/laundry). It never touches `customerRidesProvider`, so **a customer who books a cab has no way to see that ride again** after the initial booking — no history entry, no way to reopen tracking. Since `RideRequest.status` already reuses the same `OrderStatus` enum as orders, the fix is to merge both streams in `orders_screen.dart` and give rides their own lightweight tracking view (since `OrderTrackingScreen` expects `order.items`/`order.total`, which rides don't have — a `RideRequest` has `pickupArea`/`dropoffArea`/`estimatedFare` instead). Sketch:

```dart
// orders_screen.dart — merge both streams instead of only watching orders
final ordersAsync = ref.watch(customerOrdersProvider);
final ridesAsync  = ref.watch(customerRidesProvider);
// combine ordersAsync.value ?? [] and ridesAsync.value ?? [] into one list,
// sort by createdAt descending, and render each item with the right icon/tap
// target: KgoroOrder → OrderTrackingScreen(orderId: …), RideRequest → a new
// lightweight ride-detail view built the same way but reading
// firestoreServiceProvider.watchRide(rideId) and showing pickupArea /
// dropoffArea / estimatedFare / driverId instead of items / total.
```

This is a moderate change (new UI branch per item type), so it's called out as its own phase item below rather than a one-line patch.

---

## Part C — Phased plan to 100% production-ready

### Phase 0 — Unblock the build (do this first; nothing else can be tested until it's done)

- [ ] `lib/firebase_options.dart` **does not exist in your zip at all** (not a placeholder — genuinely missing), and `main.dart` imports it. Run:
  ```
  dart pub global activate flutterfire_cli
  flutterfire configure
  ```
  against your real Firebase project. Until this file exists with real values, the project won't compile.
- [ ] `.env` **does not exist** — only `.env.template` does — but `pubspec.yaml` lists `.env` as a required asset and `main.dart` calls `dotenv.load(fileName: '.env')` before anything else runs. Run `cp .env.template .env` and fill in real values.
- [ ] While you're in `.env.template`: it's currently stale — it lists `WEB_API_KEY`, `ANDROID_API_KEY`, `PROJECT_ID`, etc. (leftover from an older architecture), but the app actually reads `GOOGLE_MAPS_API_KEY`, `PAYFAST_MERCHANT_ID`, `PAYFAST_MERCHANT_KEY`, `PAYFAST_PASSPHRASE`, `PAYFAST_SANDBOX`, `SUPPORT_WHATSAPP_NUMBER`, `SUPPORT_EMAIL` (see `lib/core/app_config.dart`). Update the template so the next person who clones the repo isn't misled.
- [ ] Confirm `android/local.properties` has `GOOGLE_MAPS_API_KEY=...` set too — the Android manifest reads it from there separately (see `android/app/build.gradle.kts`), independent of the Dart-side `.env` value.

### Phase 1 — Routing & navigation correctness (Part A above)

- [ ] Add `SignOutIconButton` to `common_widgets.dart`.
- [ ] Fix the `DriverDashboardScreen` "no application" dead end with a real AppBar + "Apply now" button.
- [ ] Add the sign-out action to every AppBar-less or sign-out-less screen listed in the table above.
- [ ] Decide and implement Option A or B for the sign-up role dropdown (see "Worth deciding, not fixing blindly").
- [ ] Manually test all four "cold start after sign-up" paths on a real device/emulator: sign up as Customer, Driver, Vendor, and (via Firebase console) Admin — confirm each lands somewhere navigable, not a dead end.
- [ ] Manually test the "admin approves while app is open" path for both a pending driver and a pending vendor — confirm the screen swaps automatically without a restart.

### Phase 2 — Vendor/service correctness (Part B above)

- [ ] Fix the `_typeName` Laundry mislabel in `admin_dashboard_screen.dart`.
- [ ] Wire up `geocoding` in `VendorOnboardingScreen` so vendor pins reflect real addresses.
- [ ] Build the ride-history merge in `orders_screen.dart` + a lightweight ride-tracking view, per the sketch above.
- [ ] Seed at least one real (or realistic test) vendor of **each** of the four types — Groceries, Food, Liquor, Laundry — with several products each, and manually walk through: browse → vendor detail → add to cart → checkout → vendor dashboard sees the order → mark through each status → customer sees status update live. Do this once per service type; don't assume Laundry parity from code review alone once you have live Firestore data flowing.

### Phase 3 — Security hardening

- [ ] Close the role-escalation gap in `firestore.rules`. Today, `users/{uid}` create is `allow create: if isOwner(uid);` with no restriction on the `role` value — someone bypassing your app UI and writing to Firestore directly could hand themselves `role: admin` (3) on first write, since the existing protection only blocks *changing* role on *update*. Fix:
  ```
  allow create: if isOwner(uid) && request.resource.data.role in [0, 1, 2];
  ```
- [ ] Deploy the updated rules: `firebase deploy --only firestore:rules`.
- [ ] Confirm the in-app admin gate (`appUser.role == UserRole.admin`, a Firestore field) and the Cloud-Functions/rules admin check (`request.auth.token.admin == true`, a custom claim) stay in sync — both are set together by the `setAdminClaim` Cloud Function today; make sure that's the *only* path that ever sets `role: admin` once Phase 3's rule fix is deployed.

### Phase 4 — Payments end-to-end

- [ ] `PaymentService` (PayFast signature generation, ITN validation, hosted checkout) is fully coded but **never called** — `cart_screen.dart` creates the order directly with no payment step, so checkout is effectively cash-on-delivery today. Either wire `PaymentService` into `cart_screen.dart`'s submit flow, or explicitly decide v1 ships COD-only and remove the dead PayFast call sites to avoid confusion for the next developer.
- [ ] If wiring PayFast: test against PayFast's **sandbox** environment first (`PAYFAST_SANDBOX=true`), confirm the ITN webhook round-trip actually reaches your Cloud Function before flipping to production credentials.
- [ ] Re-confirm stock-safety: the atomic stock-decrement transaction lives in the `onOrderCreated` Cloud Function, **not** in the client. If you ever deploy Firestore/Storage rules without also deploying Functions, two customers can buy the last unit of a product with zero protection. Always deploy together: `firebase deploy --only functions,firestore:rules,storage`.

### Phase 5 — Remaining feature gaps

- [ ] Post-delivery ratings/reviews screen (currently doesn't exist).
- [ ] Customer address book (currently a single area dropdown every checkout).
- [ ] Driver earnings drill-down (currently a single weekly total, no history).
- [ ] Multi-branch chain-store support — `Vendor.isChainBrand` is a hardcoded `false` with no UI or subcollection behind it; either build it or remove the field until it's real.
- [ ] Live GPS pin on the order-tracking map (today it's a status timeline, not a moving pin — only the cab-booking screen has an actual `GoogleMap`).
- [ ] Rate limiting / abuse prevention on order creation, OTP requests, and vouching.
- [ ] Setswana/Sesotho localisation, given the target community.

### Phase 6 — Testing & QA

- [ ] `test/widget_test.dart` currently only asserts `expect(KgoroApp, isNotNull)` — replace it with a real test that pumps `KgoroApp` under a faked/mocked auth+Firestore state and asserts the correct screen renders per role (this is exactly what would have caught the Phase 1 dead ends before a real user hit them).
- [ ] The pure-logic test suite (`matching_and_pricing_test.dart`) is solid — extend that same pattern to cover the geocoding fallback and the ride/order merge logic once built.
- [ ] Do a full manual pass on a real Android device (not just an emulator) for: camera-based document upload (driver application), GPS permission prompts (driver online toggle, cab booking), and push notifications (order/ride matched) — these are the areas most likely to behave differently on-device vs. emulator.

### Phase 7 — Store submission checklist

- [ ] `android/app/build.gradle.kts` has `applicationId = "com.thabanchu.kgoro"` (correct) but `namespace = "com.example.kgoro"` and the Kotlin source still sits under `android/app/src/main/kotlin/com/example/kgoro/MainActivity.kt` — clean up the leftover `com.example` package name before submitting.
- [ ] Privacy policy + terms of service URLs (referenced implicitly by "By signing up, you agree to our Terms of Service" on the sign-up form — that text isn't currently a link to anything).
- [ ] App icon / splash / store listing screenshots.
- [ ] Confirm production Firebase project (not a dev/test project) is what `firebase_options.dart` points to before building the release APK/AAB.
- [ ] Confirm `PAYFAST_SANDBOX=false` and real PayFast production credentials are only ever set in your CI/CD secrets, never committed.

---

## Quick-reference: files touched by this plan

| File | What changes |
|---|---|
| `lib/widgets/common_widgets.dart` | + `SignOutIconButton` |
| `lib/screens/driver/driver_dashboard_screen.dart` | fix dead end, add sign-out to all 3 AppBar states |
| `lib/screens/vendor/vendor_onboarding_screen.dart` | add AppBar + sign-out, wire `geocoding` |
| `lib/app.dart` | add AppBar + sign-out to `_PendingApprovalScreen`/`_RejectedScreen` |
| `lib/screens/admin/admin_dashboard_screen.dart` | add sign-out, fix `_typeName` Laundry case |
| `lib/screens/vendor/vendor_dashboard_screen.dart` | add sign-out |
| `lib/screens/orders/orders_screen.dart` | merge order + ride streams |
| *(new)* ride tracking view | render `RideRequest` status/pickup/dropoff/fare |
| `firestore.rules` | restrict `role` on `users/{uid}` create to `[0, 1, 2]` |
| `.env.template`, `.env` | correct variable names, create real `.env` |
| `lib/firebase_options.dart` | generate via `flutterfire configure` |
