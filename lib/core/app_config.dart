import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Central accessor for all environment variables loaded from .env
///
/// Usage examples:
///   AppConfig.googleMapsKey       → Maps API key for flutter_google_maps
///   AppConfig.payfastMerchantId   → PayFast merchant credentials
///   AppConfig.supportWhatsApp     → Support WhatsApp number
///
/// Firebase keys are consumed directly in firebase_options.dart and
/// do not need to be accessed via this class.
class AppConfig {
  AppConfig._();

  // ── Google Maps ──────────────────────────────────────────────────────────────
  /// API key used by flutter_google_maps / google_maps_flutter in Dart code.
  /// The Android manifest key is set separately via android/local.properties.
  static String get googleMapsKey =>
      dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  // ── PayFast (South Africa) ───────────────────────────────────────────────────
  static String get payfastMerchantId =>
      dotenv.env['PAYFAST_MERCHANT_ID'] ?? '';
  static String get payfastMerchantKey =>
      dotenv.env['PAYFAST_MERCHANT_KEY'] ?? '';
  static String get payfastPassphrase =>
      dotenv.env['PAYFAST_PASSPHRASE'] ?? '';
  static bool get payfastSandbox =>
      (dotenv.env['PAYFAST_SANDBOX'] ?? 'true').toLowerCase() == 'true';

  static String get payfastBaseUrl => payfastSandbox
      ? 'https://sandbox.payfast.co.za/eng/process'
      : 'https://www.payfast.co.za/eng/process';

  // ── Support ──────────────────────────────────────────────────────────────────
  static String get supportWhatsApp =>
      dotenv.env['SUPPORT_WHATSAPP_NUMBER'] ?? '27000000000';
  static String get supportEmail =>
      dotenv.env['SUPPORT_EMAIL'] ?? 'support@kgoro.co.za';
}
