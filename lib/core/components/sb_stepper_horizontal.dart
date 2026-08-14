import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbStepperHorizontal extends StatelessWidget {
  final List<String> steps;
  final int currentStep;
  final ValueChanged<int>? onStepTapped;

  const SbStepperHorizontal({
    super.key,
    required this.steps,
    required this.currentStep,
    this.onStepTapped,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          // Divider
          final stepIndex = index ~/ 2;
          final isCompleted = stepIndex < currentStep;
          return Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: SBSpacing.sm),
              color: isCompleted ? colorScheme.primary : colorScheme.surfaceContainerHighest,
            ),
          );
        } else {
          // Step circle
          final stepIndex = index ~/ 2;
          final isCompleted = stepIndex < currentStep;
          final isActive = stepIndex == currentStep;
          
          final color = isCompleted || isActive ? colorScheme.primary : colorScheme.surfaceContainerHighest;
          
          return GestureDetector(
            onTap: onStepTapped != null ? () => onStepTapped!(stepIndex) : null,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCompleted ? colorScheme.primary : colorScheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: isCompleted
                      ? Icon(Icons.check_rounded, size: 18, color: colorScheme.onPrimary)
                      : Text(
                          '${stepIndex + 1}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: SBSpacing.xs),
                Text(
                  steps[stepIndex],
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isActive ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }
      }),
    );
  }
}
