import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../providers/providers.dart';
import '../../services/pricing_service.dart';

class CabBookingScreen extends ConsumerStatefulWidget {
  const CabBookingScreen({super.key});

  @override
  ConsumerState<CabBookingScreen> createState() => _CabBookingScreenState();
}

class _CabBookingScreenState extends ConsumerState<CabBookingScreen> {
  String? _pickupArea;
  String? _dropoffArea;
  bool _requesting = false;

  double? get _estimatedFare {
    if (_pickupArea == null || _dropoffArea == null) return null;
    if (_pickupArea == _dropoffArea) return null;
    
    final pickupCoords = AppConstants.areaCoordinates[_pickupArea!] ?? [AppConstants.townCentreLat, AppConstants.townCentreLng];
    final dropoffCoords = AppConstants.areaCoordinates[_dropoffArea!] ?? [AppConstants.townCentreLat, AppConstants.townCentreLng];

    return PricingService.estimateRideFare(
      pickupLat: pickupCoords[0],
      pickupLng: pickupCoords[1],
      dropoffLat: dropoffCoords[0],
      dropoffLng: dropoffCoords[1],
      estimatedMinutes: 12, // A simple baseline for in-town rides
    );
  }

  @override
  Widget build(BuildContext context) {
    final fare = _estimatedFare;

    return Scaffold(
      appBar: AppBar(title: const Text('Book a cab')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Where from?', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _pickupArea,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.radio_button_checked_rounded, color: AppColors.veld),
                hintText: 'Pickup area',
              ),
              items: AppConstants.localAreas
                  .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                  .toList(),
              onChanged: (v) => setState(() => _pickupArea = v),
            ),
            const SizedBox(height: 18),
            const Text('Where to?', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _dropoffArea,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.location_on_rounded, color: AppColors.mountain),
                hintText: 'Drop-off area',
              ),
              items: AppConstants.localAreas
                  .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                  .toList(),
              onChanged: (v) => setState(() => _dropoffArea = v),
            ),
            const SizedBox(height: 24),
            if (fare != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Estimated fare', style: TextStyle(color: Colors.grey)),
                          Text('Standard car',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                      Text('R${fare.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
            const Spacer(),
            ElevatedButton(
              onPressed: fare == null || _requesting
                  ? null
                  : () => _requestRide(fare),
              child: _requesting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                    )
                  : const Text('Request ride'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestRide(double fare) async {
    setState(() => _requesting = true);
    final user = ref.read(currentAppUserProvider).value;
    final pickupCoords = AppConstants.areaCoordinates[_pickupArea!] ?? [AppConstants.townCentreLat, AppConstants.townCentreLng];
    final dropoffCoords = AppConstants.areaCoordinates[_dropoffArea!] ?? [AppConstants.townCentreLat, AppConstants.townCentreLng];

    try {
      await ref.read(firestoreServiceProvider).createRideRequest({
        'customerId': user?.id ?? 'demo',
        'pickupArea': _pickupArea,
        'dropoffArea': _dropoffArea,
        'pickupLat': pickupCoords[0],
        'pickupLng': pickupCoords[1],
        'dropoffLat': dropoffCoords[0],
        'dropoffLng': dropoffCoords[1],
        'estimatedFare': fare,
        'status': 0,
        'createdAt': DateTime.now().toIso8601String(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Looking for the fairest nearby driver…')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not request ride. Check your connection.')),
      );
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }
}
