# Kgoro design suggestions and implementation guide

## 1. Product direction

Kgoro is a local Thaba Nchu service marketplace: one trusted place for groceries,
food, liquor delivery, rides, customer orders, driver income, and vendor
operations.

The strongest design opportunity is to make the app feel **local, dependable,
and easy to act on**. It should feel like a helpful community service rather
than a generic delivery app or an admin dashboard.

### Design principles

1. **Local first** — use “Thaba Nchu”, the selected area, and friendly local
   language in prominent places. The user should always know that the app
   serves their community.
2. **One clear action per moment** — every screen should have one visually
   obvious next step: browse, add, request, apply, accept, or save.
3. **Trust before speed** — residency checks, driver verification, age checks,
   prices, and order status should be visible and understandable.
4. **Warm utility** — retain the app’s friendly energy, but reduce visual
   noise. Use color, icons, and motion deliberately instead of relying on
   emoji or many competing badges.
5. **Designed for real conditions** — support small screens, slower networks,
   bright outdoor light, limited data, and users who may be unfamiliar with
   delivery apps.

## 2. Current app strengths and gaps

The uploaded source already has a useful foundation:

- A clear three-tab customer shell: Home, Orders, Profile.
- Distinct service areas: Groceries, Food, Liquor, and Cab.
- Real loading, empty, error, and submission states.
- A meaningful order lifecycle from “Finding driver” to “Delivered”.
- Separate workflows for customers, drivers, vendors, and admins.
- Important trust flows: residency, South African ID, proof of address,
  vouches, and 18+ verification.
- Riverpod state management and Firebase-backed streams/actions.

The main improvements should be consistency and hierarchy:

- Several screens use slightly different blue tones, radii, shadows, and
  button styling.
- Some screens use emoji in section labels and status text. This can make the
  UI feel less polished and may create inconsistent rendering across devices.
- Core information such as delivery fee, order total, open/closed status, and
  approval state should have a consistent visual language.
- Forms are functional but can be made less intimidating with grouped sections,
  progress cues, clearer helper text, and more visible success feedback.
- The home screen can do more to communicate a user’s current area and active
  order before asking them to browse services.

## 3. Recommended visual language

### Brand feeling

Use a grounded palette inspired by the local landscape:

- **Mountain green** for trust, navigation, primary actions, and the Kgoro
  identity.
- **Warm gold** for highlights, ratings, earnings, and positive attention.
- **Veld green** for available/open/success states.
- **Clay or amber** for warnings and pending work.
- **Plum** only for the liquor category, keeping it visibly distinct.
- A warm off-white background instead of a cold gray or pure white canvas.

Keep service colors as accents rather than turning every page into a different
brand:

| Meaning | Suggested token | Hex |
| --- | --- | --- |
| Main brand / primary action | `mountain` | `#174A3A` |
| Primary light surface | `mountainTint` | `#E6F1EC` |
| Highlight / gold | `naledi` | `#E0A72F` |
| Available / success | `veld` | `#198754` |
| Pending / warning | `clay` | `#C47724` |
| Error | `error` | `#B54747` |
| Page background | `background` | `#F8F6F1` |
| Raised surface | `surface` | `#FFFFFF` |
| Main text | `ink` | `#1C2B26` |
| Secondary text | `muted` | `#68756F` |
| Borders | `line` | `#DDE5DF` |

These values are a starting point. If `AppColors` already defines a closer
brand palette, keep its names and map the existing values into the same roles
instead of introducing duplicate color constants.

### Typography

Use one legible sans-serif family throughout the product. A font such as
`Plus Jakarta Sans`, `Manrope`, or the platform default is suitable. Use a
strong weight difference rather than many font sizes:

- Display / onboarding title: 28–32, 800–900.
- Screen title: 20–22, 800.
- Section heading: 16–18, 800.
- Body: 14–16, regular, line height 1.45–1.6.
- Supporting text: 12–13, medium.
- Price / earnings: 18–24, 800–900.

Avoid all-caps paragraphs. Sentence case is friendlier and easier to scan.

### Shape and spacing

Use a small, repeatable scale:

