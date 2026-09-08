import 'package:intl/intl.dart';

extension DateTimeExtensions on DateTime {
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

  /// Formats the date to a standardized string (e.g., "Oct 24, 2023").
  String toStandardFormat() {
    return DateFormat('MMM d, yyyy').format(this);
  }

  /// Formats the date to a compact numerical string (e.g., "10/24/2023").
  String toCompactFormat() {
    return DateFormat('MM/dd/yyyy').format(this);
  }

  /// Formats the time to a simple string like '4:30 PM'.
  String toTimeString() {
    return DateFormat('h:mm a').format(this);
  }

  /// Returns a human-readable relative string (e.g. 'Today at 4:30 PM',
  /// 'Yesterday at 9:00 AM', or 'Oct 24, 2023').
  String toRelativeString() {
    if (isToday) {
      return 'Today at ${toTimeString()}';
    } else if (isYesterday) {
      return 'Yesterday at ${toTimeString()}';
    } else if (isTomorrow) {
      return 'Tomorrow at ${toTimeString()}';
    }
    return toStandardFormat();
  }
}