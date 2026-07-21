# Building the APK — do this on your own machine

I implemented all the code changes directly in your project (see "What changed" below), but I
can't compile Flutter/Dart or produce an `.apk` inside this chat environment — my sandbox's network
is locked to a short allowlist (GitHub, npm, PyPI) that doesn't include `pub.dev` or
`storage.googleapis.com`, which is where the Flutter SDK and your project's packages (Firebase,
Riverpod, etc.) come from. I verified both are blocked before starting, rather than guess.

## What to run locally

You already have Flutter installed (per the original README's setup section). From the project root:

```bash
# 1. unzip the updated project (overwrite your existing kgoro/ folder, or unzip elsewhere and diff)
unzip kgoro-updated.zip

cd kgoro

# 2. fetch packages
flutter pub get

# 3. make sure lib/firebase_options.dart has your real Firebase project keys
#    (flutterfire configure — see the README's "Firebase & keys setup" section)

# 4. build a release APK
flutter build apk --release
```

The APK will land at `build/app/outputs/flutter-apk/app-release.apk` — install it on a device or
upload it wherever you distribute test builds.

If you just want to test on a connected device/emulator without a signed release build:
```bash
flutter run
```

## What changed (implemented in this project, not just planned)

- **Theme** — `lib/core/theme.dart`: light blue/white identity (Sky Blue primary, Navy headings, pale-blue surfaces), light and dark mode both updated. A few other hardcoded warm-toned hex colors were swapped to match.
- **Security fix** — sign-up no longer offers "Administrator" as a self-service role (`lib/screens/auth/login_screen.dart`); admin accounts must be created out-of-band.
- **Data models** — `lib/models/models.dart`: `Vendor` gained `ownerId`, `address`, `contactPhone`, `openingHours`, `isChainBrand`; `Product` moved from a boolean `inStock` to a real `quantity`, plus `sku` and `lowStockThreshold` (backward-compatible with old docs).
- **Vendor onboarding** — `lib/screens/vendor/vendor_onboarding_screen.dart`: new screen, collects store details and creates the vendor doc tied to the signed-in user.
- **Vendor dashboard** — `lib/screens/vendor/vendor_dashboard_screen.dart`: Orders tab (live queue, one-tap status advance), Menu tab (add/edit/delete products, stock levels, low-stock badges, CSV bulk import for bigger stores), Settings tab (open/closed, hours, contact).
- **Product editor** — `lib/screens/vendor/product_edit_screen.dart`: add/edit a single product including photo, price, quantity, SKU, low-stock threshold.
- **Routing** — `lib/app.dart`: vendor role now flows onboarding → pending-approval → dashboard (mirrors the driver approval pattern) instead of a "Coming Soon" placeholder.
- **Admin dashboard** — `lib/screens/admin/admin_dashboard_screen.dart`: now has two tabs, Drivers and Vendors, so store applications can actually be approved.
- **Stock-safe checkout** — `lib/services/firestore_service.dart` + `lib/screens/checkout/cart_screen.dart`: orders now decrement product stock atomically inside a Firestore transaction, so two customers can't both "win" the last unit.
- **Liquor age verification** — `cart_screen.dart`: an 18+ confirmation checkbox is required before checkout completes for liquor orders.
- **Mock-data cleanup** — removed the stale "mock auth" comment and the outdated "hardcoded demo catalogue" claims in the README (the screens were already Firestore-backed; only the comments/docs were stale).
- **README** — updated to reflect 4 services (was missing Liquor), the real vendor dashboard, and a refreshed priority list.
- **Placeholder assets** — `assets/images/banner_*.png` and `assets/images/logo.png` (already registered in `pubspec.yaml`) so the app doesn't reference missing images while you swap in real photography.

## What's intentionally not built yet

- Multi-branch chain stock (one brand, many physical branches with separate stock) — the `Vendor.isChainBrand` flag is in the data model, but per-branch stock documents aren't built. Flagged in the README as the next step once a real chain-scale store is ready to onboard.
- Barcode scanning for stock intake — the `sku` field is there to support it later; no scanner package was added since it'd need `flutter pub get` to verify, which I couldn't run here.
- Server-enforced admin/vendor permissions (Firestore custom claims) — the UI now gates correctly, but the write-side security rules should be hardened before a public launch, as already flagged in the README.

## If `flutter pub get` or the build fails

Nothing in this change touched `pubspec.yaml` dependencies — I deliberately avoided adding new
packages (e.g. for CSV import I used plain string parsing instead of the `csv` package) so there's
no new dependency-resolution risk. If you still hit errors, they're most likely pre-existing from
the original project (e.g. Firebase config), not from these changes — happy to help you debug the
exact error message if you paste it back here.
