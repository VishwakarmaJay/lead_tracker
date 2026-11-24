import 'package:flutter_test/flutter_test.dart';
import 'package:lead_tracker/core/utils/phone_normalizer.dart';

void main() {
  const india = PhoneNormalizer();

  group('India default (+91)', () {
    final cases = {
      '9876543210': '+919876543210',
      '+91 98765 43210': '+919876543210',
      '09876543210': '+919876543210',
      '919876543210': '+919876543210',
      '0091 98765 43210': '+919876543210',
      '(+91) 98765-43210': '+919876543210',
      '98765.43210': '+919876543210',
      '  9876543210  ': '+919876543210',
      // Landline with STD code.
      '022 2345 6789': '+912223456789',
    };
    for (final MapEntry(key: input, value: expected) in cases.entries) {
      test('"$input" → $expected', () {
        expect(india.normalize(input), expected);
      });
    }

    test('keeps a foreign country code instead of assuming India', () {
      expect(india.normalize('+1 (415) 555-2671'), '+14155552671');
      expect(india.normalize('0044 20 7946 0958'), '+442079460958');
    });

    final invalid = [
      '',
      '   ',
      '12345',
      'abc',
      '98765abc10',
      '+91 12345',
      '+91 0987654321',
      '0000000000',
      '++919876543210',
      '98765 43210 ext 2',
    ];
    for (final input in invalid) {
      test('"$input" is invalid', () {
        expect(india.normalize(input), isNull);
        expect(india.isValid(input), isFalse);
      });
    }
  });

  test('other default country code', () {
    const us = PhoneNormalizer(defaultCountryCode: '+1');
    expect(us.normalize('415-555-2671'), '+14155552671');
    expect(us.normalize('+91 98765 43210'), '+919876543210');
  });
}
