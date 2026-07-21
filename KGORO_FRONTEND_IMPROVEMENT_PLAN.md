# Kgoro — Frontend & Product Improvement Plan

**Scope:** Registration → role-based dashboards, full page inventory, light blue/white theme, mock-data removal, vendor menu/order management, and chain-store (Shoprite/Jwayelane-scale) stock handling for all 4 services: **Groceries, Fast Food, Liquor, Cab**.

This document is a build spec — hand it to yourself, a teammate, or Claude Code to implement section by section.

---

## 1. Current state (what I found in `mn-main.zip`)

| Area | Status |
|---|---|
| Auth (email/password sign up + login) | ✅ Real Firebase Auth, working |
| Role selection at signup | ⚠️ Works, but **any user can pick "Administrator" at signup** — security hole |
| Groceries / Food / Liquor / Cab customer screens | ✅ Already reading live Firestore streams, not hardcoded |
| Customer role dashboard | ✅ `HomeShell` |
| Driver role dashboard | ✅ `DriverDashboardScreen` |
| Admin role dashboard | ⚠️ Exists, but only handles driver approvals — no route protection |
| **Vendor role dashboard** | ❌ **Literally a placeholder**: `Text('Vendor Dashboard Coming Soon!')` in `app.dart` |
| Vendor registration/onboarding flow | ❌ Doesn't exist — a user can select "Vendor" at signup but there's no screen to create a store, add products, or link themselves as the owner |
| Product/stock model | ⚠️ `Product` has only `inStock: bool` — no quantity, no branch/multi-location support |
| Theme | ⚠️ Terracotta/maroon + gold + dark green — needs to become light blue/white per your request |
| Mock data | ✅ Mostly already removed from screens; remaining traces are **stale comments**, not actual fake data (see §5) |

**Bottom line:** the single biggest functional gap is that **vendors have no dashboard at all**. That's priority #1 below.

---

## 2. New visual identity: Light Blue & White

Replace `lib/core/theme.dart`'s palette with:

```dart
class AppColors {
  static const Color primary   = Color(0xFF1E6FDB); // Sky Blue — primary actions, buttons, active states
  static const Color primaryDark = Color(0xFF0D2C54); // Navy — headings, high-emphasis text
  static const Color primaryLight = Color(0xFF569CF0); // Light Blue — secondary accents, chips
  static const Color background = Color(0xFFFFFFFF); // Pure white — base background
  static const Color surfaceTint = Color(0xFFEBF3FF); // Very light blue — card/section tint
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFFF991F);
  static const Color error   = Color(0xFFDE350B);
  static const Color textMuted = Color(0xFF64748B);
}
```

- Buttons, active tabs, FABs, links → `primary`.
- Headings/titles → `primaryDark`.
- Card backgrounds stay white; use `surfaceTint` only for selected/active states and empty-state illustrations backgrounds — keeps the "light, airy" feel instead of looking heavy.
- Dark mode: invert to navy background (`primaryDark`) with `primary`/`primaryLight` as accents — don't reuse the old maroon/gold dark theme.
- Attached: `kgoro_logo_blue.png` — a redrawn placeholder logo (gateway/arch motif, matching "Kgoro" = gateway) and 4 service banners (`banner_groceries.png`, `banner_food.png`, `banner_liquor.png`, `banner_cab.png`) you can drop into `assets/images/` today and swap for professional artwork later.

---

## 3. Full page inventory (build/keep list, by role)

### 3.1 Public / pre-auth
- [x] Splash
- [x] Onboarding
- [x] Login
- [x] Sign Up (needs fixes — see §4)
- [ ] **Forgot password screen** (button exists, does nothing — wire to `FirebaseAuth.sendPasswordResetEmail`)

### 3.2 Customer role
- [x] Home dashboard (service switcher: Groceries / Food / Liquor / Cab)
- [x] Groceries list + vendor detail + cart + checkout
- [x] Food list (same pattern — confirm parity with groceries)
- [x] Liquor list (confirm parity — **must add age-confirmation step**, see §7.4)
- [x] Cab booking
- [x] Orders (history/tracking)
- [x] Profile
- [ ] **Order tracking detail screen** (single order live status — currently only a list + confirmation exist)
- [ ] **Address book** (save multiple drop-off points instead of one dropdown area each time)
- [ ] **Ratings/review screen** after order delivered

### 3.3 Driver role
- [x] Become-driver intro
- [x] Driver application form
- [x] Driver dashboard (online toggle, job feed)
- [ ] **Earnings/history detail screen** (weekly earnings shown on dashboard, but no drill-down)

### 3.4 Vendor role — ⚠️ build from scratch
This is the core deliverable you asked for ("handle orders, update their menus"):

