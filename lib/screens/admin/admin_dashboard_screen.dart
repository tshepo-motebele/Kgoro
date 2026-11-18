import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';

/// Stunning Admin Dashboard for Kgoro.
/// Provides full oversight of users, vendors, drivers, orders and pending applications.
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
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        title: const Text(
          'Kgoro Admin',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
        actions: const [SignOutIconButton()],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: AppColors.primaryDark,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: AppColors.naledi,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [
                Tab(icon: Icon(Icons.dashboard_rounded, size: 20), text: 'Overview'),
                Tab(icon: Icon(Icons.people_rounded, size: 20), text: 'Users'),
                Tab(icon: Icon(Icons.storefront_rounded, size: 20), text: 'Vendors'),
                Tab(icon: Icon(Icons.drive_eta_rounded, size: 20), text: 'Drivers'),
                Tab(icon: Icon(Icons.shopping_bag_rounded, size: 20), text: 'Orders'),
                Tab(icon: Icon(Icons.hourglass_top_rounded, size: 20), text: 'Pend. Drivers'),
                Tab(icon: Icon(Icons.hourglass_bottom_rounded, size: 20), text: 'Pend. Vendors'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _OverviewTab(),
          _AllUsersTab(),
          _AllVendorsTab(),
          _AllDriversTab(),
          _AllOrdersTab(),
          _PendingDriversTab(),
          _PendingVendorsTab(),
        ],
      ),
    );
  }
}

