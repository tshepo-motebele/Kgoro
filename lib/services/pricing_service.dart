import 'dart:math';
import '../core/constants.dart';
import '../core/utils.dart';

/// Fare/delivery-fee calculation. Kgoro deliberately caps surge pricing
/// far below what Uber-style apps allow (max 1.3x vs the 2-5x common
/// elsewhere) because this app exists to serve one town's residents, not
/// to maximize extraction during a taxi strike or bad-weather spike —
/// those are exactly the moments people here can least afford it.
class PricingService {
  static const double baseFare = 15.0; // R15 flag-drop
  static const double perKmRate = 6.5; // R/km
  static const double perMinRate = 0.8; // R/min, covers traffic/wait
  static const double groceryBaseDeliveryFee = 20.0;
  static const double foodBaseDeliveryFee = 18.0;

  /// A simple, transparent demand/supply ratio drives the multiplier —
  /// no opaque ML "dynamic pricing" black box. Admins and drivers can
  /// both see the inputs.
  static double demandMultiplier({
    required int openRequestsNearby,
    required int onlineDriversNearby,
  }) {
    if (onlineDriversNearby == 0) return AppConstants.maxSurgeMultiplier;
    final ratio = openRequestsNearby / onlineDriversNearby;
    // ratio 0-1 -> 1.0x, ratio 1-2 -> up to 1.15x, ratio 2+ -> capped 1.3x
    final raw = 1.0 + (ratio - 1).clamp(0, double.infinity) * 0.15;
    return min(raw, AppConstants.maxSurgeMultiplier);
  }

  static double estimateRideFare({
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    double multiplier = 1.0,
    double estimatedMinutes = 0,
  }) {
    final distance =
        GeoUtils.distanceKm(pickupLat, pickupLng, dropoffLat, dropoffLng);
    final fare = baseFare +
        (distance * perKmRate) +
        (estimatedMinutes * perMinRate);
    return double.parse((fare * multiplier).toStringAsFixed(2));
  }

  static double estimateDeliveryFee({
    required ServiceType type,
    required double vendorLat,
    required double vendorLng,
    required double dropoffLat,
    required double dropoffLng,
    double multiplier = 1.0,
  }) {
    final distance =
        GeoUtils.distanceKm(vendorLat, vendorLng, dropoffLat, dropoffLng);
    final base = type == ServiceType.groceries
        ? groceryBaseDeliveryFee
        : foodBaseDeliveryFee;
    final fee = base + (distance * 3.5);
    return double.parse((fee * multiplier).toStringAsFixed(2));
  }

  /// Driver payout: kept intentionally generous relative to the fee —
  /// see README for the full commission philosophy. Community platform,
  /// not a VC-scale extraction model.
  static double driverPayout(double customerFee, {double commission = 0.15}) {
    return double.parse((customerFee * (1 - commission)).toStringAsFixed(2));
  }
}
