import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbProgressStep extends StatelessWidget {
  final int totalSteps;
  final int currentStep;
  final double height;
  final Color? activeColor;
  final Color? inactiveColor;

  const SbProgressStep({
    super.key,
    required this.totalSteps,
    required this.currentStep,
    this.height = 6.0,
    this.activeColor,
    this.inactiveColor,
  }) : assert(totalSteps > 0),
       assert(currentStep >= 0 && currentStep <= totalSteps);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final active = activeColor ?? colorScheme.primary;
    final inactive = inactiveColor ?? colorScheme.surfaceContainerHighest;

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = SBSpacing.xs;
        // Total width minus all the spacing gaps, divided by number of steps
        final stepWidth = (constraints.maxWidth - (spacing * (totalSteps - 1))) / totalSteps;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(totalSteps, (index) {
            final isCompleted = index < currentStep;
            
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: height,
              width: stepWidth,
              decoration: BoxDecoration(
                color: isCompleted ? active : inactive,
                borderRadius: BorderRadius.circular(SBRadius.full),
              ),
            );
          }),
        );
      },
    );
  }
}
