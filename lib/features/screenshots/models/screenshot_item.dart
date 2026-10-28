import '../../../core/utils/date_extensions.dart';

class ScreenshotItem {
  final int id;
  final String filePath;
  final String? thumbnailPath;
  final String? extractedText;
  final String? category;
  final DateTime createdAt;
  final int? fileSize;
  final bool isProcessed;
  final bool isExpense;

  const ScreenshotItem({
    required this.id,
    required this.filePath,
    this.thumbnailPath,
    this.extractedText,
    this.category,
    required this.createdAt,
    this.fileSize,
    this.isProcessed = false,
    this.isExpense = false,
  });

  /// Category, or the placeholder when never categorized.
  ///
  /// Trims first: a whitespace-only value used to render an empty badge here
  /// while the analytics dashboard bucketed the same row as 'Uncategorized'.
  String get categoryDisplay {
    final trimmed = (category ?? '').trim();
    return trimmed.isEmpty ? 'Uncategorized' : trimmed;
  }

  /// Whole calendar days before now, as 'Today' / 'Yesterday' / 'N days ago',
  /// falling back to the numeric date past a week.
  ///
  /// Deliberately not `now.difference(createdAt).inDays`: that counts elapsed
  /// 24-hour blocks, so a screenshot captured at 23:00 yesterday read as
  /// 'Today' for most of today, and a six-day-old capture flipped to the
  /// numeric date a day early. `dayOffsetFrom` from the shared date
  /// extensions is midnight-normalized and DST-safe.
  String get dateDisplay {
    final daysAgo = -createdAt.dayOffsetFrom(DateTime.now());
    if (daysAgo <= 0) return 'Today';
    if (daysAgo == 1) return 'Yesterday';
    if (daysAgo < 7) return '$daysAgo days ago';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}