- [ ] **Vendor onboarding screen** — collects store name, service type (Groceries/Food/Liquor), local area, physical address, store photo, opening hours, and creates the `vendors/{id}` doc with `ownerId = uid`. Store goes in as `approvalStatus: pendingReview` until admin approves (reuses the existing approval pattern from drivers).
- [ ] **Vendor dashboard (home)** — tab bar with 3 tabs:
  - **Orders** — live stream of incoming orders for this vendor, grouped by status (New → Preparing/Packing → Ready → Out for delivery → Completed), with one-tap status update buttons.
  - **Menu / Products** — list of the vendor's own products with add/edit/delete, price, photo, category, and **stock quantity** (not just in/out boolean — see §6).
  - **Store settings** — open/closed toggle, opening hours, banner photo, branch management (for chain stores, see §6).
- [ ] **Add/Edit product screen** — form: name, category, price, stock quantity, photo upload (`image_picker` is already a dependency), inStock auto-derives from `quantity > 0`.
- [ ] **Vendor order detail screen** — items, customer drop-off area, total, and the status-update action.
- [ ] **Basic sales insights** (optional, `fl_chart` is already a dependency) — orders today, revenue today/week.

### 3.5 Admin role
- [x] Driver approval queue
- [ ] **Vendor approval queue** (mirror of driver approval, since vendors now self-register — see §4)
- [ ] **Route protection** — Admin screen must never be reachable except for users with a verified admin role (see §4)
- [ ] Optional: a lightweight order/dispute overview across all services

---

## 4. Registration → correct dashboard (end-to-end fix)

Current flow (`app.dart` `_RoleGate`) already switches on `AppUser.role` — keep that pattern, but fix two problems:

1. **Anyone can self-select "Administrator" at signup.** Remove `Administrator` from the sign-up dropdown entirely. Admin accounts should only be created manually (Firebase console / a Cloud Function invoked by an existing admin), never through public sign-up. Keep `Customer`, `Driver Partner`, and `Vendor / Store Owner` as the only public options.
2. **Vendor sign-up currently drops the user straight into "Coming Soon."** Fix the flow so:
   - Customer signs up → role `customer` → lands in `HomeShell` (already correct).
   - Driver signs up → role `driver` → **must** complete `DriverApplicationScreen` before reaching `DriverDashboardScreen` (this part already exists, just confirm the gate checks `approvalStatus` too, not just role, so unapproved drivers see a "pending approval" screen instead of the live dashboard).
   - Vendor signs up → role `vendor` → routed to the new **Vendor Onboarding screen** (§3.4) if no `vendors` doc with `ownerId == uid` exists yet → once submitted, show a "pending approval" screen (reuse the same pattern as drivers) → once an admin approves, routed to the **Vendor Dashboard**.

Add one field to `Vendor` in `models.dart`: `ownerId` (the uid of the user who registered the store) — this is what every vendor-side Firestore query will filter on.

---

## 5. Removing mock/demo data — checklist

Good news: the screens themselves are already Firestore-backed. What's left is cleanup, not a rewrite:

- [ ] `lib/screens/auth/login_screen.dart` line ~99 — delete the stale comment `// Mock auth allows any credentials to pass through seamlessly.` (the code beneath it is real Firebase auth already; the comment is just misleading/outdated).
- [ ] `lib/screens/admin/admin_dashboard_screen.dart` — remove the `/// Demo admin screen` doc comment once real role-gating (§4) is in place; it stops being a demo at that point.
- [ ] `README.md` §3 and §6 — currently says "product catalogue is currently a hardcoded demo list per vendor" and "UI complete, demo data" — **this is now inaccurate**; the actual code reads from `vendors/{id}/products` already. Update the README so it doesn't undersell/mis-describe the current state, and add Liquor to the services table (it's implemented in code but missing from the README's "three services" description).
- [ ] Seed **real starter data** instead of demo data: once the Vendor onboarding flow (§3.4) exists, the correct way to populate the app for a demo/launch is to have 2–3 real Thaba Nchu shop owners actually register through the app, not to hardcode sample vendors again.

---

## 6. Stock management for bigger stores (Shoprite / Jwayelane-scale)

A single spaza shop can manage 20 products by hand in the app. A Shoprite or a larger store like Jwayelane needs a fundamentally different capturing method — hundreds/thousands of SKUs, multiple tills, and stock that changes constantly. Recommended approach:

