/// Record of a duration split into non-negative h/m/s components.
typedef HoursMinutesSeconds = ({int hours, int minutes, int seconds});

extension DurationExtensions on Duration {
  /// Formats the duration into a readable `mm:ss` string (e.g., 04:05).
  String toMmSs() {
    final minutes = inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Formats the duration into a readable `hh:mm:ss` string.
  String toHhMmSs() {
    final hours = inHours.toString().padLeft(2, '0');
    final minutes = inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  /// Compact spoken-style duration: `1h 5m`, `45m`, `9s`, `2d 3h`.
  /// Zero-valued units are omitted; the zero duration renders as `0s`.
  /// Negative durations are formatted from their absolute value.
  String formatDurationShort() {
    final total = inSeconds.abs();
    if (total == 0) return '0s';
    final days = total ~/ 86400;
    final hours = (total % 86400) ~/ 3600;
    final minutes = (total % 3600) ~/ 60;
    final seconds = total % 60;
    final parts = <String>[];
    if (days > 0) parts.add('${days}d');
    if (hours > 0) parts.add('${hours}h');
    if (minutes > 0) parts.add('${minutes}m');
    if (seconds > 0 || parts.isEmpty) parts.add('${seconds}s');
    return parts.join(' ');
  }

  /// Duration split into `hours`/`minutes`/`seconds` (each < 60 for the
  /// smaller units). Values are derived from `inSeconds.abs()`, so a 90-minute
  /// duration reports 1 hour, not 1 remainder-minute.
  HoursMinutesSeconds get asHoursMinutesSeconds {
    final total = inSeconds.abs();
    return (
      hours: total ~/ 3600,
      minutes: (total % 3600) ~/ 60,
      seconds: total % 60,
    );
  }

  /// Constrains this duration to the inclusive range [lower]..[upper].
  /// Assumes [lower] <= [upper]; swaps defensively otherwise.
  Duration clamp(Duration lower, Duration upper) {
    final lo = lower <= upper ? lower : upper;
    final hi = lower <= upper ? upper : lower;
    if (this < lo) return lo;
    if (this > hi) return hi;
    return this;
  }
}
