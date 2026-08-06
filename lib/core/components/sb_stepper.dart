import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbStepper extends StatelessWidget {
  final int totalSteps;
  final int currentStep;
  final List<String>? stepLabels;

  const SbStepper({
    super.key,
    required this.totalSteps,
    required this.currentStep,
    this.stepLabels,
  }) : assert(totalSteps > 0),
       assert(currentStep >= 0 && currentStep <= totalSteps);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: List.generate(totalSteps * 2 - 1, (index) {
        final stepIndex = index ~/ 2;
        final isLine = index % 2 != 0;

        if (isLine) {
          final isCompleted = currentStep > stepIndex;
          return Expanded(
            child: Container(
              height: 2,
              color: isCompleted ? colorScheme.primary : colorScheme.outlineVariant,
            ),
          );
        }

        final isCompleted = currentStep > stepIndex;
        final isCurrent = currentStep == stepIndex;
        
        final circleColor = isCompleted || isCurrent ? colorScheme.primary : colorScheme.surfaceContainerHighest;
        final textColor = isCompleted || isCurrent ? colorScheme.onPrimary : colorScheme.onSurfaceVariant;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: circleColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: isCompleted
                  ? Icon(Icons.check_rounded, size: 16, color: colorScheme.onPrimary)
                  : Text(
                      '${stepIndex + 1}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            if (stepLabels != null && stepIndex < stepLabels!.length) ...[
              const SizedBox(height: SBSpacing.xxs),
              Text(
                stepLabels![stepIndex],
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isCurrent ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ],
        );
      }),
    );
  }
}
