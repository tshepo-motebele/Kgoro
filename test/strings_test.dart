import 'package:flutter_test/flutter_test.dart';
import 'package:kgoro/core/strings.dart';

void main() {
  test('returns English by default', () {
    expect(KgoroStrings.get('place_order'), 'Place order');
  });

  test('returns Setswana when requested', () {
    expect(KgoroStrings.get('place_order', lang: 'tn'), 'Romela odara');
  });

  test('falls back to key when missing', () {
    expect(KgoroStrings.get('unknown_key'), 'unknown_key');
  });
}
