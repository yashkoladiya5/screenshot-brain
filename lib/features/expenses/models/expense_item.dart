import 'package:intl/intl.dart';

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
    return '₹${NumberFormat('#,##0.00').format(amount)}';
  }

  String get dateDisplay {
    if (expenseDate == null) return 'N/A';
    return DateFormat('dd MMM yyyy').format(expenseDate!);
  }

  String get monthLabel {
    if (expenseDate == null) return '';
    return DateFormat('MMM yyyy').format(expenseDate!);
  }
}
