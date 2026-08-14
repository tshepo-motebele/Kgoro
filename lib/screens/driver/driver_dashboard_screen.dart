import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../core/constants.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';
import 'driver_jobs_screen.dart';
import 'driver_application_screen.dart';

class DriverDashboardScreen extends ConsumerStatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  ConsumerState<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends ConsumerState<DriverDashboardScreen> {
  bool _togglingOnline = false;

  Future<void> _toggleOnline(DriverProfile profile) async {
    setState(() => _togglingOnline = true);
    final newStatus = !profile.isOnline;
    if (newStatus) {
      try {
        final pos = await Geolocator.getCurrentPosition();
        await ref
            .read(firestoreServiceProvider)
            .updateDriverLocation(profile.userId, pos.latitude, pos.longitude);
      } catch (_) {}
    }
    await ref.read(firestoreServiceProvider).setDriverOnlineStatus(profile.userId, newStatus);
    setState(() => _togglingOnline = false);
  }

  @override
  Widget build(BuildContext context) {
    final driverAsync = ref.watch(currentDriverProfileProvider);

    return driverAsync.when(
      loading: () => const Scaffold(body: KgoroLoader()),
      error: (_, __) => const Scaffold(
        body: EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Something went wrong',
          subtitle: 'Please try again later.',
        ),
      ),
      data: (profile) {
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
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: AppColors.mountainTint,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.badge_outlined,
                          size: 40, color: AppColors.mountain),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No application found',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Complete your driver application — ID, proof of '
                      'address, and vehicle type — to start receiving job offers.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600, height: 1.5),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.drive_eta_rounded),
                      label: const Text('Apply now'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const DriverApplicationScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (profile.approvalStatus != ApprovalStatus.approved) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Driver dashboard'),
              actions: const [SignOutIconButton()],
            ),
            body: _PendingApprovalView(profile: profile),
          );
        }

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Driver dashboard'),
              actions: const [SignOutIconButton()],
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Dashboard'),
                  Tab(text: 'Offers'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.isOnline ? "You're online" : "You're offline",
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                            Text(
                              profile.isOnline
                                  ? 'Nearby jobs will be offered to you'
                                  : 'Go online to start receiving job offers',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: profile.isOnline,
                        activeTrackColor: AppColors.success,
                        onChanged: _togglingOnline ? null : (_) => _toggleOnline(profile),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'This week',
                      value: 'R${profile.earningsThisWeek.toStringAsFixed(0)}',
                      icon: Icons.payments_rounded,
                      color: AppColors.veld,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Completed jobs',
                      value: '${profile.completedJobs}',
                      icon: Icons.task_alt_rounded,
                      color: AppColors.mountain,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Rating',
                      value: profile.rating.toStringAsFixed(1),
                      icon: Icons.star_rounded,
                      color: AppColors.naledi,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Acceptance',
                      value: '${(profile.acceptanceRate * 100).toStringAsFixed(0)}%',
                      icon: Icons.thumb_up_rounded,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SectionHeader(title: 'How jobs are matched to you'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Kgoro spreads jobs fairly: drivers who haven\'t worked in a while are prioritised alongside distance, rating, and your vehicle type — so everyone gets a real chance to earn, not just the busiest few.',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4),
                  ),
                ),
              ),
            ],
          ),
          DriverJobsScreen(driverUid: profile.userId),
        ],
      ),
    ),
  );
},
);
}
}

class _PendingApprovalView extends StatelessWidget {
  final DriverProfile profile;
  const _PendingApprovalView({required this.profile});

  @override
  Widget build(BuildContext context) {
    final isMoreInfo = profile.approvalStatus == ApprovalStatus.moreInfoNeeded;
    final isRejected = profile.approvalStatus == ApprovalStatus.rejected;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isRejected
                  ? Icons.cancel_rounded
                  : isMoreInfo
                      ? Icons.info_rounded
                      : Icons.hourglass_top_rounded,
              size: 56,
              color: isRejected
                  ? AppColors.error
                  : isMoreInfo
                      ? AppColors.warning
                      : AppColors.naledi,
            ),
            const SizedBox(height: 16),
            Text(
              isRejected
                  ? 'Application not approved'
                  : isMoreInfo
                      ? 'More information needed'
                      : 'Application under review',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            const SizedBox(height: 8),
            Text(
              isRejected
                  ? 'Please contact support for details on next steps.'
                  : isMoreInfo
                      ? 'We need clearer documents or a stronger residency match. Please resubmit with a valid proof of address.'
                      : 'Our team is verifying your documents and residency. This usually takes 1-3 days.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}
