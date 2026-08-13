import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbStepperVertical extends StatelessWidget {
  final List<String> steps;
  final int currentStep;
  final ValueChanged<int>? onStepTapped;

  const SbStepperVertical({
    super.key,
    required this.steps,
    required this.currentStep,
    this.onStepTapped,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: steps.length,
      itemBuilder: (context, index) {
        final isCompleted = index < currentStep;
        final isActive = index == currentStep;
        final isLast = index == steps.length - 1;

        final color = isCompleted || isActive ? colorScheme.primary : colorScheme.surfaceContainerHighest;
        final textColor = isActive ? colorScheme.onSurface : colorScheme.onSurfaceVariant;
        final fontWeight = isActive ? FontWeight.w600 : FontWeight.w500;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                GestureDetector(
                  onTap: onStepTapped != null ? () => onStepTapped!(index) : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isCompleted ? colorScheme.primary : colorScheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: isCompleted
                        ? Icon(Icons.check_rounded, size: 16, color: colorScheme.onPrimary)
                        : Text(
                            '${index + 1}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 32, // Line height between steps
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: isCompleted ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                  ),
              ],
            ),
            const SizedBox(width: SBSpacing.md),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  steps[index],
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: textColor,
                    fontWeight: fontWeight,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