1. **Bulk import/export (CSV/Excel)** — add an "Import products" button in the Vendor dashboard's Menu tab that accepts a CSV (`name, category, price, quantity, sku, barcode`) and batch-writes to `vendors/{id}/products` using Firestore batched writes (max 500 per batch). This alone solves 90% of the big-store onboarding pain — a store's existing till/ERP export can usually already produce a CSV like this.
2. **Barcode/SKU field on `Product`** — add `sku` (string) so a future barcode-scan flow (`mobile_scanner` package) can look up and adjust stock without typing.
3. **Quantity-based stock instead of a boolean** — change `Product.inStock` to `Product.quantity` (int), and derive "in stock" as `quantity > 0` everywhere it's currently checked. Every order that includes this product should **atomically decrement `quantity`** via a Firestore transaction/Cloud Function (not a plain client-side `update`), so two simultaneous orders can't both "succeed" on the last unit.
4. **Low-stock threshold + alerts** — add `lowStockThreshold` (default e.g. 5) to `Product`; when `quantity` crosses that line, flag it in the Vendor dashboard's Menu tab (a small red "Low stock" badge) so staff know to reorder — no need for a notification system in v1.
5. **Multi-branch support** — a chain like Shoprite operates many physical branches under one brand. Model this as: `vendors/{brandId}` (the brand/catalogue owner) → `vendors/{brandId}/branches/{branchId}` (each physical store, with its own `localArea`, `lat`/`lng`, opening hours, and **its own stock counts** in `branches/{branchId}/stock/{productId}` referencing the shared catalogue). Customers browse by branch (nearest/local-area filtered); the vendor dashboard lets a manager pick which branch they're managing stock for, or see all branches at once if they're HQ-level.
6. **Reference diagram included:** `chain_store_stock_flow.png` (attached) shows how HQ catalogue, branch-level stock, the customer app, and an atomic stock-decrementing Cloud Function all fit together.

This is intentionally staged — a small spaza owner never has to touch CSV import or branches; those features only appear once a vendor's product count or `isChainBrand` flag crosses a threshold, so the UI stays simple for the majority of local shop owners.

---

## 7. Making sure all 4 services are consistently handled

Groceries, Fast Food, Liquor, and Cab are already all represented in `ServiceType` and have their own screens — good foundation. To make them feel like one coherent product rather than three services plus one bolted on:

1. **Home dashboard tab order and icons** — confirm all 4 appear as equal peers (Groceries, Food, Liquor, Cab), not 3 + an afterthought.
2. **Vendor onboarding must ask "which service type"** up front (Groceries / Food / Liquor), since that determines which customer tab the store appears under.
3. **README and any pitch/marketing copy** — update from "three services" to "four services," per §5.
4. **Liquor-specific requirement:** add an **age-verification checkbox/date-of-birth check** at checkout for liquor orders specifically (South African law: 18+). This is currently missing and is a legal/compliance gap, not just a UI nicety.
5. **Cab is structurally different** (a ride, not a cart of items) — keep it on its own booking flow, but make sure its entry point/branding matches the other three visually (same card style, same use of the new blue palette for its buttons/status pills).

---

## 8. Data collected at each step — completeness check

| Step | Currently collected | Should also collect |
|---|---|---|
| Sign up | Name, phone/email, password, role | — (role list fixed per §4) |
| Complete profile (customer/driver) | Local area, GPS position | — looks complete |
| Driver application | Vehicle type, ID number, proof of address, ID doc, selfie | — looks complete |
| **Vendor onboarding (new)** | — doesn't exist yet | Store name, service type, local area + address, banner photo, opening hours, contact number, `ownerId` |
| **Product (menu item)** | Name, price, image, category, in-stock bool | **Quantity**, optional `sku`/barcode, optional `lowStockThreshold` |
| Checkout (liquor) | Items, drop-off area | **Age confirmation** |

---

## 9. Suggested build order

1. Theme swap to light blue/white (§2) — quick, visible win, touches one file.
2. Fix sign-up role list + admin route protection (§4, item 1 and Admin item in §3.5) — security fix, do this before anything else ships.
3. `Vendor` model: add `ownerId`, and `Product`: change `inStock` → `quantity` + `lowStockThreshold` + `sku` (§6, items 2–3).
4. Vendor onboarding screen + admin vendor-approval queue (§3.4, §3.5).
5. Vendor dashboard: Orders tab, then Menu/Products tab, then Store settings tab (§3.4).
6. Liquor age-verification at checkout (§7.4) — small but legally important.
7. Bulk CSV import + multi-branch model for chain stores (§6, items 1 and 5) — only needed once a real chain-scale vendor onboards, so this can trail the rest.
8. README/documentation cleanup (§5).

---

## 10. Attached assets

- `kgoro_logo_blue.png` — placeholder app logo in the new blue/white identity (gateway/arch motif)
- `banner_groceries.png`, `banner_food.png`, `banner_liquor.png`, `banner_cab.png` — placeholder service banners, ready to drop into `assets/images/`
- `chain_store_stock_flow.png` — reference diagram for the chain-store stock architecture in §6

These are intentionally simple flat-design placeholders so the app doesn't ship with broken image references while you implement the above — swap them for professional photography/artwork before a public launch.
