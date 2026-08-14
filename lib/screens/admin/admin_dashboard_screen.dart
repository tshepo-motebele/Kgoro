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
    _tabController = TabController(length: 6, vsync: this);
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
        title: const Text('Admin Dashboard'),
        actions: const [
          SignOutIconButton(),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          dividerColor: Colors.transparent,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(icon: Icon(Icons.people_rounded), text: 'Users'),
            Tab(icon: Icon(Icons.storefront_rounded), text: 'Vendors'),
            Tab(icon: Icon(Icons.drive_eta_rounded), text: 'Drivers'),
            Tab(icon: Icon(Icons.shopping_bag_rounded), text: 'Orders'),
            Tab(icon: Icon(Icons.hourglass_top_rounded), text: 'Pend. Drivers'),
            Tab(icon: Icon(Icons.hourglass_top_rounded), text: 'Pend. Vendors'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _AllUsersTab(),
          _AllVendorsTab(),
          _AllDriversTab(),
          _AllOrdersTab(),
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
      case ServiceType.laundry:
        return 'Laundry';
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

// ---------------------------------------------------------------------------
// All Users Tab
// ---------------------------------------------------------------------------

class _AllUsersTab extends ConsumerWidget {
  const _AllUsersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersStream = ref.watch(firestoreServiceProvider).watchAllUsers();

    return StreamBuilder<List<AppUser>>(
      stream: usersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const KgoroLoader();
        final users = snapshot.data ?? [];
        if (users.isEmpty) return const Center(child: Text('No users found.'));

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, i) {
            final user = users[i];
            return ListTile(
              title: Text(user.fullName),
              subtitle: Text('${user.email ?? user.phone} • ${user.role.name}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_rounded, color: Colors.red),
                onPressed: () => _confirmDelete(context, () {
                  ref.read(firestoreServiceProvider).deleteUser(user.id);
                }),
              ),
              onTap: () => _showUserRoleDialog(context, ref, user),
            );
          },
        );
      },
    );
  }

  void _showUserRoleDialog(BuildContext context, WidgetRef ref, AppUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Role for ${user.fullName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: UserRole.values.map((role) => ListTile(
            title: Text(role.name),
            onTap: () async {
              final updated = user.copyWith(role: role);
              await ref.read(firestoreServiceProvider).upsertUser(updated);
              if (ctx.mounted) Navigator.pop(ctx);
            },
          )).toList(),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// All Vendors Tab
// ---------------------------------------------------------------------------

class _AllVendorsTab extends ConsumerWidget {
  const _AllVendorsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(firestoreServiceProvider).watchAllVendors();

    return StreamBuilder<List<Vendor>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const KgoroLoader();
        final vendors = snapshot.data ?? [];
        if (vendors.isEmpty) return const Center(child: Text('No vendors found.'));

        return ListView.builder(
          itemCount: vendors.length,
          itemBuilder: (context, i) {
            final vendor = vendors[i];
            return ListTile(
              title: Text(vendor.name),
              subtitle: Text('Status: ${vendor.approvalStatus.name}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_rounded, color: Colors.red),
                onPressed: () => _confirmDelete(context, () {
                  ref.read(firestoreServiceProvider).deleteVendor(vendor.id);
                }),
              ),
              onTap: () => _showVendorStatusDialog(context, ref, vendor),
            );
          },
        );
      },
    );
  }

  void _showVendorStatusDialog(BuildContext context, WidgetRef ref, Vendor vendor) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Status for ${vendor.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ApprovalStatus.values.map((status) => ListTile(
            title: Text(status.name),
            onTap: () async {
              await ref.read(firestoreServiceProvider).setVendorApprovalStatus(vendor.id, status);
              if (ctx.mounted) Navigator.pop(ctx);
            },
          )).toList(),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// All Drivers Tab
// ---------------------------------------------------------------------------

class _AllDriversTab extends ConsumerWidget {
  const _AllDriversTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(firestoreServiceProvider).watchAllDrivers();

    return StreamBuilder<List<DriverProfile>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const KgoroLoader();
        final drivers = snapshot.data ?? [];
        if (drivers.isEmpty) return const Center(child: Text('No drivers found.'));

        return ListView.builder(
          itemCount: drivers.length,
          itemBuilder: (context, i) {
            final driver = drivers[i];
            return ListTile(
              title: Text(driver.userId),
              subtitle: Text('Status: ${driver.approvalStatus.name}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_rounded, color: Colors.red),
                onPressed: () => _confirmDelete(context, () {
                  ref.read(firestoreServiceProvider).deleteDriver(driver.userId);
                }),
              ),
              onTap: () => _showDriverStatusDialog(context, ref, driver),
            );
          },
        );
      },
    );
  }

  void _showDriverStatusDialog(BuildContext context, WidgetRef ref, DriverProfile driver) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Status for Driver'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ApprovalStatus.values.map((status) => ListTile(
            title: Text(status.name),
            onTap: () async {
              await ref.read(firestoreServiceProvider).setDriverApprovalStatus(driver.userId, status);
              if (ctx.mounted) Navigator.pop(ctx);
            },
          )).toList(),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// All Orders Tab
// ---------------------------------------------------------------------------

class _AllOrdersTab extends ConsumerWidget {
  const _AllOrdersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(firestoreServiceProvider).watchAllOrders();

    return StreamBuilder<List<KgoroOrder>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const KgoroLoader();
        final orders = snapshot.data ?? [];
        if (orders.isEmpty) return const Center(child: Text('No orders found.'));

        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, i) {
            final order = orders[i];
            return ListTile(
              title: Text('Order: ${order.id}'),
              subtitle: Text('Status: ${order.status.name} | Total: R${order.total.toStringAsFixed(2)}'),
              onTap: () => _showOrderStatusDialog(context, ref, order),
            );
          },
        );
      },
    );
  }

  void _showOrderStatusDialog(BuildContext context, WidgetRef ref, KgoroOrder order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Order Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: OrderStatus.values.map((status) => ListTile(
            title: Text(status.name),
            onTap: () async {
              await ref.read(firestoreServiceProvider).updateOrderStatus(order.id, status);
              if (ctx.mounted) Navigator.pop(ctx);
            },
          )).toList(),
        ),
      ),
    );
  }
}

// Helper
void _confirmDelete(BuildContext context, VoidCallback onConfirm) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete record?'),
      content: const Text('This action cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(onPressed: () {
          onConfirm();
          Navigator.pop(ctx);
        }, child: const Text('Delete', style: TextStyle(color: Colors.red))),
      ],
    ),
  );
}
