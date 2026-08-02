import 'package:intl/intl.dart';

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
}
