import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';

/// Driver job offers screen — shows open orders/rides the driver has been
/// offered. The driver can Accept or Decline each offer.
/// Mounted inside DriverDashboardScreen as a tab.
class DriverJobsScreen extends ConsumerWidget {
  final String driverUid;
  const DriverJobsScreen({super.key, required this.driverUid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen for orders where this driver is a candidate (has been offered the job)
    final offeredOrders = FirebaseFirestore.instance
        .collection('orders')
        .where('candidateDriverIds', arrayContains: driverUid)
        .where('status', isEqualTo: 0) // pending
        .snapshots();

    final offeredRides = FirebaseFirestore.instance
        .collection('rides')
        .where('candidateDriverIds', arrayContains: driverUid)
        .where('status', isEqualTo: 0)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: offeredOrders,
      builder: (ctx, orderSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: offeredRides,
          builder: (ctx2, rideSnap) {
            final orderDocs = orderSnap.data?.docs ?? [];
            final rideDocs  = rideSnap.data?.docs ?? [];

            if (orderDocs.isEmpty && rideDocs.isEmpty) {
              return const EmptyState(
                icon:     Icons.inbox_rounded,
                title:    'No job offers',
                subtitle: 'Stay online — offers appear here in real time.',
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (orderDocs.isNotEmpty) ...[
                  _sectionHeader('📦 Delivery offers'),
                  ...orderDocs.map((doc) => _DeliveryOfferCard(
                        docId: doc.id,
                        data:  doc.data() as Map<String, dynamic>,
                        driverUid: driverUid,
                      )),
                ],
                if (rideDocs.isNotEmpty) ...[
                  _sectionHeader('🚕 Ride offers'),
                  ...rideDocs.map((doc) => _RideOfferCard(
                        docId: doc.id,
                        data:  doc.data() as Map<String, dynamic>,
                        driverUid: driverUid,
                      )),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _sectionHeader(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.primaryDark)),
      );
}

// ─── Delivery offer card ──────────────────────────────────────────────────────

class _DeliveryOfferCard extends ConsumerStatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  final String driverUid;
  const _DeliveryOfferCard({
    required this.docId,
    required this.data,
    required this.driverUid,
  });

  @override
  ConsumerState<_DeliveryOfferCard> createState() => _DeliveryOfferCardState();
}

class _DeliveryOfferCardState extends ConsumerState<_DeliveryOfferCard> {
  bool _loading = false;

  Future<void> _accept() async {
    setState(() => _loading = true);
    try {
      // Update driver location before accepting
      try {
        final pos = await Geolocator.getCurrentPosition();
        await ref
            .read(firestoreServiceProvider)
            .updateDriverLocation(widget.driverUid, pos.latitude, pos.longitude);
      } catch (_) {}

      // Transactional accept via Cloud Function
      final result = await FirebaseFunctions.instance
          .httpsCallable('acceptJob')
          .call({'orderId': widget.docId});

      if (mounted && result.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job accepted! Head to the store.')),
        );
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Could not accept job')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _decline() async {
    // Remove driver from candidateDriverIds
    await FirebaseFirestore.instance.collection('orders').doc(widget.docId).update({
      'candidateDriverIds': FieldValue.arrayRemove([widget.driverUid]),
    });
  }

  @override
  Widget build(BuildContext context) {
    final d    = widget.data;
    final total = (d['total'] as num?)?.toDouble() ?? 0;
    final items = (d['items'] as List?)?.length ?? 0;
    final area  = d['dropoffArea'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shopping_bag_rounded,
                    color: AppColors.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Delivery order — $items item(s)',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark),
                  ),
                ),
                Text('R${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        fontSize: 15)),
              ],
            ),
            const SizedBox(height: 6),
            Text('Drop-off: $area',
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _loading ? null : _decline,
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error)),
                    child: const Text('Decline',
                        style: TextStyle(color: AppColors.error)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : _accept,
                    child: _loading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Accept'),
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

// ─── Ride offer card ──────────────────────────────────────────────────────────

class _RideOfferCard extends ConsumerStatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  final String driverUid;
  const _RideOfferCard({
    required this.docId,
    required this.data,
    required this.driverUid,
  });

  @override
  ConsumerState<_RideOfferCard> createState() => _RideOfferCardState();
}

class _RideOfferCardState extends ConsumerState<_RideOfferCard> {
  bool _loading = false;

  Future<void> _accept() async {
    setState(() => _loading = true);
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('acceptJob')
          .call({'rideId': widget.docId});

      if (mounted && result.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride accepted! Head to pickup.')),
        );
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message ?? 'Error')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _decline() async {
    await FirebaseFirestore.instance.collection('rides').doc(widget.docId).update({
      'candidateDriverIds': FieldValue.arrayRemove([widget.driverUid]),
    });
  }

  @override
  Widget build(BuildContext context) {
    final d      = widget.data;
    final fare   = (d['estimatedFare'] as num?)?.toDouble() ?? 0;
    final pickup = d['pickupArea']  as String? ?? '';
    final drop   = d['dropoffArea'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_taxi_rounded,
                    color: AppColors.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('$pickup → $drop',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark)),
                ),
                Text('~R${fare.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        fontSize: 15)),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _loading ? null : _decline,
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error)),
                    child: const Text('Decline',
                        style: TextStyle(color: AppColors.error)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : _accept,
                    child: _loading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Accept'),
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
