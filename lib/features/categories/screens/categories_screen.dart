import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/category_provider.dart';
import '../../../core/design/tokens.dart';
import '../../../core/components/sb_loading.dart';
import '../../../core/components/sb_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_extensions.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  static const _categories = [
    ('Payments', Icons.payments_rounded, AppColors.categoryPayments),
    ('UPI Receipts', Icons.account_balance_rounded, AppColors.categoryUpi),
    ('Shopping', Icons.shopping_bag_rounded, AppColors.categoryShopping),
    ('Travel Tickets', Icons.flight_rounded, AppColors.categoryTravel),
    ('Bills', Icons.receipt_long_rounded, AppColors.categoryBills),
    ('Documents', Icons.description_rounded, AppColors.categoryDocuments),
    ('OTP Screenshots', Icons.sms_rounded, AppColors.categoryOtp),
    ('Addresses', Icons.location_on_rounded, AppColors.categoryAddress),
    ('Notes', Icons.note_rounded, AppColors.categoryNotes),
    ('Social Media', Icons.person_rounded, AppColors.categorySocial),
    ('Other', Icons.folder_rounded, AppColors.categoryOther),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final countsAsync = ref.watch(categoryCountsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: countsAsync.when(
        loading: () => const SbLoading(),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: SBSpacing.lg),
              Text('Error: $error', style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
        data: (counts) => GridView.builder(
          padding: const EdgeInsets.all(SBSpacing.lg),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: SBSpacing.md,
            mainAxisSpacing: SBSpacing.md,
            childAspectRatio: 1.3,
          ),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final (name, icon, color) = _categories[index];
            final count = counts[name] ?? 0;
            return _CategoryCard(
              name: name,
              icon: icon,
              color: color,
              count: count,
            );
          },
        ),
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
                style: theme.textTheme.bodySmall?.copyWith(color: context.sb.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
