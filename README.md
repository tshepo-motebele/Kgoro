# Kgoro — Ke ya hao, ke ya rona (Yours, ours)

A groceries + food + cab super-app built exclusively for **Thaba Nchu**, Free State — combining an Uber/SweepSouth-style multi-service model with a residency-gated marketplace and a fairness-first driver matching system designed to create real income opportunities for local, including unskilled, residents.

Thaba Nchu is a historic Barolong Boo-Seleka town roughly 60–70km east of Bloemfontein, with high unemployment and limited formal-economy access — which is the direct reason this app is scoped to one town instead of trying to be a generic national platform.

---

## 1. The Name & Identity (Theme)

**Kgoro** (Setswana/Sesotho) means *gateway* — the entrance to a homestead or a community gathering place. It reads as "the way in" to everything Thaba Nchu has to offer. 

### Visual Identity & Theme
The application's theme (`lib/core/theme.dart`) uses a modern, clean, and accessible design system optimized for both light and dark modes:

- **Typography:** The app exclusively uses **Plus Jakarta Sans** — a warm, modern, and highly legible font at all sizes.
- **Primary Brand Colors:**
  - **Sky Blue** (`#1E6FDB`): Used for primary actions, buttons, and active states.
  - **Navy** (`#0D2C54`): Used for headings, high-emphasis text, and primary text (ink).
  - **Light Blue** (`#569CF0`): Used for secondary accents and chips.
- **Highlight Color:**
  - **Warm Gold** (`#E0A72F`, alias `naledi`): Used for ratings, earnings, and positive highlights (named after the well-known Naledi Sun hotel).
- **Semantic Colors:**
  - **Success (Green)** (`#10B981`, alias `veld`): Represents the surrounding farmland.
  - **Warning (Amber)** (`#xFFFF991F`, alias `clay`).
  - **Error (Red)** (`#DE350B`).
- **Dark Mode (Deep Navy Aesthetic):** The dark theme uses a deep navy background (`#0A192F`) with slightly lighter surface colors (`#112240`) to maintain a premium feel without harsh pure blacks, while ensuring all text remains highly readable.

---

## 2. Project Structure & Available Files

The project is structured into clear feature domains. Here is a comprehensive list of all the available pages/screens in the app (`lib/screens/`):

### Core App & Navigation
- `splash_screen.dart` - Initial loading screen
- `onboarding_screen.dart` - Welcome guide for new users
- `home_shell.dart` - The main bottom navigation wrapper

### Authentication (`auth/`)
- `login_screen.dart` - Handles email/password sign-in and phone number OTP verification via `_OtpScreen`.
- `complete_profile_screen.dart` - Follow-up screen for capturing missing profile details.

### Home & Core Services
- `home/home_dashboard_screen.dart` - Main dashboard showing categories, active orders, and top local vendors.
- `groceries/groceries_screen.dart` - Grocery store listings.
- `groceries/vendor_detail_screen.dart` - Individual store view with product catalogue and reactive cart.
- `food/food_screen.dart` - Restaurant and fast-food listings.
- `cab/cab_booking_screen.dart` - Local area-to-area ride booking form.
- `laundry/laundry_screen.dart` - Laundry services (Placeholder).
- `liquor/liquor_screen.dart` - Liquor delivery (Placeholder).

### Checkout & Orders (`checkout/` & `orders/`)
- `checkout/cart_screen.dart` - Cart review, quantity adjustments, and delivery details.
- `checkout/order_confirmation_screen.dart` - Success screen after placing an order.
- `orders/orders_screen.dart` - History of past and active orders.
- `orders/order_tracking_screen.dart` - Real-time step-by-step timeline of an active delivery.
- `orders/ride_tracking_screen.dart` - Active cab ride status.

### Profiles & Dashboards
- `profile/profile_screen.dart` - User settings, role switching, and sign-out.
- `profile/edit_profile_screen.dart` - Update personal details.
- `driver/driver_dashboard_screen.dart` - Active driver view (online toggle, earnings).
- `driver/driver_jobs_screen.dart` - Incoming job offers and active assignments.
- `driver/become_driver_intro_screen.dart` - Application flow for new drivers.
- `vendor/vendor_dashboard_screen.dart` - Store management, incoming orders, and menu editing.
- `vendor/vendor_onboarding_screen.dart` - Application flow for new vendors.
- `admin/admin_dashboard_screen.dart` - Town admin panel for reviewing applications and monitoring the platform.

### Other Key Directories
- `lib/core/` - Theme, constants, validators, and geocoding utilities.
- `lib/models/` - Data models (`AppUser`, `KgoroOrder`, `Vendor`, etc.).
- `lib/services/` - Core logic (`AuthService`, `FirestoreService`, `MatchingAlgorithm`, `ResidencyVerificationService`).
- `lib/providers/` - Riverpod state management (auth state, active cart, offline connectivity).
- `lib/widgets/` - Reusable UI components (buttons, offline banners, empty states).

