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
}