- 4 px: icon/text micro-gap.
- 8 px: compact internal gap.
- 12 px: control and badge radius.
- 16 px: standard card and field spacing.
- 20 px: page padding on compact screens.
- 24 px: major card padding and section separation.
- 28 px: featured surfaces and modal corners.

Recommended corner radii:

- Inputs and compact controls: 12.
- Cards: 18.
- Featured hero surfaces: 24.
- Full-screen bottom sheets: 28 top corners.
- Pills: 999.

Prefer a subtle border plus a very light shadow over heavy elevation. This keeps
the app readable in bright outdoor conditions.

## 4. Create one source of truth for the theme

The uploaded screens currently style many widgets locally. Move the shared
decisions into `core/theme.dart`, then let screens override only category
accents or exceptional states.

```dart
import 'package:flutter/material.dart';

abstract final class KgoroColors {
  static const mountain = Color(0xFF174A3A);
  static const mountainTint = Color(0xFFE6F1EC);
  static const naledi = Color(0xFFE0A72F);
  static const veld = Color(0xFF198754);
  static const clay = Color(0xFFC47724);
  static const error = Color(0xFFB54747);
  static const background = Color(0xFFF8F6F1);
  static const surface = Colors.white;
  static const ink = Color(0xFF1C2B26);
  static const muted = Color(0xFF68756F);
  static const line = Color(0xFFDDE5DF);

  // Category accents are intentionally limited to small accents and icons.
  static const food = Color(0xFF2D6A4F);
  static const liquor = Color(0xFF6B3FA0);
  static const cab = Color(0xFFB9681E);
}

ThemeData buildKgoroTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: KgoroColors.mountain,
    brightness: Brightness.light,
  ).copyWith(
    primary: KgoroColors.mountain,
    onPrimary: Colors.white,
    secondary: KgoroColors.naledi,
    onSecondary: KgoroColors.ink,
    surface: KgoroColors.surface,
    onSurface: KgoroColors.ink,
    error: KgoroColors.error,
    onError: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: KgoroColors.background,
    fontFamily: 'Plus Jakarta Sans',
    appBarTheme: const AppBarTheme(
      backgroundColor: KgoroColors.background,
      foregroundColor: KgoroColors.ink,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: KgoroColors.ink,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    ),
    cardTheme: CardThemeData(
      color: KgoroColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: KgoroColors.line),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: KgoroColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: KgoroColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: KgoroColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: KgoroColors.mountain, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: KgoroColors.error),
      ),
      prefixIconColor: KgoroColors.muted,
      floatingLabelStyle: const TextStyle(
        color: KgoroColors.mountain,
        fontWeight: FontWeight.w700,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor: KgoroColors.mountain,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        foregroundColor: KgoroColors.mountain,
        side: const BorderSide(color: KgoroColors.mountain),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: KgoroColors.surface,
      indicatorColor: KgoroColors.mountainTint,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w600,
          color: states.contains(WidgetState.selected)
              ? KgoroColors.mountain
              : KgoroColors.muted,
        ),
      ),
    ),
  );
}
```

Apply it once at the root:

```dart
MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: buildKgoroTheme(),
  home: const SplashScreen(),
);
```

If the existing project uses `AppColors`, either rename `KgoroColors` to
`AppColors` or expose aliases. Do not maintain two independent palettes.

## 5. Reusable components to add

Create a small shared UI layer in `widgets/` so every role uses the same
language.

### 5.1 Status pill

Use this for open/closed, order status, approval status, low stock, and
residency verification. The color should communicate state, while the label
communicates the exact meaning.

```dart
class KgoroStatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const KgoroStatusPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
```

### 5.2 Consistent service card

Use the same component for Groceries, Food, Liquor, and Cab on the home
screen. Give each category its own icon and accent, but keep the structure
consistent.

