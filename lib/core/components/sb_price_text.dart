import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../design/tokens.dart';

class SbPriceText extends StatelessWidget {
  final double amount;
  final String currencyCode;
  final bool isDiscounted;
  final TextStyle? style;

  const SbPriceText({
    super.key,
    required this.amount,
    this.currencyCode = 'USD',
    this.isDiscounted = false,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final formattedPrice = NumberFormat.currency(
      symbol: '\$', // Hardcoded symbol fallback, can be localized later
      name: currencyCode,
      decimalDigits: 2,
    ).format(amount);

    final defaultStyle = theme.textTheme.titleMedium?.copyWith(
      color: isDiscounted ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
      fontWeight: isDiscounted ? FontWeight.normal : FontWeight.w600,
      decoration: isDiscounted ? TextDecoration.lineThrough : TextDecoration.none,
    );

    return Text(
      formattedPrice,
      style: style?.merge(defaultStyle) ?? defaultStyle,
    );
  }
}
