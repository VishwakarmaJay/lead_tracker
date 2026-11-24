/// Turns a phone number as typed or imported into E.164 (`+919876543210`)
/// for matching and duplicate detection.
///
/// The original string is always stored separately; this value is only a
/// lookup key. Returns `null` when the number can't be normalised confidently
/// — such leads are kept but excluded from automatic matching.
///
/// Rules:
/// - `+` or `00` prefix → international; the country code is kept as given
///   (never re-interpreted as Indian).
/// - Otherwise the default country code applies (India `+91` by default):
///   one leading trunk `0` is dropped, and for India a 12-digit number starting
///   with `91` is treated as already carrying the country code.
/// - Spaces, hyphens, dots, and parentheses are ignored. Any other character
///   makes the number invalid.
class PhoneNormalizer {
  const PhoneNormalizer({this.defaultCountryCode = '+91'});

  /// E.g. `+91`. Configurable in Settings (`default_country_calling_code`).
  final String defaultCountryCode;

  static final _separators = RegExp(r'[\s\-().]');
  static final _plusAndDigits = RegExp(r'^\+?\d+$');
  static final _e164Digits = RegExp(r'^[1-9]\d{6,14}$');
  static final _indianNational = RegExp(r'^[1-9]\d{9}$');

  String? normalize(String input) {
    final cleaned = input.trim().replaceAll(_separators, '');
    if (cleaned.isEmpty || !_plusAndDigits.hasMatch(cleaned)) {
      return null;
    }
    if (cleaned.startsWith('+')) {
      return _international(cleaned.substring(1));
    }
    if (cleaned.startsWith('00')) {
      return _international(cleaned.substring(2));
    }
    return _national(cleaned);
  }

  bool isValid(String input) => normalize(input) != null;

  String? _national(String digits) {
    final countryCode = defaultCountryCode.replaceFirst('+', '');
    if (countryCode == '91') {
      var national = digits;
      if (national.length == 11 && national.startsWith('0')) {
        national = national.substring(1);
      } else if (national.length == 12 && national.startsWith('91')) {
        national = national.substring(2);
      }
      return _indianNational.hasMatch(national) ? '+91$national' : null;
    }
    final national = digits.startsWith('0') ? digits.substring(1) : digits;
    return _international('$countryCode$national');
  }

  String? _international(String digits) {
    if (!_e164Digits.hasMatch(digits)) {
      return null;
    }
    if (digits.startsWith('91') &&
        !_indianNational.hasMatch(digits.substring(2))) {
      return null;
    }
    return '+$digits';
  }
}