```dart
class KgoroServiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  const KgoroServiceCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: KgoroColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: accent),
                ),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(
                    color: KgoroColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: KgoroColors.muted,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

### 5.3 Primary action with loading state

The uploaded source repeats loading button code in many screens. Centralize it
to prevent accidental double submissions and to make loading behavior
consistent.

```dart
class KgoroPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  const KgoroPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onPressed,
        icon: loading
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : Icon(icon ?? Icons.arrow_forward_rounded),
        label: Text(loading ? 'Please wait…' : label),
      ),
    );
  }
}
```

### 5.4 Empty state with a useful next step

Empty states should never stop at “nothing here”. Explain why and give one
next action where possible.

```dart
class KgoroEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const KgoroEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: KgoroColors.mountainTint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inbox_outlined,
                color: KgoroColors.mountain,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: KgoroColors.muted,
                height: 1.45,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

## 6. Screen-by-screen recommendations

### Splash screen

**Goal:** establish place and trust quickly.

- Keep the mountain/landscape mark and deep green background.
- Add a very short line such as “Local services. Fair opportunities.”
- Do not make the user wait longer than necessary. The current fixed 1.4-second
  delay should be replaced or shortened when initialization is complete.
- Avoid starting a new `Future.delayed` on every rebuild. Use a `StatefulWidget`
  or perform startup routing in the app bootstrap.

Suggested copy:

> Kgoro  
> Local services for Thaba Nchu

### Onboarding

The current four slides explain the product well. Improve them by:

- Replacing the `badge` emoji field with a small illustration or a second
  Material icon. This produces consistent rendering and better screen-reader
  output.
- Showing “1 of 4” in addition to the dots, useful for users who do not notice
  swipe indicators.
- Keeping the action label stable as “Continue” until the final slide, where it
  becomes “Get started”.
- Making “Skip” a quieter text action with enough tap area.
- Adding a small trust line on the final slide:
  “Built for local customers, stores, and drivers.”

Refactor the slide model:

```dart
class OnboardingSlide {
  final IconData icon;
  final Color accent;
  final String title;
  final String body;

  const OnboardingSlide({
    required this.icon,
    required this.accent,
    required this.title,
    required this.body,
  });
}
```

For the animation, keep the current scale entrance but add a gentle
`FadeTransition`. Avoid excessive elastic movement because it can feel playful
when the content is explaining safety, alcohol, or income.

### Login and sign-up

The two-tab structure is clear, but sign-up is carrying too much information at
once.

- Use a role selector with three large choices: Customer, Driver, Store owner.
- Show a short description below the selected role.
- Use “Email or phone number” as the label, with a separate helper for the
  accepted format.
- Add a password visibility button with a semantic label.
- Keep validation messages directly beneath the field.
- Preserve the “Forgot password?” path, but use a bottom sheet on small screens
  so the field remains visible behind the keyboard.
- Do not expose administrator registration in the public UI.

Example role selector:

```dart
class RoleOption extends StatelessWidget {
  final UserRole role;
  final UserRole selected;
  final String title;
  final String description;
  final IconData icon;
  final ValueChanged<UserRole> onSelected;

  const RoleOption({
    super.key,
    required this.role,
    required this.selected,
    required this.title,
    required this.description,
    required this.icon,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = role == selected;

    return Semantics(
      selected: isSelected,
      button: true,
      label: '$title. $description',
      child: InkWell(
        onTap: () => onSelected(role),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected ? KgoroColors.mountainTint : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? KgoroColors.mountain : KgoroColors.line,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? KgoroColors.mountain : KgoroColors.muted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: const TextStyle(
                        color: KgoroColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle_rounded, color: KgoroColors.mountain),
            ],
          ),
        ),
      ),
    );
  }
}
```

### Complete profile and residency

This is a trust-critical flow. Make the reason for location collection
explicit, not hidden in helper text:

1. Full name.
2. Local area.
3. Optional location confirmation.
4. A short explanation of how this helps delivery and verification.
5. Finish sign-up.

Recommendations:

- Show a “Step 1 of 1” or profile completion indicator.
- Use a visible “Why we ask for your location” expandable explanation.
- Show a success state after location permission is granted, not only a changed
  icon.
- If permission is denied, explain that area selection still works and provide
  a “Try again” action.
- Never show raw coordinates to the user.

### Home dashboard

The home screen is the main product surface and should answer three questions
within the first glance:

1. Where am I ordering from?
2. What can I do?
3. Is anything already in progress?

Recommended hierarchy:

- Header: “Dumela, [first name]” and a location chip such as “Thaba Nchu Town
  Centre”.
