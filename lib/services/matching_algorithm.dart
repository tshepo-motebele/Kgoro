import 'dart:math';
import '../core/utils.dart';
import '../models/models.dart';
import '../core/constants.dart';

/// The heart of Kgoro's "job creation, not just gig work" promise.
///
/// A naive Uber-style matcher sends every job to whichever driver is
/// closest and fastest to accept. In a small town with maybe 150-300
/// active drivers, that consistently starves everyone except the top
/// 10-15% (usually the ones who already own a car and can afford to sit
/// near the mall all day). That defeats the point of building this for
/// *unskilled, unemployed* residents who might only have a bicycle.
///
/// So jobs are scored per-candidate-driver on four weighted factors
/// instead of distance alone:
///
///   score = w1*proximity + w2*fairness + w3*reliability + w4*vehicleFit
///
/// - proximity   : closer drivers still get preference (customers still
///                  want fast delivery — this isn't charity, it's a tiebreaker)
/// - fairness     : drivers who haven't worked in a while get a boost,
///                  spreading jobs across the whole active pool instead
///                  of a small clique
/// - reliability  : rating + acceptance rate, so quality still matters
/// - vehicleFit   : a foot/bicycle courier shouldn't be offered a
///                  12km grocery run; a car is better for a rainy day
///
/// This is intentionally a simple, explainable weighted-sum model
/// (not a black-box ML ranker) so town admins can audit *why* a job
/// went to a given driver — important for trust in a small community
/// where everyone will compare notes.
class DriverMatch {
  final DriverProfile driver;
  final double score;
  final double distanceKm;
  DriverMatch(this.driver, this.score, this.distanceKm);
}

class MatchingAlgorithm {
  // Tunable weights — sum to 1.0. Adjust via admin dashboard in future.
  static const double wProximity = 0.40;
  static const double wFairness = 0.25;
  static const double wReliability = 0.25;
  static const double wVehicleFit = 0.10;

  static const double maxSearchRadiusKm = 12;

  /// Returns candidate drivers ranked best-to-worst for a given job.
  /// [requiresVehicle] lets callers exclude foot couriers for long runs.
  static List<DriverMatch> rankDrivers({
    required List<DriverProfile> onlineDrivers,
    required double pickupLat,
    required double pickupLng,
    required double jobDistanceKm,
    bool isRainOrBadWeather = false,
  }) {
    final candidates = <DriverMatch>[];

    for (final driver in onlineDrivers) {
      if (driver.currentLat == null || driver.currentLng == null) continue;
      if (driver.approvalStatus != ApprovalStatus.approved) continue;

      final distance = GeoUtils.distanceKm(
        pickupLat,
        pickupLng,
        driver.currentLat!,
        driver.currentLng!,
      );
      if (distance > maxSearchRadiusKm) continue;

      final proximityScore = 1 - (distance / maxSearchRadiusKm).clamp(0, 1);

      // Fairness: idle time normalized with a soft cap at 6 hours (360 min)
      // so a driver who's been offline for a week doesn't dominate forever.
      final idleMinutes = min(driver.minutesSinceLastJob, 360).toDouble();
      final fairnessScore = idleMinutes / 360;

      final reliabilityScore =
          (driver.rating / 5.0) * 0.6 + driver.acceptanceRate * 0.4;

      final vehicleFitScore = _vehicleFitScore(
        driver.vehicleType,
        jobDistanceKm,
        isRainOrBadWeather,
      );

      final total = wProximity * proximityScore +
          wFairness * fairnessScore +
          wReliability * reliabilityScore +
          wVehicleFit * vehicleFitScore;

      candidates.add(DriverMatch(driver, total, distance));
    }

    candidates.sort((a, b) => b.score.compareTo(a.score));
    return candidates;
  }

  static double _vehicleFitScore(
    VehicleType type,
    double jobDistanceKm,
    bool badWeather,
  ) {
    switch (type) {
      case VehicleType.footOrBicycle:
        if (jobDistanceKm <= 2 && !badWeather) return 1.0;
        if (jobDistanceKm <= 4 && !badWeather) return 0.5;
        return 0.05;
      case VehicleType.motorbike:
        if (jobDistanceKm <= 8) return badWeather ? 0.6 : 1.0;
        return 0.4;
      case VehicleType.car:
        return badWeather ? 1.0 : 0.85;
      case VehicleType.bakkie:
        return jobDistanceKm > 6 || badWeather ? 1.0 : 0.7;
    }
  }

  /// Broadcast-then-timeout dispatch: offer to the top N ranked drivers
  /// simultaneously (like a group SMS), first to accept wins, others get
  /// notified "job taken". This avoids the classic problem of offering
  /// jobs one-at-a-time down a ranked list and losing minutes to timeouts
  /// — important on a service that may only have a handful of drivers
  /// online at 9pm on a Tuesday.
  static List<DriverMatch> topOffers(List<DriverMatch> ranked, {int n = 3}) {
    return ranked.take(n).toList();
  }
}
