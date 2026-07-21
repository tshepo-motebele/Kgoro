import '../core/utils.dart';
import '../models/models.dart';

enum ResidencyCheckLevel { fail, weak, moderate, strong }

class ResidencyCheckResult {
  final ResidencyCheckLevel level;
  final List<String> notes;
  ResidencyCheckResult(this.level, this.notes);

  bool get passesForCustomer => level != ResidencyCheckLevel.fail;

  /// Driving/earning access requires a stronger bar than just ordering
  /// food, since it involves handling customers' homes, cash, and goods.
  bool get passesForDriverApplication =>
      level == ResidencyCheckLevel.moderate ||
      level == ResidencyCheckLevel.strong;
}

/// South African ID numbers don't encode a home town, and Home Affairs
/// address data isn't something a community app can query directly.
/// So "is this really a Thaba Nchu resident" is answered with layered,
/// low-cost signals instead of one silver bullet — each individually
/// spoofable, but combined they're a solid practical bar for a town
/// this size, and the review queue catches anything borderline:
///
///  1. GPS bounding box at signup (device must physically be in/near town)
///  2. Selected local area/ward from a fixed list (can't be typed freely)
///  3. Uploaded proof of address (municipal bill, letter from a Kgotla/
///     ward councillor, school proof, etc.) — reviewed by an admin
///  4. Valid-format SA ID document upload
///  5. Community vouching: 2 existing verified residents can vouch for
///     a new driver applicant, which matters a lot in a town this size
///     where people generally know each other
///
/// This composite score decides whether someone can register as a
/// *customer* (light touch — mostly just needs to be near the service
/// area) versus apply as a *driver* (needs the fuller stack, since
/// they'll be trusted with deliveries, cash, and community trust).
class ResidencyVerificationService {
  static ResidencyCheckResult evaluateForCustomer({
    required double? deviceLat,
    required double? deviceLng,
    required String selectedLocalArea,
  }) {
    final notes = <String>[];
    bool withinBox = false;
    if (deviceLat != null && deviceLng != null) {
      withinBox = GeoUtils.isWithinThabaNchu(deviceLat, deviceLng);
      notes.add(withinBox
          ? 'Device location is within the Thaba Nchu service area.'
          : 'Device location is outside the service area — orders may be limited.');
    } else {
      notes.add('Location permission not granted; area selection only.');
    }

    if (selectedLocalArea.isEmpty) {
      return ResidencyCheckResult(ResidencyCheckLevel.fail, [
        ...notes,
        'No local area selected.',
      ]);
    }

    if (withinBox) {
      return ResidencyCheckResult(ResidencyCheckLevel.strong, notes);
    }
    // Still let people order (e.g. visiting family, weak GPS indoors) but
    // flag it — this is a delivery app for the town, not a fortress.
    return ResidencyCheckResult(ResidencyCheckLevel.weak, notes);
  }

  static ResidencyCheckResult evaluateForDriverApplication({
    required double? deviceLat,
    required double? deviceLng,
    required String idNumber,
    required bool hasProofOfAddress,
    required bool hasIdDocument,
    required int voucherCount,
  }) {
    final notes = <String>[];
    int strength = 0;

    if (deviceLat != null &&
        deviceLng != null &&
        GeoUtils.isWithinThabaNchu(deviceLat, deviceLng)) {
      strength += 1;
      notes.add('✓ GPS location within service area');
    } else {
      notes.add('✗ GPS location not confirmed within service area');
    }

    if (Validators.isValidSAId(idNumber)) {
      strength += 1;
      notes.add('✓ ID number passes format/checksum validation');
    } else {
      notes.add('✗ ID number failed validation — check digits');
    }

    if (hasIdDocument) {
      strength += 1;
      notes.add('✓ ID document uploaded (pending admin review)');
    } else {
      notes.add('✗ No ID document uploaded');
    }

    if (hasProofOfAddress) {
      strength += 2; // weighted higher — this is the strongest single signal
      notes.add('✓ Proof of address uploaded (pending admin review)');
    } else {
      notes.add('✗ No proof of address uploaded');
    }

    if (voucherCount >= 2) {
      strength += 1;
      notes.add('✓ Vouched for by $voucherCount verified residents');
    } else {
      notes.add(
          '${voucherCount > 0 ? "✓" : "✗"} $voucherCount/2 community vouches');
    }

    ResidencyCheckLevel level;
    if (strength >= 5) {
      level = ResidencyCheckLevel.strong;
    } else if (strength >= 3) {
      level = ResidencyCheckLevel.moderate;
    } else if (strength >= 1) {
      level = ResidencyCheckLevel.weak;
    } else {
      level = ResidencyCheckLevel.fail;
    }

    return ResidencyCheckResult(level, notes);
  }
}
