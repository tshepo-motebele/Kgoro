/// Simple bilingual strings (English + Setswana) for key UI.
/// Expand as needed for full localisation.
class KgoroStrings {
  static const Map<String, Map<String, String>> _s = {
    'place_order': {'en': 'Place order', 'tn': 'Romela odara'},
    'cash_on_delivery': {'en': 'Cash on delivery', 'tn': 'Tshelete fa o amogela'},
    'pay_with_payfast': {'en': 'Pay with PayFast', 'tn': 'Duelela ka PayFast'},
    'rate_order': {'en': 'Rate this order', 'tn': 'Kala odara e'},
    'thank_you': {'en': 'Thank you for your rating!', 'tn': 'Re leboga ka kalo ya gago!'},
    'youre_online': {'en': "You're online", 'tn': 'O mo inthaneteng'},
    'youre_offline': {'en': "You're offline", 'tn': 'Ga o mo inthaneteng'},
  };

  static String get(String key, {String lang = 'en'}) {
    return _s[key]?[lang] ?? _s[key]?['en'] ?? key;
  }
}
