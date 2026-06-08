import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/expense_item.dart';
import '../providers/expense_provider.dart';
import '../../../core/design/tokens.dart';
import '../../../core/components/sb_card.dart';
import '../../../core/components/sb_loading.dart';
import '../../../core/components/sb_empty_state.dart';
import '../../../core/components/sb_section_header.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/theme/app_colors.dart';

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
    final theme = Theme.of(context);
    final sb = context.sb;
    final totalAsync = ref.watch(expenseTotalProvider);
    final categoryAsync = ref.watch(expenseByCategoryProvider);
    final recentAsync = ref.watch(recentExpensesProvider);
    final searchQuery = ref.watch(expenseSearchQueryProvider);
    final searchResultsAsync = ref.watch(expenseSearchResultsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(SBSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            totalAsync.when(
              loading: () => _summarySkeleton(theme: theme),
              error: (e, _) => _summarySkeleton(theme: theme),
              data: (total) => SbCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(SBSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(SBRadius.md),
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.success, size: 28),
                    ),
                    const SizedBox(width: SBSpacing.lg),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '\u20b9${NumberFormat('#,##0.00').format(total)}',
                          style: theme.textTheme.displaySmall?.copyWith(color: AppColors.success),
                        ),
                        const SizedBox(height: SBSpacing.xxs),
                        Text('Total Expenses', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: SBSpacing.xxl),

            SbSectionHeader(title: 'Categories'),
            const SizedBox(height: SBSpacing.md),
            categoryAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(SBSpacing.xxl),
                child: SbLoading(),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: SBSpacing.xl),
                child: Text('Error loading categories', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
              ),
              data: (categories) {
                if (categories.isEmpty) {
                  return SbCard(
                    child: Center(
                      child: Text('No expenses recorded yet', style: theme.textTheme.bodyMedium?.copyWith(color: sb.textSecondary)),
                    ),
                  );
                }
                final total = categories.values.fold(0.0, (a, b) => a + b);
                return SbCard(
                  child: Column(
                    children: categories.entries.map((entry) {
                      final percentage = total > 0 ? (entry.value / total) * 100 : 0.0;
                      final catColor = _categoryColor(entry.key);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: SBSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: catColor,
                                        borderRadius: BorderRadius.circular(SBRadius.full),
                                      ),
                                    ),
                                    const SizedBox(width: SBSpacing.sm),
                                    Text(entry.key, style: theme.textTheme.bodyMedium),
                                  ],
                                ),
                                Text(
                                  '\u20b9${NumberFormat('#,##0.00').format(entry.value)}',
                                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            const SizedBox(height: SBSpacing.sm),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(SBRadius.xs),
                              child: LinearProgressIndicator(
                                value: percentage / 100,
                                minHeight: 6,
                                backgroundColor: sb.borderLight,
                                color: catColor,
                              ),
                            ),
                            const SizedBox(height: SBSpacing.xxs),
                            Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: theme.textTheme.labelSmall?.copyWith(color: sb.textTertiary),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
            const SizedBox(height: SBSpacing.xxl),

            Container(
              decoration: BoxDecoration(
                color: sb.elevated,
                borderRadius: BorderRadius.circular(SBRadius.lg),
                border: Border.all(color: sb.borderLight),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search expenses...',
                  border: InputBorder.none,
                  filled: false,
                  prefixIcon: Icon(Icons.search_rounded, color: sb.textTertiary, size: SBSizes.iconMd),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close_rounded, color: sb.textTertiary, size: SBSizes.iconMd),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(expenseSearchQueryProvider.notifier).state = '';
                          },
                        )
                      : null,
                ),
                onChanged: (value) => ref.read(expenseSearchQueryProvider.notifier).state = value,
              ),
            ),
            const SizedBox(height: SBSpacing.lg),

            if (searchQuery.isNotEmpty)
              _buildExpenseList(context, searchResultsAsync)
            else
              _buildRecentExpenses(context, recentAsync),
          ],
        ),
      ),
    );
  }

  Widget _summarySkeleton({required ThemeData theme}) {
    return SbCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(SBSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(SBRadius.md),
            ),
            child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.success, size: 28),
          ),
          const SizedBox(width: SBSpacing.lg),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('\u20b90.00', style: theme.textTheme.displaySmall?.copyWith(color: AppColors.success)),
              const SizedBox(height: SBSpacing.xxs),
              Text('Total Expenses', style: theme.textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseList(BuildContext context, AsyncValue<List<ExpenseItem>> async) {
    return async.when(
      loading: () => const SbLoading(),
      error: (e, _) => Text('Error: $e'),
      data: (expenses) {
        if (expenses.isEmpty) {
          return const SbEmptyState(icon: Icons.search_off_rounded, title: 'No Expenses Found');
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SbSectionHeader(title: 'Search Results'),
            const SizedBox(height: SBSpacing.md),
            ...expenses.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: SBSpacing.sm),
              child: _ExpenseCard(expense: e),
            )),
          ],
        );
      },
    );
  }

  Widget _buildRecentExpenses(BuildContext context, AsyncValue<List<ExpenseItem>> async) {
    return async.when(
      loading: () => const SbLoading(),
      error: (e, _) => Text('Error: $e'),
      data: (expenses) {
        if (expenses.isEmpty) {
          return const SbEmptyState(
            icon: Icons.receipt_long_rounded,
            title: 'No Expenses Yet',
            subtitle: 'Scan screenshots to detect expenses automatically',
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SbSectionHeader(title: 'Recent Expenses'),
            const SizedBox(height: SBSpacing.md),
            ...expenses.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: SBSpacing.sm),
              child: _ExpenseCard(expense: e),
            )),
          ],
        );
      },
    );
  }

  Color _categoryColor(String? category) {
    switch (category) {
      case 'Food': return AppColors.categoryPayments;
      case 'Travel': return AppColors.categoryTravel;
      case 'Shopping': return AppColors.categoryShopping;
      case 'Bills': return AppColors.categoryBills;
      case 'Healthcare': return AppColors.categoryAddress;
      case 'Entertainment': return AppColors.categorySocial;
      default: return AppColors.categoryOther;
    }
  }
}

class _ExpenseCard extends StatelessWidget {
  final ExpenseItem expense;

  const _ExpenseCard({required this.expense});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SbCard(
      padding: const EdgeInsets.symmetric(horizontal: SBSpacing.lg, vertical: SBSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(SBSpacing.sm),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(SBRadius.sm),
            ),
            child: Icon(Icons.receipt_rounded, color: theme.colorScheme.primary, size: SBSizes.iconMd),
          ),
          const SizedBox(width: SBSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(expense.merchant ?? 'Unknown', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: SBSpacing.xxs),
                Text(
                  '${expense.category ?? "Other"} \u2022 ${expense.dateDisplay}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: SBSpacing.md),
          Text(
            expense.amountDisplay,
            style: theme.textTheme.titleMedium?.copyWith(color: AppColors.success),
          ),
        ],
      ),
    );
  }
}
