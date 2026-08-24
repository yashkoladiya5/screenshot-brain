import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbReorderableListWrapper extends StatefulWidget {
  final List<Widget> children;
  final void Function(int oldIndex, int newIndex) onReorder;
  final bool buildDefaultDragHandles;
  final Color? dragIndicatorColor;

  const SbReorderableListWrapper({
    super.key,
    required this.children,
    required this.onReorder,
    this.buildDefaultDragHandles = true,
    this.dragIndicatorColor,
  });

  @override
  State<SbReorderableListWrapper> createState() => _SbReorderableListWrapperState();
}

class _SbReorderableListWrapperState extends State<SbReorderableListWrapper> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final dragColor = widget.dragIndicatorColor ?? colorScheme.primary.withValues(alpha: 0.15);

    return ReorderableListView(
      buildDefaultDragHandles: widget.buildDefaultDragHandles,
      physics: const BouncingScrollPhysics(),
      proxyDecorator: (Widget child, int index, Animation<double> animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (BuildContext context, Widget? child) {
            final double animValue = Curves.easeInOut.transform(animation.value);
            final double elevation = Tween<double>(begin: 0, end: 12).evaluate(animation);
            
            return Material(
              elevation: elevation,
              color: Colors.transparent,
              shadowColor: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(SBRadius.md),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(SBRadius.md),
                  boxShadow: [
                    BoxShadow(
                      color: dragColor,
                      blurRadius: 10 * animValue,
                      spreadRadius: 2 * animValue,
                    ),
                  ],
                ),
                child: Transform.scale(
                  scale: 1.0 + (0.02 * animValue),
                  child: child,
                ),
              ),
            );
          },
          child: child,
        );
      },
      onReorder: widget.onReorder,
      children: widget.children.map((child) {
        // Wrap child to provide margins if needed, or just return child.
        // Assuming children have UniqueKeys as required by ReorderableListView
        return Padding(
          key: child.key ?? UniqueKey(),
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: child,
        );
      }).toList(),
    );
  }
}
