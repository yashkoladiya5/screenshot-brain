import 'package:intl/intl.dart';

/// The single canonical set of `DateTime` formatting/predicate helpers.
///
/// History: an in-flight edit renamed this extension and left a near-duplicate
/// `date_time_extensions.dart` scratch file behind. Both member surfaces are
/// merged here and that duplicate is gone, so no library in the app ever sees
/// two competing extensions on `DateTime` (which would make every
/// `someDate.toRelativeString()` call ambiguous).
///
/// Reference-time aware members ([toRelativeString], [isSameDayAs] and the
/// `*On` predicates) accept an explicit `reference` so callers and tests can
/// pin "now" instead of depending on the wall clock.
extension DateTimeExtensions on DateTime {
  /// Formats the date to a standardized string (e.g., "Oct 24, 2023").
  String toStandardFormat() => DateFormat('MMM d, yyyy').format(this);

  /// Same as [toStandardFormat] under the shorter name used by older call
  /// sites (kept so both spellings resolve to one implementation).
  String toShortDateString() => toStandardFormat();

  /// Formats the date to a compact numerical string (e.g., "10/24/2023").
  String toCompactFormat() => DateFormat('MM/dd/yyyy').format(this);

  /// Formats the date as day-month-year with a two-digit day
  /// (e.g., "24 Oct 2023").
  String get formatted => DateFormat('dd MMM yyyy').format(this);

  /// Date plus 24-hour time (e.g., "24 Oct 2023 16:30").
  String get formattedWithTime => DateFormat('dd MMM yyyy HH:mm').format(this);

  /// Month-and-year label (e.g., "Oct 2023"), used for section headers.
  String get monthYear => DateFormat('MMM yyyy').format(this);

  /// Formats only the clock part as 'h:mm a' (e.g., '4:30 PM').
  String toTimeString() => DateFormat('h:mm a').format(this);

  /// True when this date falls on the same calendar day as [other].
  ///
  /// Compares year/month/day fields only, so the time of day is irrelevant
  /// and mixed local/UTC operands on the same calendar day still match.
  bool isSameDayAs(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  /// Returns true if this date is today.
  bool get isToday => isSameDayAs(DateTime.now());

  /// Returns true if this date is tomorrow.
  bool get isTomorrow => dayOffsetFrom(DateTime.now()) == 1;

  /// Returns true if this date is yesterday.
  bool get isYesterday => dayOffsetFrom(DateTime.now()) == -1;

  /// True when this date is the same calendar day as [reference].
  bool isTodayOn(DateTime reference) => isSameDayAs(reference);

  /// True when this date is the calendar day before [reference].
  bool isYesterdayOn(DateTime reference) => dayOffsetFrom(reference) == -1;

  /// True when this date is the calendar day after [reference].
  bool isTomorrowOn(DateTime reference) => dayOffsetFrom(reference) == 1;

  /// Whole calendar days between this date and [reference] (negative when
  /// this date is in the past). Midnight-normalized, so wall-clock time and
  /// DST transitions never shift the result.
  /// DST-safe: the midnight difference is taken on UTC-anchored values so
  /// every day is exactly 24 hours. Subtracting local midnights instead
  /// yields 23-/25-hour spans on DST days, and `Duration.inDays` truncates
  /// toward zero, so "23 hours" collapsed to 0 and yesterday was labeled
  /// "Today" (and a tomorrow became a "Today") in DST-observing zones.
  int dayOffsetFrom(DateTime reference) {
    final self = DateTime.utc(year, month, day);
    final base = DateTime.utc(reference.year, reference.month, reference.day);
    return self.difference(base).inDays;
  }

  /// Returns a human-readable relative string including the time
  /// (e.g. 'Today at 4:30 PM', 'Yesterday at 9:00 AM', 'Tomorrow at 8:00 PM',
  /// or 'Oct 24, 2023' for anything further away).
  ///
  /// Pass [reference] to evaluate "today"/"yesterday" against a pinned clock
  /// instead of [DateTime.now].
  String toRelativeString({DateTime? reference}) {
    final now = reference ?? DateTime.now();
    if (isTodayOn(now)) return 'Today at ${toTimeString()}';
    if (isYesterdayOn(now)) return 'Yesterday at ${toTimeString()}';
    if (isTomorrowOn(now)) return 'Tomorrow at ${toTimeString()}';
    return toStandardFormat();
  }

  /// Relative date without the clock part ('Today', 'Yesterday', 'Tomorrow',
  /// otherwise the [toStandardFormat] rendering).
  String toRelativeDateString({DateTime? reference}) {
    final now = reference ?? DateTime.now();
    final offset = dayOffsetFrom(now);
    if (offset == 0) return 'Today';
    if (offset == -1) return 'Yesterday';
    if (offset == 1) return 'Tomorrow';
    return toStandardFormat();
  }
}
