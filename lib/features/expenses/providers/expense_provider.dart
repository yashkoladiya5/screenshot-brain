import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/num_extensions.dart';
import '../models/expense_item.dart';
import '../repositories/expense_repository.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository();
});

/// Runs of whitespace (spaces, tabs, newlines) — OCR text carries both.
final RegExp _spaces = RegExp(r'\s+');

/// Normalizes a raw expense search query: trim, collapse whitespace,
/// lowercase for case-insensitive matching.
String normalizeExpenseQuery(String raw) =>
    raw.trim().toLowerCase().replaceAll(_spaces, ' ');

/// Immutable one-pass aggregation over the expense list.
///
/// Built from a single iteration so total, category breakdown and the
/// recent-N list never trigger separate database scans.
class ExpenseSnapshot {
  static const int recentLimit = 10;

  final List<ExpenseItem> expenses;
  final double total;
  final Map<String, double> byCategory;
  final List<ExpenseItem> recent;

  /// Sum of amounts whose expense date falls in the current calendar month.
  final double monthlyTotal;

  const ExpenseSnapshot._({
    required this.expenses,
    required this.total,
    required this.byCategory,
    required this.recent,
    required this.monthlyTotal,
  });

  factory ExpenseSnapshot.from(Iterable<ExpenseItem> source, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    double total = 0;
    double monthlyTotal = 0;
    final categoryTotals = <String, double>{};
    final items = <ExpenseItem>[];
    for (final expense in source) {
      items.add(expense);
      final amount = expense.amount ?? 0;
      total += amount;
      // Same trimming the model getters and ExpenseRepository apply: a
      // whitespace-only label became its own invisible bucket here while the
      // dashboard chip rendered blank next to a real 'Other' row.
      final stored = (expense.category ?? '').trim();
      final category = stored.isEmpty ? 'Other' : stored;
      categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
      final date = expense.expenseDate ?? expense.createdAt;
      if (date.year == reference.year && date.month == reference.month) {
        monthlyTotal += amount;
      }
    }
    // Newest-first with an id-descending tie-break, so the order (and which
    // items survive the recent-N cutoff) never depends on repository row
    // order: `List.sort` leaves equal elements in input order, which is
    // whatever the database scan happened to return.
    items.sort((a, b) {
      final byNewest = b.createdAt.compareTo(a.createdAt);
      return byNewest != 0 ? byNewest : b.id.compareTo(a.id);
    });
    // Sum-then-round: each aggregate is rounded once, after summing, so
    // binary drift like 99.99*3 + 34.59 == 334.55999999999995 never leaks
    // into displayed money. Canonical map order (total desc, name asc) keeps
    // the breakdown deterministic for equal totals.
    final byCategory =
        categoryTotals.entries
            .map((entry) => MapEntry(entry.key, entry.value.roundTo(2)))
            .toList()
          ..sort((a, b) {
            final byTotal = b.value.compareTo(a.value);
            return byTotal != 0 ? byTotal : a.key.compareTo(b.key);
          });
    return ExpenseSnapshot._(
      expenses: List<ExpenseItem>.unmodifiable(items),
      total: total.roundTo(2),
      byCategory: Map<String, double>.unmodifiable({
        for (final entry in byCategory) entry.key: entry.value,
      }),
      recent: List<ExpenseItem>.unmodifiable(items.take(recentLimit)),
      monthlyTotal: monthlyTotal.roundTo(2),
    );
  }

  /// Case-insensitive substring search over merchant / category / description.
  ///
  /// The item side is whitespace-collapsed the same way the query is: OCR
  /// writes merchants and notes with runs of spaces and newlines, so a row
  /// stored as 'Big  Basket' matched 'big basket' only by accident.
  List<ExpenseItem> search(String normalizedQuery) {
    if (normalizedQuery.isEmpty) return expenses;
    String field(String? value) =>
        value == null ? '' : value.toLowerCase().replaceAll(_spaces, ' ');
    return expenses.where((e) {
      return field(e.merchant).contains(normalizedQuery) ||
          field(e.category).contains(normalizedQuery) ||
          field(e.description).contains(normalizedQuery);
    }).toList();
  }
}

/// The single source of expense data: one backend scan shared by every
/// derived provider below (Riverpod deduplicates the in-flight future, so
/// concurrent watchers never cause duplicate scans).
/// Errors from the repository propagate as AsyncError instead of being
/// swallowed.
final expenseListProvider = FutureProvider<List<ExpenseItem>>((ref) async {
  final repo = ref.read(expenseRepositoryProvider);
  return repo.getAllExpenses();
});

final expenseSnapshotProvider = FutureProvider<ExpenseSnapshot>((ref) async {
  final expenses = await ref.watch(expenseListProvider.future);
  return ExpenseSnapshot.from(expenses);
});

final expenseTotalProvider = FutureProvider<double>((ref) async {
  final snapshot = await ref.watch(expenseSnapshotProvider.future);
  return snapshot.total;
});

/// Total for the current calendar month, derived from the same snapshot.
final expenseMonthlyTotalProvider = FutureProvider<double>((ref) async {
  final snapshot = await ref.watch(expenseSnapshotProvider.future);
  return snapshot.monthlyTotal;
});

final expenseByCategoryProvider = FutureProvider<Map<String, double>>((
  ref,
) async {
  final snapshot = await ref.watch(expenseSnapshotProvider.future);
  return snapshot.byCategory;
});

/// Most recent [ExpenseSnapshot.recentLimit] expenses, derived from the same
/// snapshot instead of issuing its own scan.
final recentExpensesProvider = FutureProvider<List<ExpenseItem>>((ref) async {
  final snapshot = await ref.watch(expenseSnapshotProvider.future);
  return snapshot.recent;
});

final expenseSearchQueryProvider = StateProvider<String>((ref) => '');

/// Filters the shared snapshot in memory, so keystrokes no longer hit the
/// database per character.
final expenseSearchResultsProvider = FutureProvider<List<ExpenseItem>>((
  ref,
) async {
  final query = ref.watch(expenseSearchQueryProvider);
  final normalized = normalizeExpenseQuery(query);
  final snapshot = await ref.watch(expenseSnapshotProvider.future);
  return snapshot.search(normalized);
});
