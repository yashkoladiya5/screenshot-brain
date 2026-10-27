import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/category_provider.dart';
import '../../../core/design/tokens.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/components/sb_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_extensions.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  static const Map<String, (IconData, Color)> _categoryVisuals = {
    'Payments': (Icons.payments_rounded, AppColors.categoryPayments),
    'UPI Receipts': (Icons.account_balance_rounded, AppColors.categoryUpi),
    'Shopping': (Icons.shopping_bag_rounded, AppColors.categoryShopping),
    'Travel Tickets': (Icons.flight_rounded, AppColors.categoryTravel),
    'Bills': (Icons.receipt_long_rounded, AppColors.categoryBills),
    'Documents': (Icons.description_rounded, AppColors.categoryDocuments),
    'OTP Screenshots': (Icons.sms_rounded, AppColors.categoryOtp),
    'Addresses': (Icons.location_on_rounded, AppColors.categoryAddress),
    'Notes': (Icons.note_rounded, AppColors.categoryNotes),
    'Social Media': (Icons.person_rounded, AppColors.categorySocial),
    'Other': (Icons.folder_rounded, AppColors.categoryOther),
  };

  /// Visuals for any category label; categories outside the canonical
  /// vocabulary still get a card instead of disappearing from the UI.
  static (IconData, Color) _visualsFor(String name) =>
      _categoryVisuals[name] ?? (Icons.folder_rounded, AppColors.categoryOther);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countsAsync = ref.watch(categoryCountsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: countsAsync.when(
        loading: () => const LoadingWidget(
          message: 'Loading categories...',
          icon: Icons.category_rounded,
        ),
        error: (error, stack) {
          // Technical detail stays in the logs (repo-wide debugPrint pattern);
          // the user sees a short, actionable sentence instead of a dump.
          debugPrint('[Categories] Could not load categories: $error\n$stack');
          return AppErrorWidget(
            title: 'Could not load categories',
            message: "We couldn't load your categories. Please try again.",
            icon: Icons.category_outlined,
            onRetry: () => ref.invalidate(categoryCountsProvider),
          );
        },
        data: (counts) {
          final totalScreenshots = counts.values.fold(0, (a, b) => a + b);
          if (totalScreenshots == 0) {
            return const EmptyStateWidget(
              icon: Icons.folder_open_rounded,
              title: 'No categorized screenshots yet',
              subtitle:
                  'Scan your screenshots and they will be grouped here automatically',
            );
          }
          // Render in the provider's deterministic order (count desc, then
          // canonical vocabulary, then alphabetical), keeping zero-count
          // canonical categories on screen and surfacing unknown labels.
          final ordered = orderCategoryCounts(counts, includeEmpty: true);
          final entries = ordered.entries.toList();
          return GridView.builder(
            padding: const EdgeInsets.all(SBSpacing.lg),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: SBSpacing.md,
              mainAxisSpacing: SBSpacing.md,
              childAspectRatio: 1.3,
            ),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final name = entries[index].key;
              final count = entries[index].value;
              final (icon, color) = _visualsFor(name);
              return _CategoryCard(
                name: name,
                icon: icon,
                color: color,
                count: count,
              );
            },
          );
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final int count;

  const _CategoryCard({
    required this.name,
    required this.icon,
    required this.color,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SbCard(
      padding: const EdgeInsets.all(SBSpacing.lg),
      onTap: () => context.push('/categories/$name'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(SBSpacing.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(SBRadius.md),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: SBSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: theme.textTheme.titleSmall),
              const SizedBox(height: SBSpacing.xxs),
              Text(
                '$count screenshot${count == 1 ? '' : 's'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.sb.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
