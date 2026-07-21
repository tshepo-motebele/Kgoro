import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';

/// Admin dashboard — Drivers and Vendors approval queues.
/// In production this must be locked behind a Firestore custom-claim /
/// role check so ordinary users can never reach it.
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin — Pending Applications'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(icon: Icon(Icons.drive_eta_rounded), text: 'Drivers'),
            Tab(icon: Icon(Icons.storefront_rounded), text: 'Vendors'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _DriversTab(),
          _VendorsTab(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Drivers tab
// ---------------------------------------------------------------------------

class _DriversTab extends ConsumerWidget {
  const _DriversTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingStream =
        ref.watch(firestoreServiceProvider).watchPendingDriverApplications();

    return StreamBuilder<List<DriverProfile>>(
      stream: pendingStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const KgoroLoader();
        }
        final applications = snapshot.data ?? [];
        if (applications.isEmpty) {
          return const EmptyState(
            icon: Icons.inbox_rounded,
            title: 'No pending driver applications',
            subtitle: 'New driver applications will appear here for review.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: applications.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) =>
              _DriverApplicationCard(profile: applications[i]),
        );
      },
    );
  }
}

class _DriverApplicationCard extends ConsumerWidget {
  final DriverProfile profile;
  const _DriverApplicationCard({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Applicant ${profile.userId.substring(0, 6)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark)),
                ),
                StatusPill(
                    label: profile.vehicleType.label,
                    color: AppColors.primary),
              ],
            ),
            const SizedBox(height: 6),
            Text('ID: ${profile.idNumber}',
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 13)),
            Text('Vouches: ${profile.vouchedByUserIds.length}',
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => ref
                        .read(firestoreServiceProvider)
                        .setDriverApprovalStatus(
                            profile.userId, ApprovalStatus.rejected),
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error)),
                    child: const Text('Reject',
                        style: TextStyle(color: AppColors.error)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => ref
                        .read(firestoreServiceProvider)
                        .setDriverApprovalStatus(
                            profile.userId, ApprovalStatus.approved),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Vendors tab
// ---------------------------------------------------------------------------

class _VendorsTab extends ConsumerWidget {
  const _VendorsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingStream =
        ref.watch(firestoreServiceProvider).watchPendingVendorApplications();

    return StreamBuilder<List<Vendor>>(
      stream: pendingStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const KgoroLoader();
        }
        final vendors = snapshot.data ?? [];
        if (vendors.isEmpty) {
          return const EmptyState(
            icon: Icons.storefront_rounded,
            title: 'No pending vendor applications',
            subtitle: 'Store registration requests will appear here.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: vendors.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) =>
              _VendorApplicationCard(vendor: vendors[i]),
        );
      },
    );
  }
}

class _VendorApplicationCard extends ConsumerWidget {
  final Vendor vendor;
  const _VendorApplicationCard({required this.vendor});

  String get _typeName {
    switch (vendor.type) {
      case ServiceType.groceries:
        return 'Groceries';
      case ServiceType.food:
        return 'Fast Food';
      case ServiceType.liquor:
        return 'Liquor';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(vendor.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.primaryDark)),
                ),
                StatusPill(label: _typeName, color: AppColors.primaryLight),
              ],
            ),
            const SizedBox(height: 6),
            Text('Area: ${vendor.localArea}',
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 13)),
            if (vendor.address != null && vendor.address!.isNotEmpty)
              Text('Address: ${vendor.address}',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 13)),
            if (vendor.contactPhone != null &&
                vendor.contactPhone!.isNotEmpty)
              Text('Phone: ${vendor.contactPhone}',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 13)),
            Text(
                'Owner UID: ${vendor.ownerId?.substring(0, 8) ?? 'unknown'}…',
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => ref
                        .read(firestoreServiceProvider)
                        .setVendorApprovalStatus(
                            vendor.id, ApprovalStatus.rejected),
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error)),
                    child: const Text('Reject',
                        style: TextStyle(color: AppColors.error)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => ref
                        .read(firestoreServiceProvider)
                        .setVendorApprovalStatus(
                            vendor.id, ApprovalStatus.approved),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
