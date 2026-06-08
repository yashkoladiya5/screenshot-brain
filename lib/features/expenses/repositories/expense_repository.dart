import 'package:isar/isar.dart';
import '../../../services/database_service.dart';
import '../../../shared/models/expense_model.dart';
import '../models/expense_item.dart';

class ExpenseRepository {
  final Isar db = DatabaseService.db;

  Future<List<ExpenseItem>> getAllExpenses() async {
    final models = await db.expenseModels.where().findAll();
    return models.map(_toItem).toList();
  }

  Future<List<ExpenseItem>> getExpensesByMonth(DateTime month) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    final models = await db.expenseModels
        .filter()
        .expenseDateBetween(startOfMonth, endOfMonth)
        .findAll();
    return models.map(_toItem).toList();
  }

  Future<List<ExpenseItem>> searchExpenses(String query) async {
    if (query.isEmpty) return getAllExpenses();
    final lowerQuery = query.toLowerCase();
    final all = await getAllExpenses();
    return all.where((e) {
      return (e.merchant?.toLowerCase().contains(lowerQuery) ?? false) ||
          (e.category?.toLowerCase().contains(lowerQuery) ?? false) ||
          (e.description?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  Future<double> getTotalExpenses() async {
    final all = await getAllExpenses();
    double total = 0;
    for (final e in all) {
      total += (e.amount ?? 0);
    }
    return total;
  }

  Future<Map<String, double>> getExpensesByCategory() async {
    final all = await getAllExpenses();
    final byCategory = <String, double>{};
    for (final e in all) {
      final cat = e.category ?? 'Other';
      byCategory[cat] = (byCategory[cat] ?? 0) + (e.amount ?? 0);
    }
    return byCategory;
  }

  Future<List<ExpenseItem>> getRecentExpenses({int limit = 10}) async {
    final models = await db.expenseModels.where().findAll();
    models.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return models.take(limit).map(_toItem).toList();
  }

  Future<void> deleteExpense(int id) async {
    await db.expenseModels.delete(id);
  }

  ExpenseItem _toItem(ExpenseModel model) {
    return ExpenseItem(
      id: model.id,
      screenshotId: model.screenshotId,
      amount: model.amount,
      merchant: model.merchant,
      expenseDate: model.expenseDate,
      category: model.category,
      description: model.description,
      createdAt: model.createdAt,
    );
  }
}
