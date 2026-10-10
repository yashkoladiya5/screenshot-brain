import 'package:intl/intl.dart';

/// Calendar helpers for month/week bucketing in the screenshot timeline.
///
/// All "day" arithmetic is calendar-based and time-of-day independent:
/// comparisons normalize to midnight components, so a 23:59 timestamp and a
/// 00:01 timestamp on the same date are treated as the same day.
class DateUtils {
  DateUtils._();

  /// Returns a friendly time ago string, e.g., "5 mins ago", "Just now"
  static String timeAgo(DateTime date) {
    final Duration diff = DateTime.now().difference(date);

    if (diff.inDays > 365) {
      return '${(diff.inDays / 365).floor()} years ago';
    }
    if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()} months ago';
    }
    if (diff.inDays > 0) {
      return '${diff.inDays} days ago';
    }
    if (diff.inHours > 0) {
      return '${diff.inHours} hours ago';
    }
    if (diff.inMinutes > 0) {
      return '${diff.inMinutes} mins ago';
    }
    return 'Just now';
  }

  /// Checks if two dates fall on the same calendar day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Checks if two dates fall in the same calendar month and year.
  static bool isSameMonth(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month;
  }

  /// Start of the ISO week (Monday 00:00:00.000) containing [date].
  /// Locale-agnostic: Dart's `weekday` is 1=Monday..7=Sunday regardless of
  /// locale, so weeks always start on Monday.
  static DateTime startOfWeek(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: date.weekday - DateTime.monday));
  }

  /// End of the ISO week (Sunday 23:59:59.999) containing [date].
  static DateTime endOfWeek(DateTime date) {
    final start = startOfWeek(date);
    final sunday = start.add(const Duration(days: 6));
    return DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59, 999);
  }

  /// Stable bucket key for a month, e.g. `2025-01`. Zero-padded, sortable as
  /// a plain string.
  static String monthKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}';
  }

  /// Human month label for a date, e.g. `January 2025`.
  static String monthLabel(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  /// Human month label from a [monthKey] string (`2025-01` -> `January 2025`).
  /// Returns [key] unchanged when it does not parse.
  static String monthLabelForKey(String key) {
    final parts = key.split('-');
    if (parts.length != 2) return key;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null || month < 1 || month > 12) return key;
    return DateFormat('MMMM yyyy').format(DateTime(year, month));
  }

  /// Whole calendar days between two dates, ignoring time-of-day.
  /// Negative when [from] is after [to]; DST-safe because the difference is
  /// computed on UTC-anchored midnight values, not local wall clocks.
  static int daysBetween(DateTime from, DateTime to) {
    final a = DateTime.utc(from.year, from.month, from.day);
    final b = DateTime.utc(to.year, to.month, to.day);
    return b.difference(a).inDays;
  }

  /// Number of days in [month] (1-12) of [year], honoring leap years.
  /// Month 12 is handled naturally: `DateTime(year, 13)` rolls to Jan of the
  /// next year, so "day 0 of next month" is always this month's last day.
  static int daysInMonth(int year, int month) {
    return DateTime(year, month + 1).subtract(const Duration(days: 1)).day;
  }

  /// Clamps [date]'s day to the last valid day of its own month.
  /// `2025-02-31` inputs (constructed via overflow) land on `2025-02-28`;
  /// already-valid dates pass through with time preserved.
  static DateTime clampToMonthEnd(DateTime date) {
    final max = daysInMonth(date.year, date.month);
    if (date.day <= max) return date;
    return DateTime(
      date.year,
      date.month,
      max,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }

  /// Adds [months] calendar months, clamping the day to the end of the
  /// target month: Jan 31 + 1 month -> Feb 28 (Feb 29 in leap years).
  static DateTime addMonths(DateTime date, int months) {
    final zeroBased = date.month - 1 + months;
    final year = date.year + zeroBased ~/ 12;
    final month = zeroBased % 12 + 1;
    final maxDay = daysInMonth(year, month);
    final day = date.day > maxDay ? maxDay : date.day;
    return DateTime(
      year,
      month,
      day,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }

  /// Subtracts [months] calendar months with end-of-month clamping.
  static DateTime subtractMonths(DateTime date, int months) =>
      addMonths(date, -months);
}