// ── Overview ──────────────────────────────────────────────────────────────────
class _OverviewTab extends ConsumerWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(firestoreServiceProvider).watchAllUsers();
    final vendors = ref.watch(firestoreServiceProvider).watchAllVendors();
    final drivers = ref.watch(firestoreServiceProvider).watchAllDrivers();
    final orders = ref.watch(firestoreServiceProvider).watchAllOrders();
    final pendingDrivers = ref.watch(firestoreServiceProvider).watchPendingDriverApplications();
    final pendingVendors = ref.watch(firestoreServiceProvider).watchPendingVendorApplications();

    return StreamBuilder(
      stream: users,
      builder: (context, usersSnap) {
        return StreamBuilder(
          stream: vendors,
          builder: (context, vendorsSnap) {
            return StreamBuilder(
              stream: drivers,
              builder: (context, driversSnap) {
                return StreamBuilder(
                  stream: orders,
                  builder: (context, ordersSnap) {
                    return StreamBuilder(
                      stream: pendingDrivers,
                      builder: (context, pDriversSnap) {
                        return StreamBuilder(
                          stream: pendingVendors,
                          builder: (context, pVendorsSnap) {
                            final u = usersSnap.data?.length ?? 0;
                            final v = vendorsSnap.data?.length ?? 0;
                            final d = driversSnap.data?.length ?? 0;
                            final o = ordersSnap.data?.length ?? 0;
                            final pd = pDriversSnap.data?.length ?? 0;
                            final pv = pVendorsSnap.data?.length ?? 0;

                            return ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                                const Text(
                                  'Platform Overview',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Real-time snapshot of Kgoro in Thaba Nchu',
                                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                                ),
                                const SizedBox(height: 20),
                                GridView.count(
                                  crossAxisCount: 2,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 1.4,
                                  children: [
                                    _StatCard(
                                      icon: Icons.people_rounded,
                                      label: 'Total Users',
                                      value: '$u',
                                      color: AppColors.primary,
                                    ),
                                    _StatCard(
                                      icon: Icons.storefront_rounded,
                                      label: 'Vendors',
                                      value: '$v',
                                      color: AppColors.primaryLight,
                                    ),
                                    _StatCard(
                                      icon: Icons.drive_eta_rounded,
                                      label: 'Drivers',
                                      value: '$d',
                                      color: AppColors.naledi,
                                    ),
                                    _StatCard(
                                      icon: Icons.shopping_bag_rounded,
                                      label: 'Orders',
                                      value: '$o',
                                      color: AppColors.success,
                                    ),
                                    _StatCard(
                                      icon: Icons.hourglass_top_rounded,
                                      label: 'Pending Drivers',
                                      value: '$pd',
                                      color: Colors.orange.shade600,
                                    ),
                                    _StatCard(
                                      icon: Icons.hourglass_bottom_rounded,
                                      label: 'Pending Vendors',
                                      value: '$pv',
                                      color: Colors.deepOrange.shade600,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'Quick Actions',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    _QuickChip(
                                      icon: Icons.person_add_alt_1_rounded,
                                      label: 'Review Drivers',
                                      onTap: () {
                                        // Could switch tab programmatically if needed
                                      },
                                    ),
                                    _QuickChip(
                                      icon: Icons.store_mall_directory_rounded,
                                      label: 'Review Vendors',
                                      onTap: () {},
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: AppColors.primary),
      label: Text(label),
      backgroundColor: AppColors.primary.withOpacity(0.1),
      side: BorderSide.none,
      onPressed: onTap,
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────
Color _statusColor(ApprovalStatus status) {
  switch (status) {
    case ApprovalStatus.approved:
      return AppColors.success;
    case ApprovalStatus.rejected:
      return AppColors.error;
    case ApprovalStatus.pendingReview:
      return Colors.orange;
    default:
      return AppColors.textMuted;
  }
}

Color _orderStatusColor(OrderStatus status) {
  switch (status) {
    case OrderStatus.delivered:
      return AppColors.success;
    case OrderStatus.cancelled:
      return AppColors.error;
    case OrderStatus.pending:
    case OrderStatus.matched:
    case OrderStatus.accepted:
      return Colors.orange;
    case OrderStatus.pickedUp:
    case OrderStatus.onTheWay:
      return AppColors.primary;
    default:
      return AppColors.primary;
  }
}

void _confirmDelete(BuildContext context, VoidCallback onConfirm) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Delete record?'),
      content: const Text('This action cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            onConfirm();
            Navigator.pop(ctx);
          },
          child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
}

// ── Users ─────────────────────────────────────────────────────────────────────
class _AllUsersTab extends ConsumerStatefulWidget {
  const _AllUsersTab();

  @override
  ConsumerState<_AllUsersTab> createState() => _AllUsersTabState();
}

class _AllUsersTabState extends ConsumerState<_AllUsersTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final stream = ref.watch(firestoreServiceProvider).watchAllUsers();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search users by name, email or phone…',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (v) => setState(() => _query = v.toLowerCase()),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<AppUser>>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const KgoroLoader();
              }
              var users = snapshot.data ?? [];
              if (_query.isNotEmpty) {
                users = users.where((u) {
                  return u.fullName.toLowerCase().contains(_query) ||
                      (u.email ?? '').toLowerCase().contains(_query) ||
                      u.phone.contains(_query);
                }).toList();
              }
              if (users.isEmpty) {
                return const EmptyState(
                  icon: Icons.people_outline_rounded,
                  title: 'No users found',
                  subtitle: 'Try adjusting your search.',
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: users.length,
                itemBuilder: (context, i) {
                  final user = users[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.15),
                        child: Text(
                          user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                        ),
                      ),
                      title: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('${user.email ?? user.phone} • ${user.role.name}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_rounded, color: AppColors.primary),
                            onPressed: () => _showUserRoleDialog(context, ref, user),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_rounded, color: Colors.red),
                            onPressed: () => _confirmDelete(context, () {
                              ref.read(firestoreServiceProvider).deleteUser(user.id);
                            }),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showUserRoleDialog(BuildContext context, WidgetRef ref, AppUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Change role · ${user.fullName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: UserRole.values.map((role) {
            final selected = user.role == role;
            return ListTile(
              leading: Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppColors.primary : null,
              ),
              title: Text(role.name),
              onTap: () async {
                final updated = user.copyWith(role: role);
                await ref.read(firestoreServiceProvider).upsertUser(updated);
                if (ctx.mounted) Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Vendors (all) ─────────────────────────────────────────────────────────────
class _AllVendorsTab extends ConsumerStatefulWidget {
  const _AllVendorsTab();

  @override
  ConsumerState<_AllVendorsTab> createState() => _AllVendorsTabState();
}

class _AllVendorsTabState extends ConsumerState<_AllVendorsTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final stream = ref.watch(firestoreServiceProvider).watchAllVendors();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search vendors…',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (v) => setState(() => _query = v.toLowerCase()),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Vendor>>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const KgoroLoader();
              var vendors = snapshot.data ?? [];
              if (_query.isNotEmpty) {
                vendors = vendors.where((v) => v.name.toLowerCase().contains(_query)).toList();
              }
              if (vendors.isEmpty) {
                return const EmptyState(
                  icon: Icons.storefront_outlined,
                  title: 'No vendors found',
                  subtitle: 'Approved and pending stores will appear here.',
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: vendors.length,
                itemBuilder: (context, i) {
                  final vendor = vendors[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primaryLight.withOpacity(0.2),
                        child: const Icon(Icons.storefront_rounded, color: AppColors.primaryDark),
                      ),
                      title: Text(vendor.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(vendor.localArea),
                          const SizedBox(height: 4),
                          StatusPill(
                            label: vendor.approvalStatus.name,
                            color: _statusColor(vendor.approvalStatus),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.tune_rounded, color: AppColors.primary),
                            onPressed: () => _showVendorStatusDialog(context, ref, vendor),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_rounded, color: Colors.red),
                            onPressed: () => _confirmDelete(context, () {
                              ref.read(firestoreServiceProvider).deleteVendor(vendor.id);
                            }),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showVendorStatusDialog(BuildContext context, WidgetRef ref, Vendor vendor) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Update status · ${vendor.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ApprovalStatus.values.map((status) {
            return ListTile(
              leading: Icon(Icons.circle, size: 12, color: _statusColor(status)),
              title: Text(status.name),
              onTap: () async {
                await ref.read(firestoreServiceProvider).setVendorApprovalStatus(vendor.id, status);
                if (ctx.mounted) Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Drivers (all) ─────────────────────────────────────────────────────────────
class _AllDriversTab extends ConsumerStatefulWidget {
  const _AllDriversTab();

  @override
  ConsumerState<_AllDriversTab> createState() => _AllDriversTabState();
}

class _AllDriversTabState extends ConsumerState<_AllDriversTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final stream = ref.watch(firestoreServiceProvider).watchAllDrivers();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search drivers…',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (v) => setState(() => _query = v.toLowerCase()),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<DriverProfile>>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const KgoroLoader();
              var drivers = snapshot.data ?? [];
              if (_query.isNotEmpty) {
                drivers = drivers.where((d) => d.userId.toLowerCase().contains(_query) || d.idNumber.contains(_query)).toList();
              }
              if (drivers.isEmpty) {
                return const EmptyState(
                  icon: Icons.drive_eta_outlined,
                  title: 'No drivers found',
                  subtitle: 'Approved and pending drivers will appear here.',
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: drivers.length,
                itemBuilder: (context, i) {
                  final driver = drivers[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.naledi.withOpacity(0.2),
                        child: const Icon(Icons.drive_eta_rounded, color: AppColors.primaryDark),
                      ),
                      title: Text('Driver ${driver.userId.substring(0, 6)}…', style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ID: ${driver.idNumber} · ${driver.vehicleType.label}'),
                          const SizedBox(height: 4),
                          StatusPill(
                            label: driver.approvalStatus.name,
                            color: _statusColor(driver.approvalStatus),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.tune_rounded, color: AppColors.primary),
                            onPressed: () => _showDriverStatusDialog(context, ref, driver),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_rounded, color: Colors.red),
                            onPressed: () => _confirmDelete(context, () {
                              ref.read(firestoreServiceProvider).deleteDriver(driver.userId);
                            }),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showDriverStatusDialog(BuildContext context, WidgetRef ref, DriverProfile driver) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Update driver status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ApprovalStatus.values.map((status) {
            return ListTile(
              leading: Icon(Icons.circle, size: 12, color: _statusColor(status)),
              title: Text(status.name),
              onTap: () async {
                await ref.read(firestoreServiceProvider).setDriverApprovalStatus(driver.userId, status);
                if (ctx.mounted) Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Orders ────────────────────────────────────────────────────────────────────
class _AllOrdersTab extends ConsumerStatefulWidget {
  const _AllOrdersTab();

  @override
  ConsumerState<_AllOrdersTab> createState() => _AllOrdersTabState();
}

class _AllOrdersTabState extends ConsumerState<_AllOrdersTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final stream = ref.watch(firestoreServiceProvider).watchAllOrders();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search orders by ID…',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (v) => setState(() => _query = v.toLowerCase()),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<KgoroOrder>>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const KgoroLoader();
              var orders = snapshot.data ?? [];
              if (_query.isNotEmpty) {
                orders = orders.where((o) => o.id.toLowerCase().contains(_query)).toList();
              }
              if (orders.isEmpty) {
                return const EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No orders yet',
                  subtitle: 'Customer orders will appear here in real time.',
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: orders.length,
                itemBuilder: (context, i) {
                  final order = orders[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: _orderStatusColor(order.status).withOpacity(0.15),
                        child: Icon(Icons.shopping_bag_rounded, color: _orderStatusColor(order.status)),
                      ),
                      title: Text('Order ${order.id.substring(0, 8)}…', style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('R${order.total.toStringAsFixed(2)}'),
                          const SizedBox(height: 4),
                          StatusPill(
                            label: order.status.name,
                            color: _orderStatusColor(order.status),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_rounded, color: AppColors.primary),
                        onPressed: () => _showOrderStatusDialog(context, ref, order),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showOrderStatusDialog(BuildContext context, WidgetRef ref, KgoroOrder order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Update order status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: OrderStatus.values.map((status) {
            return ListTile(
              leading: Icon(Icons.circle, size: 12, color: _orderStatusColor(status)),
              title: Text(status.name),
              onTap: () async {
                await ref.read(firestoreServiceProvider).updateOrderStatus(order.id, status);
                if (ctx.mounted) Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Pending Drivers ───────────────────────────────────────────────────────────
class _PendingDriversTab extends ConsumerWidget {
  const _PendingDriversTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(firestoreServiceProvider).watchPendingDriverApplications();

    return StreamBuilder<List<DriverProfile>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const KgoroLoader();
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
          itemBuilder: (context, i) => _DriverApplicationCard(profile: applications[i]),
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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.orange.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Driver Application',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.primaryDark),
                  ),
                ),
                StatusPill(label: profile.vehicleType.label, color: AppColors.naledi),
              ],
            ),
            const SizedBox(height: 10),
            _InfoRow(icon: Icons.badge_rounded, text: 'ID: ${profile.idNumber}'),
            _InfoRow(icon: Icons.verified_user_rounded, text: 'Vouches: ${profile.vouchedByUserIds.length}'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => ref
                        .read(firestoreServiceProvider)
                        .setDriverApprovalStatus(profile.userId, ApprovalStatus.rejected),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => ref
                        .read(firestoreServiceProvider)
                        .setDriverApprovalStatus(profile.userId, ApprovalStatus.approved),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
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

// ── Pending Vendors ───────────────────────────────────────────────────────────
class _PendingVendorsTab extends ConsumerWidget {
  const _PendingVendorsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(firestoreServiceProvider).watchPendingVendorApplications();

    return StreamBuilder<List<Vendor>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const KgoroLoader();
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
          itemBuilder: (context, i) => _VendorApplicationCard(vendor: vendors[i]),
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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.deepOrange.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    vendor.name,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.primaryDark),
                  ),
                ),
                StatusPill(label: _typeName, color: AppColors.primaryLight),
              ],
            ),
            const SizedBox(height: 10),
            _InfoRow(icon: Icons.location_on_rounded, text: vendor.localArea),
            if (vendor.address != null && vendor.address!.isNotEmpty)
              _InfoRow(icon: Icons.home_rounded, text: vendor.address!),
            if (vendor.contactPhone != null && vendor.contactPhone!.isNotEmpty)
              _InfoRow(icon: Icons.phone_rounded, text: vendor.contactPhone!),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => ref
                        .read(firestoreServiceProvider)
                        .setVendorApprovalStatus(vendor.id, ApprovalStatus.rejected),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => ref
                        .read(firestoreServiceProvider)
                        .setVendorApprovalStatus(vendor.id, ApprovalStatus.approved),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: AppColors.textMuted, fontSize: 13))),
        ],
      ),
    );
  }
}
