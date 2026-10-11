import 'package:intl/intl.dart';

import '../../core/utils/date_extensions.dart';
import 'expense_model.dart';

/// Locale the app renders money in: Indian (lakh/crore) digit grouping with a
/// ₹ symbol, e.g. `₹1,29,900.00`.
const String kExpenseCurrencyLocale = 'en_IN';

/// Symbol prepended to every money figure in the expense UI.
const String kExpenseCurrencySymbol = '₹';

/// `₹1,29,900.00` — the `en_IN` currency pattern (`¤#,##,##0.00`) carries the
/// secondary grouping size, so lakh/crore separators come from intl rather
/// than from a hand-splitting regex.
final NumberFormat _rupeeFormat = NumberFormat.currency(
  locale: kExpenseCurrencyLocale,
  symbol: kExpenseCurrencySymbol,
  decimalDigits: 2,
);

/// Whole-rupee totals for dashboard tiles: `₹7,250`.
final NumberFormat _rupeeWholeFormat = NumberFormat.currency(
  locale: kExpenseCurrencyLocale,
  symbol: kExpenseCurrencySymbol,
  decimalDigits: 0,
);

/// Short form for tight spaces: `₹1.5L`.
final NumberFormat _rupeeCompactFormat = NumberFormat.compactCurrency(
  locale: kExpenseCurrencyLocale,
  symbol: kExpenseCurrencySymbol,
  decimalDigits: 1,
);

/// How completely the expense was parsed out of the screenshot text.
enum ExpenseStatus {
  /// Nothing usable was extracted (no amount and no merchant).
  unparsed,

  /// An amount was found but the merchant is unknown.
  amountOnly,

  /// Merchant was found but no amount could be parsed.
  merchantOnly,

  /// Amount and merchant both present — safe to show as a real expense.
  complete;

  /// Human label for chips / list subtitles.
  String get label {
    switch (this) {
      case ExpenseStatus.unparsed:
        return 'Unparsed';
      case ExpenseStatus.amountOnly:
        return 'Amount only';
      case ExpenseStatus.merchantOnly:
        return 'Merchant only';
      case ExpenseStatus.complete:
        return 'Complete';
    }
  }

  /// False when the row carries no usable spend data.
  bool get hasUsableData => this != ExpenseStatus.unparsed;
}

/// Immutable, UI-facing view model for an extracted expense.
///
/// Built from a persisted [ExpenseModel] via [ExpenseItem.fromModel]; money
/// goes through the shared intl `en_IN`/₹ formats declared above and dates
/// through [DateTimeExtensions], so the dashboard and the list rows can never
/// disagree about grouping or precision.
class ExpenseItem {
  final int id;
  final int screenshotId;
  final double? amount;
  final String? merchant;
  final DateTime? expenseDate;
  final String? category;
  final String? description;
  final DateTime createdAt;

  const ExpenseItem({
    required this.id,
    required this.screenshotId,
    this.amount,
    this.merchant,
    this.expenseDate,
    this.category,
    this.description,
    required this.createdAt,
  });

  /// Projects a persisted [ExpenseModel] onto the view model, tolerating the
  /// model's `late` fields when the extractor never filled them in.
  factory ExpenseItem.fromModel(ExpenseModel model) {
    return ExpenseItem(
      id: model.id,
      screenshotId: _safe(() => model.screenshotId) ?? 0,
      amount: model.amount,
      merchant: model.merchant,
      expenseDate: model.expenseDate,
      category: model.category,
      description: model.description,
      createdAt:
          _safe(() => model.createdAt) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static T? _safe<T>(T Function() read) {
    try {
      return read();
    } on Error {
      return null;
    }
  }

  bool get hasAmount => amount != null;
  bool get hasMerchant => (merchant ?? '').trim().isNotEmpty;

  /// Parsing completeness derived from the raw nullable fields.
  ExpenseStatus get status {
    if (hasAmount && hasMerchant) return ExpenseStatus.complete;
    if (hasAmount) return ExpenseStatus.amountOnly;
    if (hasMerchant) return ExpenseStatus.merchantOnly;
    return ExpenseStatus.unparsed;
  }

  String get statusLabel => status.label;

  /// `₹1,29,900.00` with Indian grouping; 'N/A' when nothing was parsed.
  ///
  /// Zero renders as `₹0.00` and negatives with the locale's minus prefix
  /// (`-₹1,234.50`), never as an empty string.
  String get amountDisplay {
    final value = amount;
    if (value == null) return 'N/A';
    return _rupeeFormat.format(value);
  }

  /// Short form for tight spaces (dashboard tiles), e.g. `₹1.5L`.
  String get amountDisplayCompact {
    final value = amount;
    if (value == null) return 'N/A';
    return _rupeeCompactFormat.format(value);
  }

  /// Rupee amount rounded to whole rupees (no decimals), for totals.
  String get amountDisplayWhole {
    final value = amount;
    if (value == null) return 'N/A';
    return _rupeeWholeFormat.format(value);
  }

  /// Merchant name or a placeholder when the extractor could not find one.
  String get merchantDisplay =>
      hasMerchant ? merchant!.trim() : 'Unknown merchant';

  /// Spend category, or 'Uncategorized' when the row predates categorization.
  String get categoryDisplay =>
      (category == null || category!.isEmpty) ? 'Uncategorized' : category!;

  /// Free-text note, or an empty string when absent (never null, so callers
  /// can render it without a null check).
  String get descriptionDisplay {
    final text = (description ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.length <= 100) return text;
    return '${text.substring(0, 100)}…';
  }

  /// '24 Oct 2023' for the purchase date; 'N/A' when the date was not parsed.
  String get dateDisplay {
    final date = expenseDate;
    if (date == null) return 'N/A';
    return date.formatted;
  }

  /// 'Oct 24, 2023' variant used in titles and accessibility labels.
  String get standardDateDisplay {
    final date = expenseDate;
    if (date == null) return 'N/A';
    return date.toStandardFormat();
  }

  /// Month header label ('Oct 2023'); empty when there is no purchase date.
  String get monthLabel {
    final date = expenseDate;
    if (date == null) return '';
    return date.monthYear;
  }

  /// When the row was extracted, relative to now ('Today at 4:30 PM').
  String get createdDisplay => createdAt.toRelativeString();

  /// [createdDisplay] pinned to [reference] for deterministic rendering.
  String createdDisplayAgainst(DateTime reference) =>
      createdAt.toRelativeString(reference: reference);

  ExpenseItem copyWith({
    int? id,
    int? screenshotId,
    double? amount,
    String? merchant,
    DateTime? expenseDate,
    String? category,
    String? description,
    DateTime? createdAt,
  }) {
    return ExpenseItem(
      id: id ?? this.id,
      screenshotId: screenshotId ?? this.screenshotId,
      amount: amount ?? this.amount,
      merchant: merchant ?? this.merchant,
      expenseDate: expenseDate ?? this.expenseDate,
      category: category ?? this.category,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExpenseItem &&
        other.id == id &&
        other.screenshotId == screenshotId &&
        other.amount == amount &&
        other.merchant == merchant &&
        other.expenseDate == expenseDate &&
        other.category == category &&
        other.description == description &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    screenshotId,
    amount,
    merchant,
    expenseDate,
    category,
    description,
    createdAt,
  );

  @override
  String toString() =>
      'ExpenseItem(id: $id, screenshotId: $screenshotId, amount: $amount, '
      'merchant: $merchant, expenseDate: $expenseDate, status: ${status.name})';
}
