import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';
import 'order_tracking_screen.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentAppUserProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('My orders')),
      body: user == null
          ? const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Sign in to see your orders',
              subtitle: 'Your delivery and ride history will appear here.',
            )
          : StreamBuilder<QuerySnapshot>(
              stream: ref.read(firestoreServiceProvider).watchCustomerOrders(user.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const KgoroLoader();
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No orders yet',
                    subtitle: 'Once you order groceries, food, or a ride, it will show up here.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    final order = KgoroOrder.fromMap(doc.id, doc.data() as Map<String, dynamic>);
                    
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.mountain.withValues(alpha: 0.12),
                          child: const Icon(Icons.shopping_bag_rounded, color: AppColors.mountain),
                        ),
                        title: Text('R${order.total.toStringAsFixed(2)}'),
                        subtitle: Text(order.dropoffArea),
                        trailing: StatusPill(
                          label: _statusLabel(order.status),
                          color: _statusColor(order.status),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OrderTrackingScreen(orderId: order.id),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  String _statusLabel(OrderStatus s) {
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