- If an order is active, show it above the service grid as a compact
  “Continue tracking” card.
- Services: keep the 2×2 grid, but make each card equal in height and make the
  entire card tappable.
- Earnings card: keep it, but make the benefit and action more prominent.
- Trust points: use a short “Why people use Kgoro” block with three rows.

Do not use a greeting emoji in the main greeting. Use a friendly icon in the
avatar or a small decorative mark instead. This is more consistent across
platforms and better for accessibility.

Example active-order card:

```dart
class ActiveOrderCard extends StatelessWidget {
  final String status;
  final String destination;
  final VoidCallback onTrack;

  const ActiveOrderCard({
    super.key,
    required this.status,
    required this.destination,
    required this.onTrack,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: KgoroColors.mountain,
      child: InkWell(
        onTap: onTrack,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(
                Icons.delivery_dining_rounded,
                color: Colors.white,
                size: 30,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your order is in progress',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$status · $destination',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
```

### Groceries, Food, and Liquor vendor lists

Keep the vendor list pattern consistent:

- Image or category icon.
- Vendor name.
- Area.
- Rating where available.
- Open/closed state.
- A clear chevron or full-card affordance.

Use the category accent only in the icon background and small status details.
Do not change the complete theme for every category.

Improve the list with:

- A search field for vendors.
- A compact “Open now” filter.
- A visible empty-state action such as “Ask a local shop to join Kgoro”.
- Cached image placeholders with a consistent aspect ratio.
- A clear distinction between closed vendors and unavailable products.

### Liquor flow

The current age verification is appropriately blocking. Make the compliance
experience even clearer:

- State “18+ only” before entering the section and again at checkout.
- Explain that ID may be checked at delivery.
- Do not allow the checkbox to be preselected.
- Use plain language and avoid playful decoration in the age dialog.
- Keep the “Go back” action visible and easy to understand.

Suggested checkout copy:

> I confirm that I am 18 or older. The delivery driver may request valid
> identification before handing over this order.

### Vendor detail and cart

On the vendor detail screen:

- Add a compact vendor header with open state and area.
- Group products by category with sticky or visually strong section labels.
- Make “Add” a high-contrast but compact action.
- After adding an item, show quantity controls in place and a small confirmation
  animation.
- Keep the extended cart button visible above the bottom safe area.

On the cart screen:

- Make the total panel visually stable at the bottom.
- Show subtotal, delivery fee, and total with consistent alignment.
- If a delivery area is missing, explain that a total cannot be calculated yet.
- Keep liquor age confirmation immediately before the final action.
- Disable “Place order” until all requirements are met, but explain the missing
  requirement instead of relying only on a disabled button.

### Cab booking

The two dropdowns are functional but can feel transactional. Improve clarity
with a simple route summary:

```dart
Widget routeSummary({
  required String? pickup,
  required String? dropoff,
  required double? fare,
}) {
  final ready = pickup != null && dropoff != null && fare != null;

  return AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: ready ? KgoroColors.mountainTint : Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: ready ? KgoroColors.mountain : KgoroColors.line,
      ),
    ),
    child: Row(
      children: [
        const Icon(Icons.route_rounded, color: KgoroColors.mountain),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            ready
                ? '$pickup to $dropoff'
                : 'Choose pickup and drop-off areas',
            style: TextStyle(
              color: ready ? KgoroColors.ink : KgoroColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (fare != null)
          Text(
            'R${fare.toStringAsFixed(2)}',
            style: const TextStyle(
              color: KgoroColors.mountain,
              fontWeight: FontWeight.w900,
            ),
          ),
      ],
    ),
  );
}
```

Also:

- Prevent selecting the same pickup and drop-off area, with a direct message.
- Explain that the fare is an estimate before request.
- After requesting, show a state such as “Finding a nearby driver” with a
  cancel option or a link to Orders.

### Orders and live tracking

This is the highest-value place for motion and live feedback.

- Keep the order list scannable: merchant/type, total, area, and status.
- Give active orders a stronger surface than completed orders.
- Use the timeline from the source, but make the current step visually
  dominant and future steps quieter.
