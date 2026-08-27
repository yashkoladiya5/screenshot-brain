import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design/tokens.dart';

class SbBouncingDockItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const SbBouncingDockItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });
}

class SbBouncingDock extends StatefulWidget {
  final List<SbBouncingDockItem> items;
  final double baseSize;
  final double expandedSize;
  final Color? backgroundColor;

  const SbBouncingDock({
    super.key,
    required this.items,
    this.baseSize = 50.0,
    this.expandedSize = 80.0,
    this.backgroundColor,
  }) : assert(items.length > 0);

  @override
  State<SbBouncingDock> createState() => _SbBouncingDockState();
}

class _SbBouncingDockState extends State<SbBouncingDock> {
  int? _hoveredIndex;
  // We use this to smoothly interpolate the sizes of adjacent icons
  double _mouseX = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = widget.backgroundColor ?? theme.colorScheme.surface.withValues(alpha: 0.8);

    return MouseRegion(
      onHover: (event) {
        setState(() {
          _mouseX = event.localPosition.dx;
        });
      },
      onExit: (_) {
        setState(() {
          _hoveredIndex = null;
          _mouseX = -1;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: SBSpacing.md, vertical: SBSpacing.sm),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(SBRadius.full),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        // Measure total width to calculate relative mouse position accurately
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(widget.items.length, (index) {
            final item = widget.items[index];
            
            // Calculate size based on mouse proximity
            double targetSize = widget.baseSize;
            
            if (_mouseX >= 0) {
              // Estimate the center X of this specific icon based on base sizes
              // This is a rough estimation assuming icons are evenly spaced
              final double iconCenterX = (index * widget.baseSize) + (widget.baseSize / 2) + (index * 8); // +8 for padding
              final double distance = (_mouseX - iconCenterX).abs();
              
              // If within influence radius, scale up
              final double influenceRadius = widget.baseSize * 1.5;
              if (distance < influenceRadius) {
                // Map distance to a scale factor (closer = bigger)
                final double factor = 1 - (distance / influenceRadius);
                targetSize = widget.baseSize + ((widget.expandedSize - widget.baseSize) * factor);
              }
            }

            return MouseRegion(
              onEnter: (_) => setState(() => _hoveredIndex = index),
              child: GestureDetector(
                onTap: item.onTap,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: widget.baseSize, end: targetSize),
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOutCubic,
                  builder: (context, size, child) {
                    final bool isHovered = _hoveredIndex == index;
                    
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Tooltip (only shows when exactly hovered)
                          AnimatedOpacity(
                            opacity: isHovered ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 150),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8.0),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(SBRadius.sm),
                              ),
                              child: Text(
                                item.label,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.surface,
                                ),
                              ),
                            ),
                          ),
                          
                          // Icon Container
                          Container(
                            width: size,
                            height: size,
                            decoration: BoxDecoration(
                              color: item.color ?? theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(SBRadius.xl),
                              boxShadow: [
                                if (size > widget.baseSize)
                                  BoxShadow(
                                    color: (item.color ?? theme.colorScheme.primaryContainer).withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 4),
                                  )
                              ],
                            ),
                            child: Icon(
                              item.icon,
                              size: size * 0.5,
                              color: item.color != null ? Colors.white : theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
