import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../providers/providers.dart';
import '../../services/pricing_service.dart';
import '../orders/ride_tracking_screen.dart';
import 'dart:async';

class CabBookingScreen extends ConsumerStatefulWidget {
  const CabBookingScreen({super.key});

  @override
  ConsumerState<CabBookingScreen> createState() => _CabBookingScreenState();
}

class _CabBookingScreenState extends ConsumerState<CabBookingScreen> {
  String? _pickupArea;
  String? _dropoffArea;
  bool _requesting = false;
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();

  // Center on Thaba Nchu by default
  static const CameraPosition _kDefaultPosition = CameraPosition(
    target: LatLng(AppConstants.townCentreLat, AppConstants.townCentreLng),
    zoom: 14.0,
  );

  Set<Marker> _markers = {};

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

  void _updateMarkersAndCamera() async {
    final markers = <Marker>{};
    LatLng? pickupLatLng;
    LatLng? dropoffLatLng;

    if (_pickupArea != null) {
      final coords = AppConstants.areaCoordinates[_pickupArea!] ?? [AppConstants.townCentreLat, AppConstants.townCentreLng];
      pickupLatLng = LatLng(coords[0], coords[1]);
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickupLatLng,
          infoWindow: InfoWindow(title: 'Pickup: $_pickupArea'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }

    if (_dropoffArea != null) {
      final coords = AppConstants.areaCoordinates[_dropoffArea!] ?? [AppConstants.townCentreLat, AppConstants.townCentreLng];
      dropoffLatLng = LatLng(coords[0], coords[1]);
      markers.add(
        Marker(
          markerId: const MarkerId('dropoff'),
          position: dropoffLatLng,
          infoWindow: InfoWindow(title: 'Drop-off: $_dropoffArea'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });

    final controller = await _controller.future;
    
    if (pickupLatLng != null && dropoffLatLng != null && pickupLatLng != dropoffLatLng) {
      // Zoom to fit both
      LatLngBounds bounds;
      if (pickupLatLng.latitude > dropoffLatLng.latitude && pickupLatLng.longitude > dropoffLatLng.longitude) {
        bounds = LatLngBounds(southwest: dropoffLatLng, northeast: pickupLatLng);
      } else if (pickupLatLng.longitude > dropoffLatLng.longitude) {
        bounds = LatLngBounds(
            southwest: LatLng(pickupLatLng.latitude, dropoffLatLng.longitude),
            northeast: LatLng(dropoffLatLng.latitude, pickupLatLng.longitude));
      } else if (pickupLatLng.latitude > dropoffLatLng.latitude) {
        bounds = LatLngBounds(
            southwest: LatLng(dropoffLatLng.latitude, pickupLatLng.longitude),
            northeast: LatLng(pickupLatLng.latitude, dropoffLatLng.longitude));
      } else {
        bounds = LatLngBounds(southwest: pickupLatLng, northeast: dropoffLatLng);
      }
      controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
    } else if (pickupLatLng != null) {
      controller.animateCamera(CameraUpdate.newLatLng(pickupLatLng));
    } else if (dropoffLatLng != null) {
      controller.animateCamera(CameraUpdate.newLatLng(dropoffLatLng));
    }
  }

  @override
  Widget build(BuildContext context) {
    final fare = _estimatedFare;

    return Scaffold(
      body: Stack(
        children: [
          // Background Map
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _kDefaultPosition,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: _markers,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          ),
          
          // Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: Material(
              elevation: 4,
              shape: const CircleBorder(),
              color: AppColors.surface,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          
          // Bottom UI Panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Book a ride', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink)),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _pickupArea,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.radio_button_checked_rounded, color: AppColors.veld),
                          hintText: 'Pickup area',
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        ),
                        items: AppConstants.localAreas
                            .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                            .toList(),
                        onChanged: (v) {
                          setState(() => _pickupArea = v);
                          _updateMarkersAndCamera();
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _dropoffArea,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.location_on_rounded, color: AppColors.error),
                          hintText: 'Drop-off area',
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        ),
                        items: AppConstants.localAreas
                            .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                            .toList(),
                        onChanged: (v) {
                          setState(() => _dropoffArea = v);
                          _updateMarkersAndCamera();
                        },
                      ),
                      
                      if (fare != null) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.mountainTint,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.mountain.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Estimated fare', style: TextStyle(color: AppColors.mountain.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  const Text('Standard car', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.mountain, fontSize: 15)),
                                ],
                              ),
                              Text('R${fare.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.mountain)),
                            ],
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: fare == null || _requesting ? null : () => _requestRide(fare),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.mountain,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: _requesting
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Text('Confirm Ride', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _requestRide(double fare) async {
    setState(() => _requesting = true);
    final user = ref.read(currentAppUserProvider).value;
    final pickupCoords = AppConstants.areaCoordinates[_pickupArea!] ?? [AppConstants.townCentreLat, AppConstants.townCentreLng];
    final dropoffCoords = AppConstants.areaCoordinates[_dropoffArea!] ?? [AppConstants.townCentreLat, AppConstants.townCentreLng];

    try {
      final docRef = await ref.read(firestoreServiceProvider).createRideRequest({
        'customerId': user?.id ?? 'demo',
        'pickupArea': _pickupArea,
        'dropoffArea': _dropoffArea,
        'pickupLat': pickupCoords[0],
        'pickupLng': pickupCoords[1],
        'dropoffLat': dropoffCoords[0],
        'dropoffLng': dropoffCoords[1],
        'estimatedFare': fare,
        'status': 0, // Pending
        'createdAt': DateTime.now().toIso8601String(),
      });
      if (!mounted) return;
      // Navigate to ride tracking instead of just popping back
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RideTrackingScreen(rideId: docRef.id),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not request ride. Check your connection.')),
        );
        setState(() => _requesting = false);
      }
    }
  }
}
