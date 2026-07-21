import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';
import '../groceries/groceries_screen.dart';
import '../food/food_screen.dart';
import '../cab/cab_booking_screen.dart';
import '../liquor/liquor_screen.dart';
import '../driver/become_driver_intro_screen.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentAppUserProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero gradient header
          userAsync.when(
            data: (user) => HeroGradientHeader(
              greeting: 'Dumela, ${user?.fullName.split(' ').first ?? 'friend'} 👋',
              subtitle: user?.localArea ?? 'Thaba Nchu',
              trailing: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    (user?.fullName.isNotEmpty == true)
                        ? user!.fullName[0].toUpperCase()
                        : 'K',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                ),
              ),
            ),
            loading: () => const HeroGradientHeader(
              greeting: 'Welcome to Kgoro',
              subtitle: 'Thaba Nchu',
            ),
            error: (_, __) => const HeroGradientHeader(
              greeting: 'Welcome to Kgoro',
              subtitle: 'Thaba Nchu',
            ),
          ),
          // Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              children: [
                const SectionHeader(title: 'Our Services'),
                const _ServiceGrid(),
                const SectionHeader(title: 'Earn with Kgoro'),
                const _EarnCard(),
                const SectionHeader(title: 'Why Kgoro?'),
                const _AboutCard(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
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
        color: const Color(0xFF00875A),
        onTap: () => Navigator.of(context).push(_route(const GroceriesScreen())),
      ),
      _TileData(
        title: 'Food',
        subtitle: 'Kitchens & takeaways',
        icon: Icons.ramen_dining_rounded,
        color: AppColors.mountain,
        onTap: () => Navigator.of(context).push(_route(const FoodScreen())),
      ),
      _TileData(
        title: 'Liquor',
        subtitle: '18+ only',
        icon: Icons.local_bar_rounded,
        color: const Color(0xFF6B3FA0),
        onTap: () => Navigator.of(context).push(_route(const LiquorScreen())),
      ),
      _TileData(
        title: 'Cab',
        subtitle: 'Rides around town',
        icon: Icons.local_taxi_rounded,
        color: const Color(0xFFFF991F),
        onTap: () => Navigator.of(context).push(_route(const CabBookingScreen())),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.15,
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
              position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero)
                  .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
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
            colors: [AppColors.primary, AppColors.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: AppColors.mountain.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Earn on your own terms',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17,
                          letterSpacing: -0.5)),
                  const SizedBox(height: 6),
                  Text(
                    'Walk, cycle or drive. Fair-match spreads jobs across all local drivers equally.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white, width: 1.5),
                      minimumSize: const Size(0, 40),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text('Apply now', style: TextStyle(fontWeight: FontWeight.w700)),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BecomeDriverIntroScreen()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.directions_bike_rounded, color: Colors.white, size: 56),
          ],
        ),
      ),
    );
  }
}

// ─── About Card ───────────────────────────────────────────────────────────────

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    return StaggeredFadeSlide(
      index: 6,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFEBECF0)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: const [
            _AboutPoint(
              icon: Icons.verified_user_rounded,
              color: Color(0xFF0052CC),
              text: 'Every customer, vendor and driver is verified as a Thaba Nchu resident.',
            ),
            SizedBox(height: 14),
            _AboutPoint(
              icon: Icons.balance_rounded,
              color: Color(0xFF00875A),
              text: 'Fair-match technology spreads delivery jobs across all drivers — not just the busiest few.',
            ),
            SizedBox(height: 14),
            _AboutPoint(
              icon: Icons.trending_up_rounded,
              color: Color(0xFFFF991F),
              text: 'Surge pricing is capped at 1.3× so deliveries stay affordable during busy times.',
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutPoint extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _AboutPoint({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text,
              style: const TextStyle(fontSize: 13.5, height: 1.45, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}
