import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbPricingCard extends StatelessWidget {
  final String title;
  final String price;
  final String billingPeriod;
  final String? description;
  final List<String> features;
  final bool isPopular;
  final VoidCallback onActionTap;
  final String actionText;

  const SbPricingCard({
    super.key,
    required this.title,
    required this.price,
    this.billingPeriod = '/mo',
    this.description,
    required this.features,
    this.isPopular = false,
    required this.onActionTap,
    this.actionText = 'Get Started',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final borderColor = isPopular ? colorScheme.primary : colorScheme.outlineVariant.withValues(alpha: 0.5);
    final borderWidth = isPopular ? 2.0 : 1.0;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          margin: EdgeInsets.only(top: isPopular ? 16.0 : 0),
          padding: const EdgeInsets.all(SBSpacing.xl),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(SBRadius.xl),
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: isPopular
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    )
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isPopular ? colorScheme.primary : colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: SBSpacing.sm),
              if (description != null) ...[
                Text(
                  description!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: SBSpacing.md),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    price,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    billingPeriod,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: SBSpacing.lg),
              Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
              const SizedBox(height: SBSpacing.lg),
              ...features.map((feature) => Padding(
                    padding: const EdgeInsets.only(bottom: SBSpacing.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: isPopular ? colorScheme.primary : colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        const SizedBox(width: SBSpacing.sm),
                        Expanded(
                          child: Text(
                            feature,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: SBSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onActionTap,
                  style: FilledButton.styleFrom(
                    backgroundColor: isPopular ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                    foregroundColor: isPopular ? colorScheme.onPrimary : colorScheme.onSurface,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(SBRadius.md),
                    ),
                  ),
                  child: Text(
                    actionText,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (isPopular)
          Positioned(
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(SBRadius.full),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Text(
                'MOST POPULAR',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
