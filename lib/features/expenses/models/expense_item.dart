import 'package:intl/intl.dart';

import '../../../core/utils/date_extensions.dart';
import '../../../shared/models/expense_item.dart'
    show kExpenseCurrencyLocale, kExpenseCurrencySymbol;

/// Money is displayed in the app's declared currency presentation
/// (`en_IN` lakh/crore grouping with a ₹ symbol, the standard owned by
/// shared/models/expense_item.dart). Without an explicit locale Intl falls
/// back to the device locale, so the same ₹129900 expense rendered as
/// '₹129.900,00' on a German device — and comma-grouped even on en_US ones —
/// while the shared model and validators only ever speak '₹1,29,900.00'.
final NumberFormat _rupeeFormat = NumberFormat.currency(
  locale: kExpenseCurrencyLocale,
  symbol: kExpenseCurrencySymbol,
  decimalDigits: 2,
);

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

  String get amountDisplay {
    if (amount == null) return 'N/A';
    return _rupeeFormat.format(amount);
  }

  /// Merchant name, trimmed; 'Unknown' for null AND blank values — rows
  /// written by the extractor can carry `merchant: ''`, which `?? 'Unknown'`
  /// at the call site rendered as an empty title. Mirrors
  /// `AnalyticsService.unknownMerchantLabel`.
  String get merchantDisplay {
    final trimmed = (merchant ?? '').trim();
    return trimmed.isEmpty ? 'Unknown' : trimmed;
  }

  /// Spend label, trimmed; blank or whitespace-only categories fold into
  /// 'Other' so the row chip agrees with the `ExpenseSnapshot.byCategory`
  /// bucket the same expense is counted under on the same screen.
  String get categoryDisplay {
    final trimmed = (category ?? '').trim();
    return trimmed.isEmpty ? 'Other' : trimmed;
  }

  String get dateDisplay {
    final date = expenseDate;
    if (date == null) return 'N/A';
    // Shared extension pins the month names to the app label locale; the
    // locale-less `DateFormat('dd MMM yyyy')` translated them per device.
    return date.formatted;
  }

  String get monthLabel {
    final date = expenseDate;
    if (date == null) return '';
    return date.monthYear;
  }
}
