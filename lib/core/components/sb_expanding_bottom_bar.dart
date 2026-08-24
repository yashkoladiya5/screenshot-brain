import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbExpandingBottomBarItem {
  final IconData icon;
  final String label;
  final Color activeColor;

  const SbExpandingBottomBarItem({
    required this.icon,
    required this.label,
    required this.activeColor,
  });
}

class SbExpandingBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onItemSelected;
  final List<SbExpandingBottomBarItem> items;
  final Color? backgroundColor;

  const SbExpandingBottomBar({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
    required this.items,
    this.backgroundColor,
  }) : assert(items.length >= 2 && items.length <= 5);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final bg = backgroundColor ?? colorScheme.surface;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, -5),
          )
        ],
      ),
      padding: EdgeInsets.only(
        top: SBSpacing.sm,
        bottom: bottomPadding > 0 ? bottomPadding : SBSpacing.md,
        left: SBSpacing.md,
        right: SBSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isSelected = index == currentIndex;

          return GestureDetector(
            onTap: () => onItemSelected(index),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutQuint,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: isSelected ? item.activeColor.withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(SBRadius.full),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.icon,
                    color: isSelected ? item.activeColor : colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutQuint,
                    child: SizedBox(
                      width: isSelected ? null : 0,
                      child: Padding(
                        padding: EdgeInsets.only(left: isSelected ? 8.0 : 0.0),
                        child: Text(
                          item.label,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: item.activeColor,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
