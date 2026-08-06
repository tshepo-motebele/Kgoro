import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_config.dart';

/// PayFast payment integration for South Africa.
///
/// PayFast works as a hosted checkout: we build a signed form,
/// redirect the user to payfast.co.za, and they return to a
/// success/cancel URL when done.
///
/// Docs: https://developers.payfast.co.za/docs
class PaymentService {
  /// Opens the PayFast hosted checkout for a given order.
  ///
  /// [orderId]    — Kgoro order ID (used as m_payment_id)
  /// [amountRand] — Total amount in South African Rand
  /// [itemName]   — Short description shown on the PayFast page
  /// [email]      — Customer's email address (pre-fills checkout)
  /// [firstName]  — Customer's first name
  static Future<bool> initiatePayment({
    required String orderId,
    required double amountRand,
    required String itemName,
    required String email,
    String firstName = 'Customer',
    String lastName  = '',
  }) async {
    final params = {
      'merchant_id':  AppConfig.payfastMerchantId,
      'merchant_key': AppConfig.payfastMerchantKey,
      'm_payment_id': orderId,
      'amount':       amountRand.toStringAsFixed(2),
      'item_name':    itemName,
      'name_first':   firstName,
      'name_last':    lastName,
      'email_address': email,
      // Return URLs — deep-link back into the app
      'return_url':   'kgoro://payment/success?orderId=$orderId',
      'cancel_url':   'kgoro://payment/cancel?orderId=$orderId',
      'notify_url':   'https://us-central1-${AppConfig.payfastMerchantId}.cloudfunctions.net/payfastItn',
    };

    // Generate signature
    final signature = _generateSignature(params, AppConfig.payfastPassphrase);
    params['signature'] = signature;

    final queryString = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final url = Uri.parse('${AppConfig.payfastBaseUrl}?$queryString');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      return true;
    }
    return false;
  }

  static String _generateSignature(Map<String, String> params, String passphrase) {
    // PayFast signature: MD5 of URL-encoded params (sorted by key) + passphrase
    final filtered = Map<String, String>.from(params)
      ..remove('signature');
    final paramString = filtered.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    final withPass = '$paramString&passphrase=${Uri.encodeComponent(passphrase)}';
    return md5.convert(utf8.encode(withPass)).toString();
  }

  /// Validates a PayFast ITN (Instant Transaction Notification) payload.
  /// This should be called server-side (Cloud Function) not on the client.
  /// Included here for reference / testing.
  static bool validateItn({
    required Map<String, String> itnData,
    required String passphrase,
  }) {
    final receivedSig = itnData['signature'] ?? '';
    final filtered    = Map<String, String>.from(itnData)..remove('signature');
    final paramString = filtered.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    final withPass = '$paramString&passphrase=${Uri.encodeComponent(passphrase)}';
    final expected = md5.convert(utf8.encode(withPass)).toString();
    return receivedSig == expected;
  }
}