- Always show the last update time when real-time data is available.
- For a cancelled order, explain what happened and what the user can do next.
- Avoid using emojis in status strings. Pair text with icons instead.

For example, replace:

```dart
'Delivered! Enjoy 🎉'
```

with:

```dart
const statusMessage = 'Delivered. Enjoy your order.';
const statusIcon = Icons.check_circle_rounded;
```

If a driver is assigned, show verification, vehicle type, rating, and a
contact/help action without exposing private identifiers.

### Profile

The profile screen should function as the user’s trust and role hub:

- Keep the avatar, name, phone, and residency badge at the top.
- Show “Become a driver” or “Driver dashboard” as the primary role action.
- Keep Admin visible only for admin users.
- Group support and account actions under a secondary section.
- Use a confirmation dialog before signing out if there is an active order.

The residency badge should be explicit:

- “Residency verified” with a check icon.
- “Verification in progress” with a pending icon.
- “Verification needed” with a next-step action.

### Driver dashboard

The driver experience should prioritize earnings and availability:

- Put the online/offline switch in the first card.
- Use a clear green online state and neutral offline state.
- Keep earnings, completed jobs, rating, and acceptance rate visible.
- Add a small “Last updated” label where metrics are streamed.
- Make offer cards time-sensitive without creating panic.
- Use full-width Accept and secondary Decline actions with enough spacing.

The current fairness explanation is a valuable differentiator. Give it a
“How matching works” expandable card so it is available without competing with
active job offers.

### Driver application

This form contains sensitive documents and should feel secure:

- Add a visible step indicator: Vehicle → Identity → Address → Location →
  Submit.
- Explain accepted document types before upload.
- Show preview thumbnails and “Replace” actions after selection.
- Show an upload progress state for each document.
- Do not silently swallow storage failures. Tell the user which upload failed
  and allow retry.
- After submission, show the current review state and what happens next.

Use a reusable upload tile:

```dart
class DocumentUploadTile extends StatelessWidget {
  final String title;
  final String helper;
  final bool uploaded;
  final VoidCallback onTap;

  const DocumentUploadTile({
    super.key,
    required this.title,
    required this.helper,
    required this.uploaded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = uploaded ? KgoroColors.veld : KgoroColors.mountain;

    return Semantics(
      button: true,
      label: uploaded ? '$title uploaded. Tap to replace.' : '$title. $helper',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: uploaded
                ? KgoroColors.veld.withValues(alpha: 0.07)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: uploaded ? KgoroColors.veld : KgoroColors.line,
            ),
          ),
          child: Row(
            children: [
              Icon(
                uploaded
                    ? Icons.check_circle_rounded
                    : Icons.upload_file_rounded,
                color: color,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(
                      uploaded ? 'Uploaded · Tap to replace' : helper,
                      style: const TextStyle(
                        color: KgoroColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: KgoroColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
```

### Vendor dashboard

The three tabs—Orders, Menu, Settings—are appropriate. Improve the operational
hierarchy:

- Show a “Store open” status in the app bar or first card.
- Put new orders first and give them a visible count.
- Keep the next order action obvious: “Mark as preparing”, “Ready for pickup”,
  and so on.
- In Menu, make stock status a first-class signal and keep “Add Product”
  persistent.
- Keep CSV import available, but present it as a secondary utility.
- In Settings, show a preview of the store banner and a clear save state.
- Use “Store is open” / “Store is closed” rather than a switch with no context.

For destructive actions such as deleting products, retain the confirmation
dialog and include the product name, as the source already does.

### Admin approval

Admin users need density and confidence:

- Show pending counts in the Drivers and Vendors tabs.
- Make applicant identity and application type easy to scan.
- Add a review detail view before approve/reject for documents and notes.
- Require confirmation for Reject and allow an optional reason.
- Show a success toast and remove the card only after the write succeeds.
- Keep admin access behind a server-side role/custom-claim check; hiding the
  tile in the UI is not a security boundary.

## 7. Navigation and motion

Use motion to explain transitions, not to decorate every tap:

- Screen transitions: 220–300 ms fade + short horizontal slide.
- Cards entering a list: 40–60 ms stagger, no more than 6 visible delays.
- Quantity changes: small scale or number transition.
- Order status: animate only when the status changes.
- Online/offline: animate the switch and status label together.
- Success: icon scale/fade once, then settle.

