import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';
import 'order_tracking_screen.dart';
import 'ride_tracking_screen.dart';

/// Unified "My Orders" screen — shows both delivery orders and cab rides,
/// sorted newest-first. Tapping an order opens [OrderTrackingScreen];
/// tapping a ride opens [RideTrackingScreen].
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentAppUserProvider).value;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My orders')),
        body: const EmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'Sign in to see your orders',
          subtitle: 'Your delivery and ride history will appear here.',
          lottieUrl: 'https://assets9.lottiefiles.com/packages/lf20_x62chj8y.json',
        ),
      );
    }

    final ordersAsync = ref.watch(customerOrdersProvider);
    final ridesAsync = ref.watch(customerRidesProvider);

    // Show shimmer until at least one stream is loaded
    final loading = ordersAsync.isLoading || ridesAsync.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('My orders')),
      body: loading
          ? const KgoroShimmerList()
          : _buildCombinedList(
              context,
              orders: ordersAsync.value ?? [],
              rides: ridesAsync.value ?? [],
            ),
    );
  }

  Widget _buildCombinedList(
    BuildContext context, {
    required List<KgoroOrder> orders,
    required List<RideRequest> rides,
  }) {
    // Build a unified list of displayable items sorted by createdAt descending.
    final items = <_ListItem>[
      for (final o in orders) _ListItem.order(o),
      for (final r in rides) _ListItem.ride(r),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No orders yet',
        subtitle:
            'Once you order groceries, food, a ride, or anything else, it will show up here.',
        lottieUrl: 'https://assets9.lottiefiles.com/packages/lf20_x62chj8y.json',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _buildItem(context, items[i]),
    );
  }

  Widget _buildItem(BuildContext context, _ListItem item) {
    if (item.order != null) {
      final order = item.order!;
      return Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.mountain.withValues(alpha: 0.12),
            child: const Icon(Icons.shopping_bag_rounded,
                color: AppColors.mountain),
          ),
          title: Text('R${order.total.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(order.dropoffArea),
          trailing: StatusPill(
            label: _orderStatusLabel(order.status),
            color: _statusColor(order.status),
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => OrderTrackingScreen(orderId: order.id)),
          ),
        ),
      );
    } else {
      final ride = item.ride!;
      return Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.naledi.withValues(alpha: 0.12),
            child: const Icon(Icons.local_taxi_rounded,
                color: AppColors.naledi),
          ),
          title: Text('R${ride.estimatedFare.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text('${ride.pickupArea} → ${ride.dropoffArea}'),
          trailing: StatusPill(
            label: _rideStatusLabel(ride.status),
            color: _statusColor(ride.status),
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => RideTrackingScreen(rideId: ride.id)),
          ),
        ),
      );
    }
  }

  String _orderStatusLabel(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending:
        return 'Finding driver';
      case OrderStatus.matched:
        return 'Matched';
      case OrderStatus.accepted:
        return 'Accepted';
      case OrderStatus.pickedUp:
        return 'Picked up';
      case OrderStatus.onTheWay:
        return 'On the way';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _rideStatusLabel(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending:
        return 'Finding driver';
      case OrderStatus.matched:
        return 'Driver matched';
      case OrderStatus.accepted:
        return 'Driver en route';
      case OrderStatus.pickedUp:
        return 'Picked up';
      case OrderStatus.onTheWay:
        return 'Almost there';
      case OrderStatus.delivered:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _statusColor(OrderStatus s) {
    switch (s) {
      case OrderStatus.delivered:
        return AppColors.success;
      case OrderStatus.cancelled:
        return AppColors.error;
      case OrderStatus.pending:
        return AppColors.warning;
      default:
        return AppColors.mountain;
    }
  }
}

// ── Internal helper for sorting heterogeneous list items ──────────────────────

class _ListItem {
  final KgoroOrder? order;
  final RideRequest? ride;
  final DateTime createdAt;

  _ListItem.order(KgoroOrder o)
      : order = o,
        ride = null,
        createdAt = o.createdAt;

  _ListItem.ride(RideRequest r)
      : order = null,
        ride = r,
        createdAt = r.createdAt;
}
