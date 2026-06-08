import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/home_provider.dart';
import '../../screenshots/providers/screenshot_provider.dart';
import '../../expenses/models/expense_item.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(homeStatsProvider);
    final isScanning = ref.watch(scanningProvider);
    debugPrint('[HomeDashboard] build() isScanning=$isScanning statsAsync=${statsAsync.isLoading ? "loading" : statsAsync.hasError ? "error" : "data"}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Screenshot Brain'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (stats) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(homeStatsProvider),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: _StatCard(
                        icon: Icons.photo_library,
                        label: 'Screenshots',
                        value: '${stats.screenshotCount}',
                        color: Theme.of(context).colorScheme.primary,
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _StatCard(
                        icon: Icons.receipt_long,
                        label: 'Expenses',
                        value: '${stats.expenseCount}',
                        color: Colors.green,
                      )),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _StatCard(
                        icon: Icons.category,
                        label: 'Unprocessed',
                        value: '${stats.unprocessedCount}',
                        color: Colors.orange,
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _StatCard(
                        icon: Icons.account_balance_wallet,
                        label: 'Total Spent',
                        value: '\u20b9${NumberFormat('#,##0').format(stats.totalExpenses)}',
                        color: Colors.red,
                      )),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _QuickActionButton(
                        icon: Icons.scanner,
                        label: 'Scan',
                        onTap: isScanning ? null : () => ref.read(scanScreenshotsProvider.notifier).scan(),
                        isLoading: isScanning,
                      ),
                      const SizedBox(width: 12),
                      _QuickActionButton(
                        icon: Icons.search,
                        label: 'Search',
                        onTap: () => context.push('/search'),
                      ),
                      const SizedBox(width: 12),
                      _QuickActionButton(
                        icon: Icons.category,
                        label: 'Categories',
                        onTap: () => context.push('/categories'),
                      ),
                      const SizedBox(width: 12),
                      _QuickActionButton(
                        icon: Icons.account_balance_wallet,
                        label: 'Expenses',
                        onTap: () => context.push('/expenses'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent Expenses', style: Theme.of(context).textTheme.titleMedium),
                      TextButton(
                        onPressed: () => context.push('/expenses'),
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildRecentExpenses(context, stats.recentExpenses),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentExpenses(BuildContext context, List<ExpenseItem> expenses) {
    if (expenses.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No expenses yet. Scan screenshots to detect expenses.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    return Column(
      children: expenses.take(5).map((expense) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(Icons.receipt, color: Theme.of(context).colorScheme.primary, size: 20),
            ),
            title: Text(expense.merchant ?? 'Unknown', style: Theme.of(context).textTheme.bodyMedium),
            subtitle: Text(expense.category ?? 'Other', style: Theme.of(context).textTheme.bodySmall),
            trailing: Text(expense.amountDisplay, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
          ),
        );
      }).toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  const _QuickActionButton({required this.icon, required this.label, this.onTap, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                if (isLoading)
                  const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                else
                  Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
                const SizedBox(height: 8),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
