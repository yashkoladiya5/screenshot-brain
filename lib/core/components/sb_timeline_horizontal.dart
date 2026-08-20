import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbTimelineHorizontal extends StatelessWidget {
  final List<String> steps;
  final int currentStep;
  final Color? activeColor;
  final Color? inactiveColor;

  const SbTimelineHorizontal({
    super.key,
    required this.steps,
    required this.currentStep,
    this.activeColor,
    this.inactiveColor,
  }) : assert(steps.length > 0),
       assert(currentStep >= 0 && currentStep <= steps.length);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final active = activeColor ?? colorScheme.primary;
    final inactive = inactiveColor ?? colorScheme.surfaceContainerHighest;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(steps.length, (index) {
        final isCompleted = index < currentStep;
        final isActive = index == currentStep;
        final isLast = index == steps.length - 1;

        return Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  // Left connector (hidden for first item)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index == 0 ? Colors.transparent : (isCompleted || isActive ? active : inactive),
                    ),
                  ),
                  // Node
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isCompleted || isActive ? active : inactive,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isActive ? active.withValues(alpha: 0.3) : Colors.transparent,
                        width: isActive ? 4 : 0,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: isCompleted
                        ? Icon(Icons.check_rounded, size: 14, color: colorScheme.onPrimary)
                        : Text(
                            '${index + 1}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isActive ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  // Right connector (hidden for last item)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isLast ? Colors.transparent : (isCompleted ? active : inactive),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: SBSpacing.sm),
              Text(
                steps[index],
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive || isCompleted ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
