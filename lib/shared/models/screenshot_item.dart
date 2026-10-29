import '../../core/utils/date_extensions.dart';
import '../../core/utils/file_extensions.dart';
import 'screenshot_model.dart';

/// Lifecycle state of a persisted screenshot, derived from the raw boolean
/// flags stored on [ScreenshotModel].
enum ScreenshotStatus {
  /// Row exists but OCR/text extraction has not completed.
  pending,

  /// Text extracted and categorized; not recognised as an expense.
  processed,

  /// Text extracted and the screenshot was classified as an expense.
  expense;

  /// Human label for chips / list subtitles.
  String get label {
    switch (this) {
      case ScreenshotStatus.pending:
        return 'Pending';
      case ScreenshotStatus.processed:
        return 'Processed';
      case ScreenshotStatus.expense:
        return 'Expense';
    }
  }

  bool get isPending => this == ScreenshotStatus.pending;

  /// Whether OCR still has to run for this row.
  bool get needsProcessing => this == ScreenshotStatus.pending;

  bool get isExpense => this == ScreenshotStatus.expense;
}

/// Immutable, UI-facing view model for a screenshot row.
///
/// Built from a persisted [ScreenshotModel] via [ScreenshotItem.fromModel];
/// safe to construct directly in widget tests and previews. Formatting is
/// delegated to the app's shared extensions ([DateTimeExtensions],
/// [FileSizeExtensions], [ScreenshotPathExtensions]) instead of hand-rolled
/// `DateFormat` patterns sprinkled through the UI.
class ScreenshotItem {
  final int id;
  final String filePath;
  final String? thumbnailPath;
  final String? extractedText;
  final String? category;
  final DateTime createdAt;
  final int? fileSize;
  final int? width;
  final int? height;
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
    this.width,
    this.height,
    this.isProcessed = false,
    this.isExpense = false,
  });

  /// Projects a persisted [ScreenshotModel] onto the view model.
  ///
  /// `filePath` and `createdAt` are `late` on the model; callers that build
  /// models without setting them get a defensive default instead of a
  /// `LateInitializationError` leaking into the UI layer.
  factory ScreenshotItem.fromModel(ScreenshotModel model) {
    return ScreenshotItem(
      id: model.id,
      filePath: _safe(() => model.filePath) ?? '',
      thumbnailPath: model.thumbnailPath,
      extractedText: model.extractedText,
      category: model.category,
      createdAt:
          _safe(() => model.createdAt) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      fileSize: model.fileSize,
      width: model.width,
      height: model.height,
      isProcessed: model.isProcessed,
      isExpense: model.isExpense,
    );
  }

  /// Reads a possibly-uninitialized `late` field without letting a
  /// `LateInitializationError` escape into the UI layer.
  static T? _safe<T>(T Function() read) {
    try {
      return read();
    } on Error {
      return null;
    }
  }

  /// Derived processing state.
  ScreenshotStatus get status {
    if (isExpense) return ScreenshotStatus.expense;
    if (isProcessed) return ScreenshotStatus.processed;
    return ScreenshotStatus.pending;
  }

  String get statusLabel => status.label;

  /// Category, or a placeholder when the screenshot was never categorized.
  ///
  /// Whitespace-only values fall back to the placeholder and padded values
  /// are trimmed, matching `ExpenseItem.categoryDisplay` and the
  /// `AnalyticsService` bucketing so the same value never renders blank in
  /// one place and 'Uncategorized' in another.
  String get categoryDisplay {
    final trimmed = (category ?? '').trim();
    return trimmed.isEmpty ? 'Uncategorized' : trimmed;
  }

  /// Lower-cased extension of [filePath] ('' when there is none).
  String get fileExtension => filePath.fileExtension;

  /// Whether the stored file carries an extension the importer accepts.
  bool get isSupportedImage => filePath.isAllowedImageExtension;

  /// Base name of [filePath], stripped of any directory separators.
  String get fileName {
    final normalized = filePath.replaceAll(r'\', '/');
    final base = normalized.substring(normalized.lastIndexOf('/') + 1);
    return base.isEmpty ? filePath : base;
  }

  /// '1.2 MB' style size, or a placeholder when the stat was never recorded.
  ///
  /// Zero/negative sizes render as '0 B' (the shared formatter's own
  /// behaviour) rather than crashing the row.
  String get fileSizeDisplay {
    final size = fileSize;
    if (size == null) return 'Unknown size';
    return size.toReadableFileSize();
  }

  /// Pixel dimensions ('1080×2400'), or '—' when unmeasured/nonsensical.
  String get dimensionsDisplay {
    final w = width;
    final h = height;
    if (w == null || h == null || w <= 0 || h <= 0) return '—';
    return '$w×$h';
  }

  /// Relative capture time including the clock ('Today at 4:30 PM').
  String get dateDisplay => createdAt.toRelativeString();

  /// Same as [dateDisplay] pinned to [reference] (for deterministic tests
  /// and "as of" exports).
  String dateDisplayAgainst(DateTime reference) =>
      createdAt.toRelativeString(reference: reference);

  /// Plain 'Oct 24, 2023' rendering for tables and accessibility labels.
  String get standardDateDisplay => createdAt.toStandardFormat();

  /// Single-line preview of the OCR text, whitespace-collapsed.
  /// Returns null when there is nothing meaningful to show.
  String? get textPreview {
    final collapsed = (extractedText ?? '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (collapsed.isEmpty) return null;
    if (collapsed.length <= 80) return collapsed;
    // Back off one code unit when the cut lands on the high half of a
    // surrogate pair — OCR text from chats and receipts is emoji-heavy, and a
    // dangling low surrogate renders as '?' at the end of the preview.
    var cut = 80;
    if ((collapsed.codeUnitAt(cut - 1) & 0xFC00) == 0xD800) cut -= 1;
    return '${collapsed.substring(0, cut)}…';
  }

  /// True when OCR produced any non-whitespace text.
  bool get hasExtractedText =>
      (extractedText ?? '').replaceAll(RegExp(r'\s+'), '').isNotEmpty;

  ScreenshotItem copyWith({
    int? id,
    String? filePath,
    String? thumbnailPath,
    String? extractedText,
    String? category,
    DateTime? createdAt,
    int? fileSize,
    int? width,
    int? height,
    bool? isProcessed,
    bool? isExpense,
  }) {
    return ScreenshotItem(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      extractedText: extractedText ?? this.extractedText,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      fileSize: fileSize ?? this.fileSize,
      width: width ?? this.width,
      height: height ?? this.height,
      isProcessed: isProcessed ?? this.isProcessed,
      isExpense: isExpense ?? this.isExpense,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScreenshotItem &&
        other.id == id &&
        other.filePath == filePath &&
        other.thumbnailPath == thumbnailPath &&
        other.extractedText == extractedText &&
        other.category == category &&
        other.createdAt == createdAt &&
        other.fileSize == fileSize &&
        other.width == width &&
        other.height == height &&
        other.isProcessed == isProcessed &&
        other.isExpense == isExpense;
  }

  @override
  int get hashCode => Object.hash(
    id,
    filePath,
    thumbnailPath,
    extractedText,
    category,
    createdAt,
    fileSize,
    width,
    height,
    isProcessed,
    isExpense,
  );

  @override
  String toString() =>
      'ScreenshotItem(id: $id, filePath: $filePath, category: $category, '
      'createdAt: $createdAt, status: ${status.name})';
}
