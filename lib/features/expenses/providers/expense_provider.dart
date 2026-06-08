import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense_item.dart';
import '../repositories/expense_repository.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository();
});

final expenseListProvider = FutureProvider<List<ExpenseItem>>((ref) async {
  final repo = ref.read(expenseRepositoryProvider);
  return repo.getAllExpenses();
});

final expenseTotalProvider = FutureProvider<double>((ref) async {
  final repo = ref.read(expenseRepositoryProvider);
  return repo.getTotalExpenses();
});

final expenseByCategoryProvider = FutureProvider<Map<String, double>>((ref) async {
  final repo = ref.read(expenseRepositoryProvider);
  return repo.getExpensesByCategory();
});

final recentExpensesProvider = FutureProvider<List<ExpenseItem>>((ref) async {
  final repo = ref.read(expenseRepositoryProvider);
  return repo.getRecentExpenses();
});

final expenseSearchQueryProvider = StateProvider<String>((ref) => '');

final expenseSearchResultsProvider = FutureProvider<List<ExpenseItem>>((ref) async {
  final query = ref.watch(expenseSearchQueryProvider);
  if (query.isEmpty) return [];
  final repo = ref.read(expenseRepositoryProvider);
  return repo.searchExpenses(query);
});
