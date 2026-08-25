import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbProgressStep {
  final String title;
  final String? subtitle;
  final Widget? content;
  final bool isActive;
  final bool isCompleted;

  const SbProgressStep({
    required this.title,
    this.subtitle,
    this.content,
    this.isActive = false,
    this.isCompleted = false,
  });
}

class SbProgressStepperVertical extends StatelessWidget {
  final List<SbProgressStep> steps;
  final Color? activeColor;
  final Color? completedColor;
  final Color? inactiveColor;

  const SbProgressStepperVertical({
    super.key,
    required this.steps,
    this.activeColor,
    this.completedColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final active = activeColor ?? colorScheme.primary;
    final completed = completedColor ?? Colors.green.shade600;
    final inactive = inactiveColor ?? colorScheme.surfaceContainerHighest;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: steps.length,
      itemBuilder: (context, index) {
        final step = steps[index];
        final isLast = index == steps.length - 1;
        
        Color nodeColor = inactive;
        if (step.isCompleted) {
          nodeColor = completed;
        } else if (step.isActive) {
          nodeColor = active;
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column 1: Node and Line
              Column(
                children: [
                  // Node
                  Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(top: 2), // Align with text
                    decoration: BoxDecoration(
                      color: step.isActive ? colorScheme.surface : nodeColor,
                      shape: BoxShape.circle,
                      border: step.isActive ? Border.all(color: active, width: 3) : null,
                    ),
                    child: step.isCompleted
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                        : null,
                  ),
                  // Connecting Line
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: step.isCompleted ? completed : inactive,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: SBSpacing.md),
              
              // Column 2: Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: SBSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: step.isActive || step.isCompleted ? FontWeight.bold : FontWeight.normal,
                          color: step.isActive ? active : (step.isCompleted ? colorScheme.onSurface : colorScheme.onSurfaceVariant),
                        ),
                      ),
                      if (step.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          step.subtitle!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (step.content != null && step.isActive) ...[
                        const SizedBox(height: SBSpacing.md),
                        step.content!,
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
