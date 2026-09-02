import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../providers/providers.dart';
import '../widgets/common_widgets.dart';
import 'home/home_dashboard_screen.dart';
import 'orders/orders_screen.dart';
import 'profile/profile_screen.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(selectedServiceTabProvider);
    const screens = [
      HomeDashboardScreen(),
      OrdersScreen(),
      ProfileScreen(),
    ];

    return Scaffold(
      body: Column(
        children: [
          const KgoroOfflineBanner(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: IndexedStack(key: ValueKey(tab), index: tab, children: screens),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(
            top: BorderSide(color: AppColors.line, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (i) =>
              ref.read(selectedServiceTabProvider.notifier).state = i,
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.mountainTint,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: AppColors.mountain),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon:
                  Icon(Icons.receipt_long_rounded, color: AppColors.mountain),
              label: 'Orders',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon:
                  Icon(Icons.person_rounded, color: AppColors.mountain),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
