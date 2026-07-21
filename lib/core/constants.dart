/// Central place for everything that makes this "Thaba Nchu's app"
/// rather than a generic clone. Tune these as the real municipal
/// boundary / ward data becomes available.
class AppConstants {
  static const String appName = 'Kgoro';
  static const String appTagline = 'Groceries, Food, Rides & More — Just for Thaba Nchu.';

  /// Firebase / Maps keys are intentionally NOT hardcoded here.
  /// Add google-services.json (Android) and GoogleService-Info.plist (iOS)
  /// from your Firebase console, and put your Maps API key in:
  ///  - android/app/src/main/AndroidManifest.xml (com.google.android.geo.API_KEY)
  ///  - ios/Runner/AppDelegate.swift
  /// See README.md "Firebase & keys setup" section.

  /// Approximate operating area. Thaba 'Nchu town centre sits at
  /// roughly -29.20, 26.83. This bounding box is deliberately generous
  /// to include the surrounding wards/villages (Selosesha, Kromdraai,
  /// Rietfontein, Sediba, Setlogelo, Ratlou) so genuine residents on the
  /// edge of town aren't locked out. Replace with a proper polygon
  /// (municipal ward GeoJSON) once available — see GeoUtils.
  static const double minLat = -29.35;
  static const double maxLat = -29.05;
  static const double minLng = 26.68;
  static const double maxLng = 26.98;

  static const double townCentreLat = -29.20;
  static const double townCentreLng = 26.83;

  /// Local areas offered as a dropdown at signup/checkout instead of
  /// making people type an address freehand — faster on low-end phones
  /// and it doubles as a light residency signal.
  static const List<String> localAreas = [
    'Thaba Nchu Town Centre',
    'Selosesha',
    'Kromdraai',
    'Rietfontein',
    'Sediba',
    'Setlogelo',
    'Ratlou Village',
    'Bultfontein Section',
    'Moroka',
    'Sela',
  ];

  static const Map<String, List<double>> areaCoordinates = {
    'Thaba Nchu Town Centre': [-29.2000, 26.8333],
    'Selosesha': [-29.2150, 26.8200],
    'Kromdraai': [-29.1800, 26.8500],
    'Rietfontein': [-29.1900, 26.8000],
    'Sediba': [-29.2300, 26.8400],
    'Setlogelo': [-29.2200, 26.8600],
    'Ratlou Village': [-29.1700, 26.8300],
    'Bultfontein Section': [-29.2400, 26.8100],
    'Moroka': [-29.2050, 26.8700],
    'Sela': [-29.1850, 26.8800],
  };

  static const double serviceRadiusKm = 25;

  /// Fairness cap so a busy day never prices out the community it's
  /// meant to serve — see DemandPredictionService.
  static const double maxSurgeMultiplier = 1.3;
}

enum ServiceType { groceries, food, cab, liquor }

enum OrderStatus {
  pending,
  matched,
  accepted,
  pickedUp,
  onTheWay,
  delivered,
  cancelled,
}

enum VehicleType { footOrBicycle, motorbike, car, bakkie }

extension VehicleTypeLabel on VehicleType {
  String get label {
    switch (this) {
      case VehicleType.footOrBicycle:
        return 'On foot / Bicycle';
      case VehicleType.motorbike:
        return 'Motorbike';
      case VehicleType.car:
        return 'Car';
      case VehicleType.bakkie:
        return 'Bakkie / Taxi';
    }
  }
}

enum ApprovalStatus { pendingReview, approved, rejected, moreInfoNeeded }
