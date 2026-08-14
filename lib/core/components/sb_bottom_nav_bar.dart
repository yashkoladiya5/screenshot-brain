import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbBottomNavBarItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const SbBottomNavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class SbBottomNavBar extends StatelessWidget {
  final List<SbBottomNavBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const SbBottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: SBSpacing.sm, vertical: SBSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = index == currentIndex;

              return GestureDetector(
                onTap: () => onTap(index),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(horizontal: SBSpacing.lg, vertical: SBSpacing.sm),
                  decoration: BoxDecoration(
                    color: isSelected ? colorScheme.primaryContainer.withValues(alpha: 0.5) : Colors.transparent,
                    borderRadius: BorderRadius.circular(SBRadius.full),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? item.activeIcon : item.icon,
                        color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: SBSpacing.xs),
                        Text(
                          item.label,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
