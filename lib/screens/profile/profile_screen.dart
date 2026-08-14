import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_config.dart';
import '../driver/driver_dashboard_screen.dart';
import '../driver/become_driver_intro_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../vendor/vendor_onboarding_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentAppUserProvider).value;
    final driverProfile = ref.watch(currentDriverProfileProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.naledi.withValues(alpha: 0.3),
                child: Text(
                  (user?.fullName.isNotEmpty ?? false) ? user!.fullName[0] : '?',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.fullName ?? 'Guest',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    Text(user?.phone ?? '', style: TextStyle(color: Colors.grey.shade600)),
                    const SizedBox(height: 6),
                    if (user != null) ResidencyBadge(verified: user.isResidencyVerified),
                  ],
                ),
              ),
              if (user != null)
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: AppColors.mountain),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => EditProfileScreen(user: user)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          if (driverProfile != null)
            _ProfileTile(
              icon: Icons.two_wheeler_rounded,
              title: 'Driver dashboard',
              subtitle: driverProfile.approvalStatus.name,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DriverDashboardScreen()),
              ),
            )
          else
            _ProfileTile(
              icon: Icons.handshake_rounded,
              title: 'Become a driver',
              subtitle: 'Earn money delivering or driving in Thaba Nchu',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BecomeDriverIntroScreen()),
              ),
            ),
          if (user?.role == UserRole.customer)
            _ProfileTile(
              icon: Icons.storefront_rounded,
              title: 'Register your store',
              subtitle: 'Start selling food, groceries, or services',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const VendorOnboardingScreen()),
              ),
            ),
          if (user?.role == UserRole.admin)
            _ProfileTile(
              icon: Icons.admin_panel_settings_rounded,
              title: 'Admin',
              subtitle: 'Review driver & vendor applications',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
              ),
            ),
          _ProfileTile(
            icon: Icons.help_outline_rounded,
            title: 'Help & support',
            subtitle: 'Contact the Kgoro team',
            onTap: () async {
              final url = Uri.parse('https://wa.me/${AppConfig.supportWhatsApp}?text=Hi%20Kgoro%20Support');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not open WhatsApp.')),
                  );
                }
              }
            },
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(authServiceProvider).signOutAndCleanup();
              // Invalidate critical state on sign out to prevent data leaking between sessions
              ref.invalidate(currentAppUserProvider);
              ref.invalidate(currentDriverProfileProvider);
              ref.invalidate(cartProvider);
            },
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            label: const Text('Sign out', style: TextStyle(color: AppColors.error)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ProfileTile(
      {required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: AppColors.mountain),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
