import 'package:intl/intl.dart';

extension DateExtensions on DateTime {
  /// Formats the date to a standardized string (e.g., "Oct 24, 2023").
  String toStandardFormat() {
    return DateFormat('MMM d, yyyy').format(this);
  }

  /// Formats the date to a compact numerical string (e.g., "10/24/2023").
  String toCompactFormat() {
    return DateFormat('MM/dd/yyyy').format(this);
  }

  /// Returns true if this date is today.
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Returns true if this date is tomorrow.
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year && month == tomorrow.month && day == tomorrow.day;
  }

  /// Returns true if this date is yesterday.
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }

  /// Returns a human-readable relative time string (e.g., "Today", "Yesterday", or "Oct 24, 2023").
  String toRelativeString() {
    if (isToday) return 'Today';
    if (isYesterday) return 'Yesterday';
    if (isTomorrow) return 'Tomorrow';
    return toStandardFormat();
  }
}
