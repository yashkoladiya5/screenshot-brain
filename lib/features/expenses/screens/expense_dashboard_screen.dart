import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/expense_item.dart';
import '../providers/expense_provider.dart';
import '../../../core/design/tokens.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/components/sb_card.dart';
import '../../../core/components/sb_section_header.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/expense_item.dart'
    show kExpenseCurrencyLocale, kExpenseCurrencySymbol;

/// Dashboard money follows the app's declared currency presentation
/// (`en_IN` lakh/crore grouping + ₹, shared with the expense models). The
/// previous locale-less `NumberFormat('#,##0.00')` resolved against the
/// device locale, so the summary tile printed '₹129.900,00' on a German
/// device while list rows on the same screen spoke the shared format.
final NumberFormat _rupeeFormat = NumberFormat.currency(
  locale: kExpenseCurrencyLocale,
  symbol: kExpenseCurrencySymbol,
  decimalDigits: 2,
);

class ExpenseDashboardScreen extends ConsumerStatefulWidget {
  const ExpenseDashboardScreen({super.key});

  @override
  ConsumerState<ExpenseDashboardScreen> createState() =>
      _ExpenseDashboardScreenState();
}

class _ExpenseDashboardScreenState
    extends ConsumerState<ExpenseDashboardScreen> {
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

    // One watcher on the single-scan snapshot: total, monthly total, the
    // category breakdown, recent expenses and in-memory search all derive
    // from it — no per-section provider fan-out or extra table scans.
    final snapshotAsync = ref.watch(expenseSnapshotProvider);
    final searchQuery = ref.watch(expenseSearchQueryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      body: snapshotAsync.when(
        loading: () => const LoadingWidget(
          message: 'Loading expenses...',
          icon: Icons.account_balance_wallet_rounded,
        ),
        error: (error, stack) {
          // Technical detail stays in the logs (repo-wide debugPrint pattern);
          // the user sees a short, actionable sentence instead of a dump.
          debugPrint('[Expenses] Could not load expenses: $error\n$stack');
          return AppErrorWidget(
            title: 'Could not load expenses',
            message: "We couldn't load your expenses. Please try again.",
            icon: Icons.account_balance_wallet_outlined,
            onRetry: () => ref.invalidate(expenseListProvider),
          );
        },
        data: (snapshot) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(expenseListProvider),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(SBSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummary(theme, snapshot),
                const SizedBox(height: SBSpacing.xxl),
                const SbSectionHeader(title: 'Categories'),
                const SizedBox(height: SBSpacing.md),
                _buildCategoryBreakdown(theme, sb, snapshot),
                const SizedBox(height: SBSpacing.xxl),
                _buildSearchField(sb),
                const SizedBox(height: SBSpacing.lg),
                if (searchQuery.isNotEmpty)
                  _buildSearchResults(snapshot)
                else
                  _buildRecentExpenses(snapshot),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummary(ThemeData theme, ExpenseSnapshot snapshot) {
    return SbCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(SBSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(SBRadius.md),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: AppColors.success,
              size: 28,
            ),
          ),
          const SizedBox(width: SBSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _rupeeFormat.format(snapshot.total),
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: SBSpacing.xxs),
                Text('Total Expenses', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 48,
            color: theme.colorScheme.outlineVariant,
          ),
          const SizedBox(width: SBSpacing.lg),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _rupeeFormat.format(snapshot.monthlyTotal),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: SBSpacing.xxs),
              Text('This Month', style: theme.textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(
    ThemeData theme,
    ScreenshotBrainThemeExtension sb,
    ExpenseSnapshot snapshot,
  ) {
    final categories = snapshot.byCategory;
    if (categories.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.category_outlined,
        title: 'No expenses recorded yet',
        subtitle: 'Detected expenses from your screenshots will appear here',
        iconSize: 32,
      );
    }
    final sorted = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return SbCard(
      child: Column(
        children: sorted.map((entry) {
          // Percentages come from the snapshot's own total — no re-fold.
          final percentage = snapshot.total > 0
              ? (entry.value / snapshot.total) * 100
              : 0.0;
          final catColor = _categoryColor(entry.key);
          return Padding(
            padding: const EdgeInsets.only(bottom: SBSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // The label is the only elastic child; without Expanded a
                    // long category name pushed the amount off the right edge.
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: catColor,
                              borderRadius: BorderRadius.circular(
                                SBRadius.full,
                              ),
                            ),
                          ),
                          const SizedBox(width: SBSpacing.sm),
                          Flexible(
                            child: Text(
                              entry.key,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: SBSpacing.sm),
                    Text(
                      _rupeeFormat.format(entry.value),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
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
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: sb.textTertiary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchField(ScreenshotBrainThemeExtension sb) {
    final searchQuery = ref.watch(expenseSearchQueryProvider);
    return Container(
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
          prefixIcon: Icon(
            Icons.search_rounded,
            color: sb.textTertiary,
            size: SBSizes.iconMd,
          ),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: sb.textTertiary,
                    size: SBSizes.iconMd,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(expenseSearchQueryProvider.notifier).state = '';
                  },
                )
              : null,
        ),
        onChanged: (value) =>
            ref.read(expenseSearchQueryProvider.notifier).state = value,
      ),
    );
  }

  Widget _buildSearchResults(ExpenseSnapshot snapshot) {
    // Filtering the in-memory snapshot: keystrokes never hit the database.
    final results = snapshot.search(
      normalizeExpenseQuery(ref.watch(expenseSearchQueryProvider)),
    );
    if (results.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.search_off_rounded,
        title: 'No Expenses Found',
        subtitle: 'Try a different merchant, category or description',
        iconSize: 32,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SbSectionHeader(title: 'Search Results'),
        const SizedBox(height: SBSpacing.md),
        ...results.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: SBSpacing.sm),
            child: _ExpenseCard(expense: e),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentExpenses(ExpenseSnapshot snapshot) {
    final recent = snapshot.recent;
    if (recent.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.receipt_long_rounded,
        title: 'No Expenses Yet',
        subtitle: 'Scan screenshots to detect expenses automatically',
        iconSize: 32,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SbSectionHeader(title: 'Recent Expenses'),
        const SizedBox(height: SBSpacing.md),
        ...recent.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: SBSpacing.sm),
            child: _ExpenseCard(expense: e),
          ),
        ),
      ],
    );
  }

  Color _categoryColor(String? category) {
    switch (category) {
      case 'Food':
        return AppColors.categoryPayments;
      case 'Travel':
        return AppColors.categoryTravel;
      case 'Shopping':
        return AppColors.categoryShopping;
      case 'Bills':
        return AppColors.categoryBills;
      case 'Healthcare':
        return AppColors.categoryAddress;
      case 'Entertainment':
        return AppColors.categorySocial;
      default:
        return AppColors.categoryOther;
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
      padding: const EdgeInsets.symmetric(
        horizontal: SBSpacing.lg,
        vertical: SBSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(SBSpacing.sm),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(SBRadius.sm),
            ),
            child: Icon(
              Icons.receipt_rounded,
              color: theme.colorScheme.primary,
              size: SBSizes.iconMd,
            ),
          ),
          const SizedBox(width: SBSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.merchantDisplay,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: SBSpacing.xxs),
                Text(
                  '${expense.categoryDisplay} \u2022 ${expense.dateDisplay}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: SBSpacing.md),
          Text(
            expense.amountDisplay,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}