---

## 3. The Core Idea: Three Services, One App

| Service | Status | Notes |
|---|---|---|
| **Groceries** | UI & Logic Complete | Vendor list from Firestore; reactive cart and quantity controls. Out-of-stock items are visually disabled. |
| **Food** | UI & Logic Complete | Same pattern as groceries, filtered by `ServiceType.food`. |
| **Cab** | UI Complete | Area-to-area dropdown booking. Navigates seamlessly to `RideTrackingScreen`. |

---

## 4. What makes this *Thaba Nchu's* app, not a generic clone

### Residency Gating (`lib/services/residency_service.dart`)
South African ID numbers don't encode a hometown, and there's no public API to confirm "this person lives in Thaba Nchu." So the app layers several checkable signals:
1. **GPS bounding box** at signup — device must be physically near town.
2. **Fixed local-area dropdown** instead of free-text address (faster on low-end phones, harder to fake).
3. **Uploaded proof of address** — reviewed by an admin.
4. **SA ID document upload + validation**.
5. **Community vouching** — two existing verified users vouch for a new driver applicant.

### Fairness-capped Surge Pricing (`lib/services/pricing_service.dart`)
Surge is capped at **1.3×** (vs the 2–5× common on Uber-style platforms) because this app exists to serve one town's residents, not to extract maximum revenue during a taxi strike or bad-weather spike.

### The Fair-Match Algorithm (`lib/services/matching_algorithm.dart`)
A naive "closest driver wins" matcher consistently starves everyone except the top 10–15% of drivers. In a town where the explicit goal is creating opportunity for **unskilled, currently unemployed** residents, every open job scores each *online, approved* driver on four weighted factors:

`score = 0.40 × proximity + 0.25 × fairness + 0.25 × reliability + 0.10 × vehicleFit`

- **Fairness** — drivers who haven't worked recently get a boost, so jobs spread across the *whole* active pool.
- **Dispatch pattern:** The top 3 ranked candidates are offered the job simultaneously; first to accept wins.

---

## 5. Fully Working Features (Recent Updates)

- **100% Clean Codebase:** Passes `flutter analyze` with 0 issues.
- **Robust Authentication:** 
  - Working Email/Password flows.
  - Working Phone Number OTP verification flow (`_OtpScreen`) natively integrated with Firebase.
- **UI/UX Polish:**
  - **Offline Awareness:** A persistent `KgoroOfflineBanner` appears instantly across the app if the user loses internet connection.
  - **Active Order Tracking:** The Home Dashboard displays an `ActiveOrderCard` whenever an order is in progress.
  - **Foreground Notifications:** In-app snackbars appear for notifications received while actively using the app, rather than forcefully navigating the user.
  - **Cart Enhancements:** Users can add/remove item quantities directly from the Cart screen. The FAB cart total updates reactively across screens.
  - **Store UX:** Closed vendors are faded and sorted to the bottom. Out-of-stock products are greyed out.
  - **Order Timelines:** Accurate order tracking timeline that correctly handles cancellations without showing false progress.
- **Dark Mode Support:** All components dynamically adapt perfectly to the deep navy dark theme.
- **App Configuration:** Uses `.env` for secrets (like Cloud Functions URLs and PayFast notify URLs).

---

## 6. Firebase & Keys Setup (Deployment)

To run the app against a real backend, you must configure your own Firebase project:

1. **Create a Firebase project** at console.firebase.google.com
2. Enable **Authentication → Phone** sign-in method & **Email/Password**.
3. Enable **Firestore Database** (deploy `firestore.rules` from this repo).
4. Enable **Storage** (deploy `storage.rules` from this repo).
5. Install the FlutterFire CLI and run it from the project root:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   *This overwrites the placeholder `lib/firebase_options.dart` with real values.*
6. For Android phone-auth silent verification, add your debug **and** release **SHA-1/SHA-256** fingerprints in Firebase Project Settings.
7. Create a `.env` file in the root directory (copy `.env.example` if available) and add your environment variables (like `CLOUD_FUNCTIONS_BASE_URL`).
8. **Set the first admin** manually via the Firebase Admin SDK (cannot be done from the client):
   ```js
   admin.auth().setCustomUserClaims(uid, { admin: true });
   ```

---

## 7. Running the app

```bash
flutter pub get
flutter test              # run the algorithm/pricing unit tests
flutter run               # after Firebase is configured
```

*Note: Without Firebase configured, the app will build and the UI/navigation will work, but sign-in and data screens will fail to connect. This is expected until you run `flutterfire configure`.*
