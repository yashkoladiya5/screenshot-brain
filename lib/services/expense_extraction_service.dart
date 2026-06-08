import '../shared/models/expense_model.dart';

class ExpenseExtractionService {
  static double? extractAmount(String text) {
    final amountPatterns = [
      RegExp(r'(?:Rs\.?|INR|₹)\s*(\d+(?:,\d{3})*(?:\.\d{1,2})?)'),
      RegExp(r'(\d+(?:,\d{3})*(?:\.\d{1,2})?)\s*(?:Rs\.?|INR|₹)'),
      RegExp(r'(?:total|amount|paid)\s*[:\-]?\s*(?:Rs\.?|INR|₹)?\s*(\d+(?:\.\d{1,2})?)', caseSensitive: false),
      RegExp(r'\$\s*(\d+(?:\.\d{1,2})?)'),
      RegExp(r'(\d+(?:\.\d{1,2})?)\s*USD'),
    ];
    for (final pattern in amountPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final amountStr = match.group(1)!.replaceAll(',', '');
        final amount = double.tryParse(amountStr);
        if (amount != null && amount > 0) return amount;
      }
    }
    return null;
  }

  static String? extractMerchant(String text) {
    final merchantPatterns = [
      RegExp(r'(?:paid to|sent to|transfer to|payment to|merchant|vendor|store)\s*[:\-]?\s*(.+?)(?:\n|\.|,|$)', caseSensitive: false),
      RegExp(r'(?:from|via)\s+([A-Z][A-Za-z\s]+?)(?:\s+(?:on|at|for|\n|\.|,|$))', caseSensitive: false),
    ];
    for (final pattern in merchantPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final merchant = match.group(1)?.trim();
        if (merchant != null && merchant.isNotEmpty && merchant.length < 50) return merchant;
      }
    }
    return null;
  }

  static DateTime? extractDate(String text) {
    final datePatterns = [
      RegExp(r'(\d{1,2}[/\-]\d{1,2}[/\-]\d{2,4})'),
      RegExp(r'(\d{1,2}\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dev)[a-z]*\s+\d{2,4})', caseSensitive: false),
      RegExp(r'((?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dev)[a-z]*\s+\d{1,2},?\s+\d{2,4})', caseSensitive: false),
    ];
    for (final pattern in datePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final dateStr = match.group(1)!;
        final parsed = DateTime.tryParse(dateStr);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  static ExpenseModel extractExpense(String text, int screenshotId) {
    final expense = ExpenseModel();
    expense.screenshotId = screenshotId;
    expense.amount = extractAmount(text);
    expense.merchant = extractMerchant(text);
    expense.expenseDate = extractDate(text) ?? DateTime.now();
    expense.category = _determineExpenseCategory(text);
    expense.description = text.length > 200 ? '${text.substring(0, 200)}...' : text;
    expense.createdAt = DateTime.now();
    return expense;
  }

  static String _determineExpenseCategory(String text) {
    final lower = text.toLowerCase();
    if (RegExp(r'grocery|food|restaurant|zomato|swiggy', caseSensitive: false).hasMatch(lower)) return 'Food';
    if (RegExp(r'travel|flight|train|bus|cab|uber|ola|hotel', caseSensitive: false).hasMatch(lower)) return 'Travel';
    if (RegExp(r'shopping|amazon|flipkart|myntra|cloth', caseSensitive: false).hasMatch(lower)) return 'Shopping';
    if (RegExp(r'bill|electricity|water|gas|mobile|recharge|broadband', caseSensitive: false).hasMatch(lower)) return 'Bills';
    if (RegExp(r'medicin|hospital|doctor|health|pharmacy', caseSensitive: false).hasMatch(lower)) return 'Healthcare';
    if (RegExp(r'entertainment|movie|netflix|spotify|game', caseSensitive: false).hasMatch(lower)) return 'Entertainment';
    return 'Other';
  }
}
