import 'dart:math';
import 'constants.dart';

class GeoUtils {
  /// Cheap bounding-box residency pre-check. This is a first-pass filter
  /// only — real residency approval also requires an uploaded proof of
  /// address / ID and (for drivers) admin review. See
  /// ResidencyVerificationService for the full flow.
  static bool isWithinThabaNchu(double lat, double lng) {
    return lat >= AppConstants.minLat &&
        lat <= AppConstants.maxLat &&
        lng >= AppConstants.minLng &&
        lng <= AppConstants.maxLng;
  }

  /// Haversine distance in kilometres between two coordinates.
  static double distanceKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const r = 6371.0; // Earth radius km
    final dLat = _deg2rad(lat2 - lat1);
    final dLng = _deg2rad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  static double _deg2rad(double deg) => deg * (pi / 180);

  static double distanceFromTownCentreKm(double lat, double lng) {
    return distanceKm(
      lat,
      lng,
      AppConstants.townCentreLat,
      AppConstants.townCentreLng,
    );
  }
}

class Validators {
  /// South African 13-digit ID number: YYMMDD SSSS C A Z, with the
  /// standard Luhn checksum as the final digit. Used only to sanity-check
  /// the format at signup — it does NOT confirm someone lives in Thaba
  /// Nchu (SA ID numbers don't encode a town), so it is combined with
  /// GPS + proof-of-address + admin review for driver approval.
  static bool isValidSAId(String id) {
    final cleaned = id.trim();
    if (!RegExp(r'^\d{13}$').hasMatch(cleaned)) return false;

    final digits = cleaned.split('').map(int.parse).toList();
    int sumOdd = 0;
    for (int i = 0; i < 12; i += 2) {
      sumOdd += digits[i];
    }
    String evenConcat = '';
    for (int i = 1; i < 12; i += 2) {
      evenConcat += digits[i].toString();
    }
    final evenDoubled = (int.parse(evenConcat) * 2).toString();
    final sumEven =
        evenDoubled.split('').map(int.parse).fold(0, (a, b) => a + b);
    final total = sumOdd + sumEven;
    final checkDigit = (10 - (total % 10)) % 10;
    return checkDigit == digits[12];
  }

  static bool isValidSaPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'\s|-'), '');
    return RegExp(r'^(\+27|0)[6-8][0-9]{8}$').hasMatch(cleaned);
  }

  static bool isValidEmail(String email) {
    return RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$').hasMatch(email.trim());
  }

  static String? requiredField(String? value, {String label = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }
}
