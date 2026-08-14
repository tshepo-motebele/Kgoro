import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';

/// Lightweight ride-detail / tracking screen for cab bookings.
/// Shown when a customer taps a [RideRequest] item in [OrdersScreen].
/// Streams the ride document live so status updates appear automatically.
class RideTrackingScreen extends ConsumerWidget {
  final String rideId;
  const RideTrackingScreen({super.key, required this.rideId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ride details')),
      body: StreamBuilder<RideRequest?>(
        stream: ref.read(firestoreServiceProvider).watchRide(rideId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const KgoroLoader();
          }
          final ride = snapshot.data;
          if (ride == null) {
            return const KgoroEmptyState(
              icon: Icons.local_taxi_rounded,
              title: 'Ride not found',
              message: 'This ride may have been removed or is no longer available.',
            );
          }
          return _RideDetailBody(ride: ride);
        },
      ),
    );
  }
}

class _RideDetailBody extends StatelessWidget {
  final RideRequest ride;
  const _RideDetailBody({required this.ride});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Status banner ───────────────────────────────────────────────────
        _StatusBanner(status: ride.status),
        const SizedBox(height: 20),

        // ── Route card ──────────────────────────────────────────────────────
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your route',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.primaryDark),
                ),
                const SizedBox(height: 14),
                _RouteRow(
                  icon: Icons.trip_origin_rounded,
                  iconColor: AppColors.mountain,
                  label: 'Pickup',
                  value: ride.pickupArea,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Container(
                    width: 2,
                    height: 24,
                    color: AppColors.line,
                  ),
                ),
                _RouteRow(
                  icon: Icons.location_on_rounded,
                  iconColor: AppColors.error,
                  label: 'Drop-off',
                  value: ride.dropoffArea,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // ── Fare card ───────────────────────────────────────────────────────
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.veld.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.payments_rounded,
                      color: AppColors.veld, size: 22),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Estimated fare',
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'R${ride.estimatedFare.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryDark),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // ── Driver card (shown once assigned) ───────────────────────────────
        if (ride.driverId != null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.mountainTint,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_rounded,
                        color: AppColors.mountain, size: 26),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Driver assigned',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDark,
                              fontSize: 14),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Your driver is on their way.',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],

        // ── Status timeline ─────────────────────────────────────────────────
        const SectionHeader(title: 'Ride progress'),
        _RideTimeline(status: ride.status),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _StatusBanner
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final OrderStatus status;
  const _StatusBanner({required this.status});

  String get _label {
    switch (status) {
      case OrderStatus.pending:
        return 'Finding your driver\u2026';
      case OrderStatus.matched:
        return 'Driver matched \u2014 confirming';
      case OrderStatus.accepted:
        return 'Driver on their way to you';
      case OrderStatus.pickedUp:
        return 'En route to destination';
      case OrderStatus.onTheWay:
        return 'Almost there!';
      case OrderStatus.delivered:
        return 'Ride completed';
      case OrderStatus.cancelled:
        return 'Ride cancelled';
    }
  }

  Color get _color {
    switch (status) {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.local_taxi_rounded, color: _color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _label,
              style: TextStyle(
                  color: _color, fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _RouteRow
// ─────────────────────────────────────────────────────────────────────────────

class _RouteRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  const _RouteRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 11)),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.ink)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _RideTimeline
// ─────────────────────────────────────────────────────────────────────────────

class _RideTimeline extends StatelessWidget {
  final OrderStatus status;
  const _RideTimeline({required this.status});

  static const _steps = [
    (OrderStatus.pending,   'Finding driver',          Icons.search_rounded),
    (OrderStatus.accepted,  'Driver on the way',       Icons.directions_car_rounded),
    (OrderStatus.pickedUp,  'You\'ve been picked up',  Icons.person_pin_circle_rounded),
    (OrderStatus.delivered, 'Arrived at destination',  Icons.flag_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _steps.map((step) {
        final (stepStatus, label, icon) = step;
        final isDone = status.index >= stepStatus.index &&
            status != OrderStatus.cancelled;
        final isActive = status == stepStatus;
        final color = isDone
            ? AppColors.mountain
            : isActive
                ? AppColors.naledi
                : AppColors.line;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDone
                      ? AppColors.mountain.withValues(alpha: 0.12)
                      : AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 1.5),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: isDone ? FontWeight.w700 : FontWeight.w500,
                    color: isDone ? AppColors.ink : AppColors.textMuted,
                    fontSize: 14,
                  ),
                ),
              ),
              if (isDone)
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.mountain, size: 16),
            ],
          ),
        );
      }).toList(),
    );
  }
}
