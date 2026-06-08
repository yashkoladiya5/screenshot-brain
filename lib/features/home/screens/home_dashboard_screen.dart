import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/home_provider.dart';
import '../../screenshots/providers/screenshot_provider.dart';
import '../../expenses/models/expense_item.dart';
import '../../../core/design/tokens.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/components/sb_card.dart';
import '../../../core/components/sb_stat_card.dart';
import '../../../core/components/sb_section_header.dart';
import '../../../core/components/sb_loading.dart';
import '../../../core/components/sb_empty_state.dart';
import '../../../core/components/sb_error_state.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(homeStatsProvider);
    final isScanning = ref.watch(scanningProvider);

    return Scaffold(
      body: statsAsync.when(
        loading: () => const SbLoading(message: 'Loading your dashboard...'),
        error: (error, _) => SbErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(homeStatsProvider),
        ),
        data: (stats) {
          if (stats.screenshotCount == 0 && !isScanning) {
            return _EmptyHome(scan: () => ref.read(scanScreenshotsProvider.notifier).scan());
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(homeStatsProvider),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _SliverAppBar(isScanning: isScanning),
                if (isScanning)
                  const SliverToBoxAdapter(child: _ScanningBanner()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(SBSpacing.lg, SBSpacing.lg, SBSpacing.lg, 0),
                  sliver: SliverToBoxAdapter(
                    child: _StatsGrid(stats: stats),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(SBSpacing.lg, SBSpacing.xxl, SBSpacing.lg, SBSpacing.md),
                  sliver: SliverToBoxAdapter(
                    child: SbSectionHeader(
                      title: 'Quick Actions',
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: SBSpacing.lg),
                  sliver: SliverToBoxAdapter(
                    child: _QuickActions(
                      isScanning: isScanning,
                      onScan: () => ref.read(scanScreenshotsProvider.notifier).scan(),
                    ),
                  ),
                ),
                if (stats.recentExpenses.isNotEmpty) ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(SBSpacing.lg, SBSpacing.xxl, SBSpacing.lg, SBSpacing.md),
                    sliver: SliverToBoxAdapter(
                      child: SbSectionHeader(
                        title: 'Recent Expenses',
                        actionLabel: 'View All',
                        onAction: () => context.push('/expenses'),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: SBSpacing.lg),
                    sliver: SliverToBoxAdapter(
                      child: _RecentExpensesList(expenses: stats.recentExpenses),
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: SBSpacing.xxxl)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SliverAppBar extends ConsumerWidget {
  final bool isScanning;

  const _SliverAppBar({required this.isScanning});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return SliverAppBar(
      floating: true,
      snap: true,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Screenshot Brain', style: theme.textTheme.headlineSmall),
          Text('Your intelligent screenshot assistant', style: theme.textTheme.bodySmall),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: SBSpacing.sm),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(SBRadius.lg),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: IconButton(
            icon: const Icon(Icons.search_rounded, size: SBSizes.iconMd),
            onPressed: () => context.push('/search'),
            tooltip: 'Search',
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: SBSpacing.sm),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(SBRadius.lg),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: IconButton(
            icon: const Icon(Icons.settings_rounded, size: SBSizes.iconMd),
            onPressed: () => context.push('/settings'),
            tooltip: 'Settings',
          ),
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final HomeStats stats;

  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: SbStatCard(
              icon: Icons.photo_library_rounded,
              label: 'Screenshots',
              value: '${stats.screenshotCount}',
            )),
            const SizedBox(width: SBSpacing.md),
            Expanded(child: SbStatCard(
              icon: Icons.receipt_long_rounded,
              label: 'Expenses',
              value: '${stats.expenseCount}',
            )),
          ],
        ),
        const SizedBox(height: SBSpacing.md),
        Row(
          children: [
            Expanded(child: SbStatCard(
              icon: Icons.hourglass_empty_rounded,
              label: 'Unprocessed',
              value: '${stats.unprocessedCount}',
            )),
            const SizedBox(width: SBSpacing.md),
            Expanded(child: SbStatCard(
              icon: Icons.account_balance_wallet_rounded,
              label: 'Total Spent',
              value: '\u20b9${NumberFormat('#,##0').format(stats.totalExpenses)}',
              color: AppColors.success,
            )),
          ],
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  final bool isScanning;
  final VoidCallback onScan;

  const _QuickActions({required this.isScanning, required this.onScan});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ActionButton(
          icon: Icons.document_scanner_rounded,
          label: 'Scan',
          isLoading: isScanning,
          onTap: isScanning ? null : onScan,
        ),
        const SizedBox(width: SBSpacing.md),
        _ActionButton(
          icon: Icons.category_rounded,
          label: 'Categories',
          onTap: () => context.push('/categories'),
        ),
        const SizedBox(width: SBSpacing.md),
        _ActionButton(
          icon: Icons.receipt_rounded,
          label: 'Expenses',
          onTap: () => context.push('/expenses'),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: SbCard(
        padding: const EdgeInsets.symmetric(vertical: SBSpacing.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(SBRadius.xl),
          onTap: onTap,
          child: Column(
            children: [
              if (isLoading)
                SizedBox(
                  width: SBSizes.iconXxl,
                  height: SBSizes.iconXxl,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: theme.colorScheme.primary,
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(SBSpacing.sm),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(SBRadius.sm),
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary, size: SBSizes.iconXl),
                ),
              const SizedBox(height: SBSpacing.sm),
              Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentExpensesList extends StatelessWidget {
  final List<ExpenseItem> expenses;

  const _RecentExpensesList({required this.expenses});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: expenses.take(5).map((expense) {
        return Padding(
          padding: const EdgeInsets.only(bottom: SBSpacing.sm),
          child: SbCard(
            padding: const EdgeInsets.symmetric(horizontal: SBSpacing.lg, vertical: SBSpacing.md),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(SBSpacing.sm),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(SBRadius.sm),
                  ),
                  child: Icon(
                    Icons.receipt_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: SBSizes.iconMd,
                  ),
                ),
                const SizedBox(width: SBSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(expense.merchant ?? 'Unknown', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                      const SizedBox(height: SBSpacing.xxs),
                      Text('${expense.category ?? "Other"} \u2022 ${expense.dateDisplay}', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                Text(expense.amountDisplay, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.success)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _EmptyHome extends StatelessWidget {
  final VoidCallback scan;

  const _EmptyHome({required this.scan});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SbEmptyState(
          icon: Icons.photo_library_outlined,
          title: 'No screenshots yet',
          subtitle: 'Scan your device to automatically organize screenshots, detect expenses, and find important documents.',
          action: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: scan,
              icon: const Icon(Icons.document_scanner_rounded, size: SBSizes.iconMd),
              label: const Text('Scan Screenshots'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: SBSpacing.lg),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanningBanner extends StatelessWidget {
  const _ScanningBanner();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(SBSpacing.lg, SBSpacing.sm, SBSpacing.lg, 0),
      child: SbCard(
        padding: const EdgeInsets.all(SBSpacing.lg),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: primary,
              ),
            ),
            const SizedBox(width: SBSpacing.md),
            Text('Scanning for screenshots...', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}


