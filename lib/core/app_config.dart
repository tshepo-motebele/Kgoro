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

  // ── Cloud Functions ───────────────────────────────────────────────────────────
  /// Base URL for Firebase Cloud Functions — used in PayFast ITN notify_url.
  /// Set CLOUD_FUNCTIONS_BASE_URL in .env e.g.:
  ///   CLOUD_FUNCTIONS_BASE_URL=https://us-central1-your-project.cloudfunctions.net
  static String get cloudFunctionsBaseUrl =>
      dotenv.env['CLOUD_FUNCTIONS_BASE_URL'] ??
      'https://us-central1-kgoro-app.cloudfunctions.net';

  // ── Support ──────────────────────────────────────────────────────────────────
  static String get supportWhatsApp =>
      dotenv.env['SUPPORT_WHATSAPP_NUMBER'] ?? '27000000000';
  static String get supportEmail =>
      dotenv.env['SUPPORT_EMAIL'] ?? 'support@kgoro.co.za';
}
