/// Pure-string validation primitives shared by forms and extraction logic.
///
/// These are the single source of truth for "is this string valid" checks.
/// [ValidatorUtils] wraps them with Form-field error messages, and callers
/// that only need a boolean can use these directly.
class StringValidators {
  StringValidators._();

  /// RFC-ish email pattern: dot-separated atom in the local part (plus the
  /// common special characters), hostname labels, and a 2+ letter TLD.
  /// Not a full RFC 5322 parser, but rejects the practical false positives
  /// (`a@b`, `a@@b.com`, `@b.com`, trailing dots) that the old loose regex
  /// accepted.
  static final RegExp _emailRe = RegExp(
    r"^[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+)*"
    r'@[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?'
    r'(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?)*'
    r'\.[A-Za-z]{2,}$',
  );

  /// E.164: `+` followed by 7-15 digits, the first one non-zero. Checked
  /// against the separator-stripped form, so a spaced `+91 98765 43210`
  /// still qualifies.
  static final RegExp _e164Re = RegExp(r'^\+[1-9]\d{6,14}$');

  /// Plain 10-digit national fallback, checked against the separator-stripped
  /// form so any grouping (`9876543210`, `987-654-3210`, `98765 43210`) reads
  /// the same.
  static final RegExp _tenDigitRe = RegExp(r'^\d{10}$');

  /// Cosmetic phone separators: hyphen, dot and any whitespace (including the
  /// non-breaking spaces OCR emits).
  static final RegExp _phoneSeparatorRe = RegExp(r'[-.\s]');

  /// URL with optional scheme, registrable host, optional port and
  /// path/query/fragment (multi-segment paths allowed). Matched
  /// case-insensitively because hostnames and schemes are, and the TLD length
  /// is uncapped so modern suffixes (`.website`, `.technology`) pass.
  static final RegExp _urlRe = RegExp(
    r'^(?:https?://)?'
    r'(?:[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?\.)+[A-Za-z]{2,}'
    r'(?::\d{1,5})?'
    r'(?:[/?#]\S*)?$',
    caseSensitive: false,
  );

  /// Currency tokens understood by the app's expense extraction pipeline
  /// (see `_currencyToken` in `expense_extraction_service.dart`).
  static final RegExp _currencyPrefixRe = RegExp(
    r'^(?:₹|\$|€|£|\bRs\.?|\bINR|\bUSD|\bEUR|\bGBP)\s*',
    caseSensitive: false,
  );

  static final RegExp _currencySuffixRe = RegExp(
    r'\s*(?:₹|\$|€|£|\bRs\.?|\bINR|\bUSD|\bEUR|\bGBP)$',
    caseSensitive: false,
  );

  /// Any currency token still present after one token was stripped —
  /// used to reject mixed/duplicated markers like `₹1,29,900 USD`.
  static final RegExp _leftoverCurrencyRe = RegExp(
    r'[₹$€£]|\b(?:Rs|INR|USD|EUR|GBP)\b',
    caseSensitive: false,
  );

  /// Amount shapes mirrored from `expense_extraction_service.dart`:
  /// western grouping `1,299.90`, Indian grouping `1,29,900`,
  /// European dot-grouping with decimal comma `1.299,90`,
  /// bare decimal comma `1299,90`, plain `1299.90` / `1299`.
  static final List<RegExp> _amountRes = [
    RegExp(r'^\d{1,3}(?:,\d{3})+(?:\.\d{1,2})?$'), // 1,299 / 1,299.90
    RegExp(r'^\d{1,3}(?:,\d{2,3}){2,}(?:\.\d{1,2})?$'), // 1,29,900
    RegExp(r'^\d{1,3}(?:\.\d{3})+(?:,\d{1,2})?$'), // 1.299 / 1.299,90
    RegExp(r'^\d+,\d{1,2}$'), // 1299,90
    RegExp(r'^\d+\.\d{1,2}$'), // 1299.90
    RegExp(r'^\d+$'), // 1299
  ];

  /// Longest digit run that can still be money. Mirrors the guard the
  /// extraction pipeline applies in `_parseNumber`: longer runs are UTR /
  /// reference / card numbers, and past nine digits the parsed value is no
  /// longer exactly representable as a [double] anyway.
  static const int _maxAmountDigits = 9;

  static final RegExp _nonDigitRe = RegExp(r'\D');

  /// Checks if a string contains at least one uppercase letter.
  static bool hasUpperCase(String value) {
    return value.contains(RegExp(r'[A-Z]'));
  }

  /// Checks if a string contains at least one lowercase letter.
  static bool hasLowerCase(String value) {
    return value.contains(RegExp(r'[a-z]'));
  }

