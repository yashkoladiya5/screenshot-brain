import 'package:intl/intl.dart';

/// Formats [value] using Indian digit grouping: the last three digits form
/// one group, then every two digits before it (e.g. `129900` -> `1,29,900`,
/// `100000000` -> `10,00,00,000`).
///
/// [decimals] fixed fractional digits are appended when greater than zero.
/// A negative value renders the minus sign before the currency symbol.
String formatIndianNumber(num value, {String symbol = '₹', int decimals = 0}) {
  assert(decimals >= 0 && decimals <= 15, 'decimals must be between 0 and 15');
  final negative = value < 0;
  final abs = value.abs();
  final String text;
  if (abs is int) {
    text = decimals > 0 ? '${abs.toString()}.${'0' * decimals}' : '$abs';
  } else {
    text = abs.toDouble().toStringAsFixed(decimals);
  }
  final dotIndex = text.indexOf('.');
  final integerPart = dotIndex == -1 ? text : text.substring(0, dotIndex);
  final fractionPart = dotIndex == -1 ? '' : text.substring(dotIndex + 1);
  final grouped = _groupIndianDigits(integerPart);
  final buffer = StringBuffer();
  if (negative) buffer.write('-');
  buffer.write(symbol);
  buffer.write(grouped);
  if (fractionPart.isNotEmpty) {
    buffer
      ..write('.')
      ..write(fractionPart);
  }
  return buffer.toString();
}

/// Groups a plain integer digit string (no sign) using the Indian system.
String _groupIndianDigits(String digits) {
  if (digits.length <= 3) return digits;
  final last3 = digits.substring(digits.length - 3);
  final rest = digits.substring(0, digits.length - 3);
  final parts = <String>[];
  for (var end = rest.length; end > 0; end -= 2) {
    parts.insert(0, rest.substring(end > 2 ? end - 2 : 0, end));
  }
  return '${parts.join(',')},$last3';
}

extension NumExtensions on num {
  /// Formats the number as currency (e.g., $1,234.56).
  String toCurrency([String symbol = '\$']) {
    final format = NumberFormat.currency(symbol: symbol, decimalDigits: 2);
    return format.format(this);
  }

  /// Formats the number as a compact string (e.g., 1.2k, 3M).
  String toCompact() {
    final format = NumberFormat.compact();
    return format.format(this);
  }

  /// Ensures the number is within the specified bounds.
  num clampTo(num min, num max) {
    if (this < min) return min;
    if (this > max) return max;
    return this;
  }

  /// Divides by [divisor], returning [orElse] (default `0`) instead of
  /// throwing/producing infinity when the divisor is zero.
  double safeDiv(num divisor, {double orElse = 0}) {
    if (divisor == 0) return orElse;
    return this / divisor;
  }

  /// Clamps into `[min, max]`, asserting that `min <= max`.
  ///
  /// Unlike [clampTo], misuse of bounds fails fast in debug builds.
  num coerceIn(num min, num max) {
    assert(min <= max, 'min ($min) must not exceed max ($max)');
    if (this < min) return min;
    if (this > max) return max;
    return this;
  }

  /// Rounds to [decimals] places (0..15).
  ///
  /// Delegates to `toStringAsFixed`, the same decimal rounding the Dart
  /// number formatter uses. The classic `(x * 10^n).round() / 10^n` trick
  /// drifts because the multiplication is lossy: `2.675` is stored just
  /// below the tie, so the naive trick wrongly yields `2.68` while
  /// `roundTo(2)` correctly yields `2.67`. Exact decimal ties follow
  /// `toStringAsFixed` (e.g. `0.145.roundTo(2) == 0.14`,
  /// `2.5.roundTo(0) == 3.0`).
  double roundTo(int decimals) {
    assert(
      decimals >= 0 && decimals <= 15,
      'decimals must be between 0 and 15',
    );
    return double.parse(toDouble().toStringAsFixed(decimals));
  }

  /// Linear interpolation towards [to] by factor [t] (typically 0..1,
  /// values outside that range overshoot on purpose, e.g. elastic easing).
  double lerp(num to, double t) => (this + (to - this) * t).toDouble();

  /// Inverse lerp: where does `this` sit inside `[rangeStart, rangeEnd]`.
  /// Returns 0 at [rangeStart], 1 at [rangeEnd]; may go outside [0, 1].
  double inverseLerp(num rangeStart, num rangeEnd) {
    assert(rangeStart != rangeEnd, 'inverseLerp requires a non-empty range');
    return ((this - rangeStart) / (rangeEnd - rangeStart)).toDouble();
  }

  /// Maps from the input range `[inMin, inMax]` into `[outMin, outMax]`.
  double remap(num inMin, num inMax, num outMin, num outMax) =>
      (outMin + (outMax - outMin) * inverseLerp(inMin, inMax)).toDouble();

  /// This value as a percentage of [total]; [orElse] (default `0`) when
  /// [total] is zero. Example: `30.percentOf(120)` -> `25.0`.
  double percentOf(num total, {double orElse = 0}) {
    if (total == 0) return orElse;
    return (this / total * 100).toDouble();
  }

  /// Formats using Indian digit grouping with a currency symbol.
  ///
  /// Example: `(129900).toIndianRupees()` -> `'₹1,29,900'`.
  String toIndianRupees({String symbol = '₹', int decimals = 0}) =>
      formatIndianNumber(this, symbol: symbol, decimals: decimals);
}
