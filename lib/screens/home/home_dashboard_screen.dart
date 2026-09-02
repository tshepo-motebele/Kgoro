import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';
import '../groceries/groceries_screen.dart';
import '../food/food_screen.dart';
import '../cab/cab_booking_screen.dart';
import '../liquor/liquor_screen.dart';
import '../laundry/laundry_screen.dart';
import '../driver/become_driver_intro_screen.dart';
import '../orders/order_tracking_screen.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentAppUserProvider);
    final activeOrder = ref.watch(activeOrderProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Offline banner ─────────────────────────────────────────────
          const KgoroOfflineBanner(),

          // ── Hero header ───────────────────────────────────────────────
          userAsync.when(
            data: (user) {
              final firstName = user?.fullName.split(' ').first ?? 'friend';
              final area = user?.localArea ?? 'Thaba Nchu';
              return HeroGradientHeader(
                greeting: 'Dumela, $firstName',
                subtitle: area,
                trailing: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35), width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      (user?.fullName.isNotEmpty == true)
                          ? user!.fullName[0].toUpperCase()
                          : 'K',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              );
            },
            loading: () => const HeroGradientHeader(
              greeting: 'Welcome to Kgoro',
              subtitle: 'Thaba Nchu',
            ),
            error: (_, __) => const HeroGradientHeader(
              greeting: 'Welcome to Kgoro',
              subtitle: 'Thaba Nchu',
            ),
          ),

          // ── Body ──────────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              children: [
                // ── Active order card (if an order is in progress) ──────
                if (activeOrder != null) ...[
                  ActiveOrderCard(
                    status: _statusLabel(activeOrder.status),
                    destination: activeOrder.dropoffArea,
                    onTrack: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            OrderTrackingScreen(orderId: activeOrder.id),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],

                const SectionHeader(title: 'Our Services'),
                const _ServiceGrid(),
                const SectionHeader(title: 'Earn with Kgoro'),
                const _EarnCard(),
                const SectionHeader(title: 'Why Kgoro?'),
                const _TrustBlock(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Finding driver';
      case OrderStatus.matched:
        return 'Driver matched';
      case OrderStatus.accepted:
        return 'Store preparing';
      case OrderStatus.pickedUp:
        return 'Picked up';
      case OrderStatus.onTheWay:
        return 'On the way';
      default:
        return 'In progress';
    }
  }
}

// ─── Service Grid ──────────────────────────────────────────────────────────────

class _ServiceGrid extends StatelessWidget {
  const _ServiceGrid();

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _TileData(
        title: 'Groceries',
        subtitle: 'Local shops',
        icon: Icons.local_grocery_store_rounded,
        color: AppColors.groceries,
        onTap: () => Navigator.of(context).push(_route(const GroceriesScreen())),
      ),
      _TileData(
        title: 'Food',
        subtitle: 'Kitchens & takeaways',
        icon: Icons.ramen_dining_rounded,
        color: AppColors.food,
        onTap: () => Navigator.of(context).push(_route(const FoodScreen())),
      ),
      _TileData(
        title: 'Liquor',
        subtitle: '18+ only',
        icon: Icons.local_bar_rounded,
        color: AppColors.liquor,
        onTap: () => Navigator.of(context).push(_route(const LiquorScreen())),
      ),
      _TileData(
        title: 'Cab',
        subtitle: 'Rides around town',
        icon: Icons.local_taxi_rounded,
        color: AppColors.cab,
        onTap: () => Navigator.of(context).push(_route(const CabBookingScreen())),
      ),
      _TileData(
        title: 'Laundry',
        subtitle: 'Wash & fold',
        icon: Icons.local_laundry_service_rounded,
        color: AppColors.laundry,
        onTap: () => Navigator.of(context).push(_route(const LaundryScreen())),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.1,
      children: List.generate(
        tiles.length,
        (i) => AnimatedServiceCard(
          title: tiles[i].title,
          subtitle: tiles[i].subtitle,
          icon: tiles[i].icon,
          color: tiles[i].color,
          onTap: tiles[i].onTap,
          index: i,
        ),
      ),
    );
  }

  PageRouteBuilder _route(Widget page) => PageRouteBuilder(
        pageBuilder: (_, animation, __) => page,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                      begin: const Offset(0.05, 0), end: Offset.zero)
                  .animate(CurvedAnimation(
                      parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 280),
      );
}

class _TileData {
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _TileData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

// ─── Earn Card ────────────────────────────────────────────────────────────────

class _EarnCard extends StatelessWidget {
  const _EarnCard();

  @override
  Widget build(BuildContext context) {
    return StaggeredFadeSlide(
      index: 5,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF174A3A), Color(0xFF1F6B52)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.mountain.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Earn on your own terms',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Walk, cycle, or drive. Fair-match spreads jobs across all local drivers equally.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white, width: 1.5),
                      minimumSize: const Size(0, 38),
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                    label: const Text('Apply now',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const BecomeDriverIntroScreen()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_bike_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Trust Block ──────────────────────────────────────────────────────────────

class _TrustBlock extends StatelessWidget {
  const _TrustBlock();

  @override
  Widget build(BuildContext context) {
    return StaggeredFadeSlide(
      index: 6,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.line),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Column(
          children: [
            _TrustRow(
              icon: Icons.verified_user_rounded,
              color: AppColors.mountain,
              text:
                  'Every customer, vendor, and driver is verified as a Thaba Nchu resident.',
            ),
            SizedBox(height: 16),
            Divider(height: 1),
            SizedBox(height: 16),
            _TrustRow(
              icon: Icons.balance_rounded,
              color: AppColors.veld,
              text:
                  'Fair-match technology spreads jobs across all drivers — not just the busiest few.',
            ),
            SizedBox(height: 16),
            Divider(height: 1),
            SizedBox(height: 16),
            _TrustRow(
              icon: Icons.trending_up_rounded,
              color: AppColors.naledi,
              text:
                  'Surge pricing is capped at 1.3× so deliveries stay affordable during busy times.',
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _TrustRow({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 19, color: color),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.5,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.ink,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