  /// Checks if a string contains at least one digit.
  static bool hasDigit(String value) {
    return value.contains(RegExp(r'[0-9]'));
  }

  /// Checks if a string contains at least one special character.
  static bool hasSpecialCharacter(String value) {
    return value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  }

  /// Checks if a string is a valid URL (optional http(s) scheme, domain,
  /// optional port/path/query). Trims surrounding whitespace.
  static bool isValidUrl(String value) {
    final v = value.trim();
    if (v.isEmpty || v.contains(RegExp(r'\s'))) return false;
    return _urlRe.hasMatch(v);
  }

  /// Validates an email address. Input is trimmed first; internal spaces,
  /// missing TLD, double dots and empty local/domain parts are rejected.
  static bool isValidEmail(String value) {
    final v = value.trim();
    if (v.isEmpty || v.length > 254) return false;
    final at = v.lastIndexOf('@');
    if (at <= 0) return false;
    if (v.indexOf('@') != at) return false; // more than one '@'
    final local = v.substring(0, at);
    final domain = v.substring(at + 1);
    if (local.isEmpty || local.length > 64) return false;
    if (domain.length > 253) return false;
    return _emailRe.hasMatch(v);
  }

  /// Validates a phone number: strict E.164 (`+919876543210`) or a 10-digit
  /// national fallback. `-`, `.` and whitespace are treated as cosmetic
  /// grouping, so `987-654-3210`, `98765 43210` (the usual Indian mobile
  /// grouping) and `+91 98765-43210` all pass; anything that is not digits
  /// after stripping them (`(415) 555-0123`) does not.
  static bool isValidPhone(String value) {
    final v = value.trim();
    if (v.isEmpty) return false;
    final closed = v.replaceAll(_phoneSeparatorRe, '');
    if (_e164Re.hasMatch(closed)) return true;
    return _tenDigitRe.hasMatch(closed);
  }

  /// True when [value] looks like a money amount the expense pipeline can
  /// parse: an optional ₹/$/€/£/Rs./INR/USD/EUR/GBP prefix or suffix plus one
  /// of the supported grouping/decimal formats.
  static bool isValidAmount(String value) => parseAmount(value) != null;

  /// Normalizes a supported amount string to a [double], or null when the
  /// string is not a valid amount. Indian (`1,29,900`) and Western
  /// (`1,299.90`) grouping both resolve by dropping the thousands separators
  /// (129900.0 and 1299.90); European (`1.299,90`) resolves to 1299.90.
  /// Digit runs longer than [_maxAmountDigits] are reference numbers, not
  /// money, and resolve to null.
  static double? parseAmount(String value) {
    var s = value.trim();
    if (s.isEmpty) return null;
    // A valid amount carries at most ONE currency token, prefix or suffix.
    final strippedPrefix = s.replaceFirst(_currencyPrefixRe, '');
    final hadPrefix = strippedPrefix != s;
    s = hadPrefix ? strippedPrefix : s.replaceFirst(_currencySuffixRe, '');
    s = s.trim();
    if (s.isEmpty ||
        s.startsWith('-') ||
        s.startsWith('(') ||
        s.contains(_leftoverCurrencyRe)) {
      return null;
    }
    if (!_amountRes.any((re) => re.hasMatch(s))) return null;
    if (s.replaceAll(_nonDigitRe, '').length > _maxAmountDigits) return null;

    double? out;
    if (RegExp(r'^\d{1,3}(?:\.\d{3})+(?:,\d{1,2})?$').hasMatch(s)) {
      // European: 1.299,90 -> 1299.90
      out = double.tryParse(s.replaceAll('.', '').replaceAll(',', '.'));
    } else if (RegExp(r'^\d+,\d{1,2}$').hasMatch(s)) {
      // Decimal comma without grouping: 1299,90 -> 1299.90
      out = double.tryParse(s.replaceAll(',', '.'));
    } else {
      // Strip group separators (commas) and parse the rest.
      out = double.tryParse(
        RegExp(r'^\d{1,3}(?:,\d{2,3})+(?:\.\d{1,2})?$').hasMatch(s)
            ? s.replaceAll(',', '')
            : s,
      );
    }
    return out;
  }

  /// Passphrase-strength checks kept for API compatibility: at least one
  /// uppercase, lowercase and digit, minimum [minLength] characters.
  static bool isStrongPassword(String value, {int minLength = 8}) {
    return value.length >= minLength &&
        hasUpperCase(value) &&
        hasLowerCase(value) &&
        hasDigit(value);
  }
}
