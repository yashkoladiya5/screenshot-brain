import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../models/expense_item.dart';
import '../providers/expense_provider.dart';

class ExpenseDashboardScreen extends ConsumerStatefulWidget {
  const ExpenseDashboardScreen({super.key});

  @override
  ConsumerState<ExpenseDashboardScreen> createState() => _ExpenseDashboardScreenState();
}

class _ExpenseDashboardScreenState extends ConsumerState<ExpenseDashboardScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalAsync = ref.watch(expenseTotalProvider);
    final categoryAsync = ref.watch(expenseByCategoryProvider);
    final recentAsync = ref.watch(recentExpensesProvider);
    final searchQuery = ref.watch(expenseSearchQueryProvider);
    final searchResultsAsync = ref.watch(expenseSearchResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Dashboard'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            totalAsync.when(
              loading: () => _buildSummaryCard(context, 'Loading...', 'Total Expenses'),
              error: (e, _) => _buildSummaryCard(context, 'Error', 'Total Expenses'),
              data: (total) => _buildSummaryCard(
                context,
                '₹${NumberFormat('#,##0.00').format(total)}',
                'Total Expenses',
              ),
            ),
            const SizedBox(height: 24),
            Text('Expense Categories', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            categoryAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, _) => Text('Error: $e'),
              data: (categories) {
                if (categories.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No expenses recorded yet'),
                    ),
                  );
                }
                final total = categories.values.fold(0.0, (a, b) => a + b);
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: categories.entries.map((entry) {
                        final percentage = total > 0 ? (entry.value / total) * 100 : 0.0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(entry.key, style: Theme.of(context).textTheme.bodyMedium),
                                  Text(
                                    '₹${NumberFormat('#,##0.00').format(entry.value)} (${percentage.toStringAsFixed(1)}%)',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: percentage / 100,
                                  minHeight: 8,
                                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search expenses...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(expenseSearchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
              ),
              onChanged: (value) => ref.read(expenseSearchQueryProvider.notifier).state = value,
            ),
            const SizedBox(height: 16),
            searchQuery.isNotEmpty
                ? _buildExpenseList(context, searchResultsAsync, ref)
                : _buildRecentExpenses(context, recentAsync, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String amount, String label) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.account_balance_wallet, color: Theme.of(context).colorScheme.primary, size: 32),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(amount, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                Text(label, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseList(BuildContext context, AsyncValue<List<ExpenseItem>> async, WidgetRef ref) {
    return async.when(
      loading: () => const LoadingWidget(),
      error: (e, _) => Text('Error: $e'),
      data: (expenses) {
        if (expenses.isEmpty) return const EmptyStateWidget(icon: Icons.search_off, title: 'No Expenses Found');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Search Results', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...expenses.map((e) => _buildExpenseCard(context, e)),
          ],
        );
      },
    );
  }

  Widget _buildRecentExpenses(BuildContext context, AsyncValue<List<ExpenseItem>> async, WidgetRef ref) {
    return async.when(
      loading: () => const LoadingWidget(),
      error: (e, _) => Text('Error: $e'),
      data: (expenses) {
        if (expenses.isEmpty) return const EmptyStateWidget(icon: Icons.receipt_long, title: 'No Expenses Yet', subtitle: 'Expenses from screenshots will appear here');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent Expenses', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...expenses.map((e) => _buildExpenseCard(context, e)),
          ],
        );
      },
    );
  }

  Widget _buildExpenseCard(BuildContext context, ExpenseItem expense) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(Icons.receipt, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(expense.merchant ?? 'Unknown Merchant', style: Theme.of(context).textTheme.titleSmall),
        subtitle: Text('${expense.category ?? 'Other'} • ${expense.dateDisplay}'),
        trailing: Text(
          expense.amountDisplay,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