Respect reduced-motion settings:

```dart
final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

final duration = reduceMotion
    ? Duration.zero
    : const Duration(milliseconds: 220);
```

Do not animate a constantly rebuilding stream widget with a new animation on
every Firestore snapshot. Compare the previous status and animate only when it
changes.

## 8. Accessibility and South African context

- Keep interactive targets at least 48×48 logical pixels.
- Maintain strong contrast for text and controls.
- Never communicate status with color alone; pair it with a label and icon.
- Add `Semantics` labels to service cards, upload tiles, status pills, and
  driver online controls.
- Support large text without clipping. Test at 200% text scale.
- Use `TextInputType.phone` and accept E.164 phone numbers where required.
- Format Rand consistently: `R12.50`, not mixed currency patterns.
- Avoid exposing Firebase UIDs in visible UI.
- Keep legal/safety language plain and short.
- Use culturally relevant copy such as “Dumela” only when it remains
  understandable in context.
- Replace emoji used as essential status or section labels with icons. Icons
  render more consistently and can be described to assistive technology.

## 9. Data, state, and error presentation

The UI is driven by Riverpod and Firestore streams. Keep the design aligned
with those states:

| State | Visual treatment | Required action |
| --- | --- | --- |
| Loading | Skeleton or compact loader in the content region | None, but do not block the app shell |
| Empty | Icon, explanation, and next step | Action where one exists |
| Error | Plain-language message with retry | Retry or contact support |
| Saving | Disable only the relevant action and show progress | Prevent duplicate writes |
| Success | Confirmation, then return to the relevant context | Keep the user oriented |
| Permission denied | Explain why and provide alternate path | Try again or continue manually |

Use a typed UI state when a screen has more than one async operation. A simple
boolean such as `_loading` is fine for one submit action, but document uploads,
location, and Firestore writes should have separate states so one failure does
not make the entire form appear frozen.

Example error banner:

```dart
class KgoroErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const KgoroErrorBanner({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KgoroColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: KgoroColors.error.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: KgoroColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: KgoroColors.ink,
                height: 1.35,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}
```

## 10. Suggested implementation order

Implement the design in this order to get the biggest improvement with the
least rework:

### Phase 1 — foundation

1. Consolidate colors into `core/theme.dart`.
2. Add the typography, button, input, card, and navigation theme.
3. Replace local button/input/card styling on the Home, Orders, Profile, and
   Login screens.
4. Add shared `StatusPill`, primary button, empty state, and error banner.

### Phase 2 — customer experience

1. Refine the Home header and service grid.
2. Add active-order visibility to Home.
3. Standardize vendor cards across Groceries, Food, and Liquor.
4. Refine vendor detail, cart, delivery fee, and checkout states.
5. Improve order tracking hierarchy and status transitions.

### Phase 3 — trust and role workflows

1. Break profile completion and driver application into clearer groups.
2. Add document upload previews and retryable upload states.
3. Refine driver online/offline and offer actions.
4. Add vendor order counts, stock emphasis, and save states.
5. Add admin pending counts and reject confirmation reasons.

### Phase 4 — polish and resilience

1. Remove functional emoji usage and replace it with icons.
2. Add semantics and test large text.
3. Add reduced-motion handling.
4. Check keyboard behavior on every form.
5. Test loading, empty, error, permission-denied, and offline-ish states.
6. Test on a compact Android viewport and a larger tablet viewport.

## 11. Definition of done

The design refresh is complete when:

- All major customer, driver, vendor, and admin screens use the same theme.
- Primary actions look and behave consistently.
- Every async operation communicates loading, success, and failure.
- Open/closed, order, approval, and residency states have consistent pills and
  icons.
- The home screen shows location, services, and active order context quickly.
- Liquor age verification is clear, blocking, and repeated at checkout.
- Driver application and document upload states are understandable.
- No important status depends on emoji or color alone.
- The app remains usable with large text, screen readers, and reduced motion.
- The product still feels distinctly local to Thaba Nchu rather than like a
  generic delivery template.
