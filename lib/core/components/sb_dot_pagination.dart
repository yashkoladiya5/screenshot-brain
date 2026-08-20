import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbDotPagination extends StatelessWidget {
  final int totalPages;
  final int currentPage;
  final Color? activeColor;
  final Color? inactiveColor;
  final double dotSize;
  final double activeWidthMultiplier;

  const SbDotPagination({
    super.key,
    required this.totalPages,
    required this.currentPage,
    this.activeColor,
    this.inactiveColor,
    this.dotSize = 8.0,
    this.activeWidthMultiplier = 3.0,
  }) : assert(totalPages > 0),
       assert(currentPage >= 0 && currentPage < totalPages);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final active = activeColor ?? colorScheme.primary;
    final inactive = inactiveColor ?? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (index) {
        final isActive = index == currentPage;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          height: dotSize,
          width: isActive ? dotSize * activeWidthMultiplier : dotSize,
          decoration: BoxDecoration(
            color: isActive ? active : inactive,
            borderRadius: BorderRadius.circular(dotSize / 2),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: active.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
        );
      }),
    );
  }
}
