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

  String get categoryDisplay => category ?? 'Uncategorized';
  String get dateDisplay {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}
