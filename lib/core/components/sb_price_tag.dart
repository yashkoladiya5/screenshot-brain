import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../design/tokens.dart';

class SbPriceTag extends StatelessWidget {
  final double price;
  final double? originalPrice;
  final String currencySymbol;
  final bool compact;

  const SbPriceTag({
    super.key,
    required this.price,
    this.originalPrice,
    this.currencySymbol = '\$',
    this.compact = false,
  });

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      symbol: currencySymbol,
      decimalDigits: amount.truncateToDouble() == amount ? 0 : 2,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final hasDiscount = originalPrice != null && originalPrice! > price;
    final priceStr = _formatCurrency(price);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          priceStr,
          style: (compact ? theme.textTheme.titleMedium : theme.textTheme.headlineSmall)?.copyWith(
            fontWeight: FontWeight.bold,
            color: hasDiscount ? Colors.green.shade700 : colorScheme.onSurface,
          ),
        ),
        if (hasDiscount) ...[
          SizedBox(width: compact ? SBSpacing.xs : SBSpacing.sm),
          Text(
            _formatCurrency(originalPrice!),
            style: (compact ? theme.textTheme.bodyMedium : theme.textTheme.titleMedium)?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              decoration: TextDecoration.lineThrough,
              decorationColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }
}
