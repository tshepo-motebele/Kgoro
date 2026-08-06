import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';

/// Live order tracking screen — streams /orders/{orderId} in real time.
/// Customer sees a status timeline updating as the driver progresses.
class OrderTrackingScreen extends ConsumerWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order tracking')),
      body: StreamBuilder<KgoroOrder?>(
        stream: ref.read(firestoreServiceProvider).watchOrder(orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const KgoroLoader();
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const EmptyState(
              icon: Icons.receipt_long_rounded,
              title: 'Order not found',
              subtitle: 'This order may have been cancelled.',
            );
          }

          final order    = snapshot.data!;
          final status   = order.status;
          final total    = order.total;
          final items    = order.items;
          final area     = order.dropoffArea;
          final driverId = order.driverId;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Status Banner ───────────────────────────────────────────────
              _StatusBanner(status: status),
              const SizedBox(height: 24),

              // ── Timeline ────────────────────────────────────────────────────
              const Text('Progress',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.primaryDark)),
              const SizedBox(height: 12),
              _Timeline(current: status),
              const SizedBox(height: 24),

              // ── Driver card ──────────────────────────────────────────────────
              if (driverId != null) ...[
                const Text('Your driver',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.primaryDark)),
                const SizedBox(height: 10),
                _DriverCard(driverId: driverId),
                const SizedBox(height: 24),
              ],

              // ── Order summary ────────────────────────────────────────────────
              const Text('Order summary',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.primaryDark)),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...items.map((i) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${i['name']} × ${i['qty']}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                Text(
                                    'R${((i['price'] as num? ?? 0) * (i['qty'] as num? ?? 1)).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        color: AppColors.textMuted)),
                              ],
                            ),
                          )),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 15)),
                          Text('R${total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: AppColors.primary)),
                        ],
                      ),
                      if (area.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text('Deliver to: $area',
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 13)),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Status Banner ─────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final OrderStatus status;
  const _StatusBanner({required this.status});

  static const _messages = {
    OrderStatus.pending:   ('Looking for your driver…', Icons.hourglass_top_rounded, AppColors.warning),
    OrderStatus.matched:   ('Driver matched! Heading to pick up.', Icons.directions_run_rounded, AppColors.primary),
    OrderStatus.accepted:  ('Store is preparing your order.', Icons.store_rounded, AppColors.primary),
    OrderStatus.pickedUp:  ('Order picked up — on the way!', Icons.delivery_dining_rounded, AppColors.primary),
    OrderStatus.onTheWay:  ('Almost there! Driver is nearby.', Icons.near_me_rounded, AppColors.success),
    OrderStatus.delivered: ('Delivered! Enjoy 🎉', Icons.check_circle_rounded, AppColors.success),
    OrderStatus.cancelled: ('Order cancelled.', Icons.cancel_rounded, AppColors.error),
  };

  @override
  Widget build(BuildContext context) {
    final (msg, icon, color) = _messages[status] ??
        ('Processing…', Icons.sync_rounded, AppColors.textMuted);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Text(msg,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    height: 1.3)),
          ),
        ],
      ),
    );
  }
}

// ── Timeline ─────────────────────────────────────────────────────────────────

class _Timeline extends StatelessWidget {
  final OrderStatus current;
  const _Timeline({required this.current});

  static const _steps = [
    (OrderStatus.pending,   'Order received',        Icons.receipt_rounded),
    (OrderStatus.accepted,  'Store preparing',       Icons.store_rounded),
    (OrderStatus.pickedUp,  'Picked up',             Icons.handshake_rounded),
    (OrderStatus.onTheWay,  'On the way',            Icons.delivery_dining_rounded),
    (OrderStatus.delivered, 'Delivered',             Icons.check_circle_rounded),
  ];

  bool _isPast(OrderStatus step) => step.index <= current.index;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _steps.asMap().entries.map((e) {
        final i     = e.key;
        final (status, label, icon) = e.value;
        final done  = _isPast(status);
        final isLast = i == _steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: done ? AppColors.primary : const Color(0xFFDFE1E6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon,
                      size: 16,
                      color: done ? Colors.white : AppColors.textMuted),
                ),
                if (!isLast)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 2,
                    height: 32,
                    color: done ? AppColors.primary : const Color(0xFFDFE1E6),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(label,
                  style: TextStyle(
                      fontWeight:
                          done ? FontWeight.w700 : FontWeight.w400,
                      color: done
                          ? AppColors.primaryDark
                          : AppColors.textMuted,
                      fontSize: 14)),
            ),
          ],
        );
      }).toList(),
    );
  }
}

// ── Driver Card ───────────────────────────────────────────────────────────────

class _DriverCard extends ConsumerWidget {
  final String driverId;
  const _DriverCard({required this.driverId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance.collection('drivers').doc(driverId).snapshots(),
      builder: (ctx, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final d = snapshot.data!.data() as Map<String, dynamic>?;
        if (d == null) return const SizedBox.shrink();

        final rating   = (d['rating'] as num?)?.toDouble() ?? 5.0;
        final jobs     = d['completedJobs'] as int? ?? 0;
        final vehicle  = _vehicleLabel(d['vehicleType'] as int? ?? 2);

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.surfaceTint,
              child: const Icon(Icons.person_rounded, color: AppColors.primary),
            ),
            title: Text('Your driver',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(
                '$vehicle · ★ ${rating.toStringAsFixed(1)} · $jobs deliveries',
                style: const TextStyle(fontSize: 13)),
          ),
        );
      },
    );
  }

  String _vehicleLabel(int type) {
    switch (type) {
      case 0:  return 'On foot / Bicycle';
      case 1:  return 'Motorbike';
      case 2:  return 'Car';
      case 3:  return 'Bakkie';
      default: return 'Vehicle';
    }
  }
}
