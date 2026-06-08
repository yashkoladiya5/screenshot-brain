import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/category_provider.dart';
import '../../../core/widgets/loading_widget.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoryListProvider);
    final countsAsync = ref.watch(categoryCountsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: countsAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (counts) {
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final count = counts[category] ?? 0;
              return _CategoryCard(
                category: category,
                count: count,
                icon: _getCategoryIcon(category),
                color: _getCategoryColor(category),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Payments': return Icons.payments;
      case 'UPI Receipts': return Icons.account_balance;
      case 'Shopping': return Icons.shopping_bag;
      case 'Travel Tickets': return Icons.flight;
      case 'Bills': return Icons.receipt_long;
      case 'Documents': return Icons.description;
      case 'OTP Screenshots': return Icons.sms;
      case 'Addresses': return Icons.location_on;
      case 'Notes': return Icons.note;
      case 'Social Media': return Icons.person;
      default: return Icons.folder;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Payments': return const Color(0xFF4CAF50);
      case 'UPI Receipts': return const Color(0xFF009688);
      case 'Shopping': return const Color(0xFFFF9800);
      case 'Travel Tickets': return const Color(0xFF2196F3);
      case 'Bills': return const Color(0xFFF44336);
      case 'Documents': return const Color(0xFF9C27B0);
      case 'OTP Screenshots': return const Color(0xFFFF5722);
      case 'Addresses': return const Color(0xFF795548);
      case 'Notes': return const Color(0xFF607D8B);
      case 'Social Media': return const Color(0xFF00BCD4);
      default: return const Color(0xFF9E9E9E);
    }
  }
}

class _CategoryCard extends StatelessWidget {
  final String category;
  final int count;
  final IconData icon;
  final Color color;

  const _CategoryCard({
    required this.category,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    '$count screenshot${count == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
