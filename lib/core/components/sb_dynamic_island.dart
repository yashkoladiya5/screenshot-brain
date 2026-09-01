import 'package:flutter/material.dart';

class SbDynamicIsland extends StatefulWidget {
  final bool isExpanded;
  final Widget collapsedChild;
  final Widget expandedChild;
  final VoidCallback? onTap;

  const SbDynamicIsland({
    super.key,
    required this.isExpanded,
    required this.collapsedChild,
    required this.expandedChild,
    this.onTap,
  });

  @override
  State<SbDynamicIsland> createState() => _SbDynamicIslandState();
}

class _SbDynamicIslandState extends State<SbDynamicIsland> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      value: widget.isExpanded ? 1.0 : 0.0,
    );
  }

  @override
  void didUpdateWidget(SbDynamicIsland oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final double progress = Curves.elasticOut.transform(_controller.value);
          
          // Width goes from small pill (120) to wide card (340)
          final double width = 120.0 + (220.0 * progress);
          // Height goes from small pill (35) to tall card (160)
          final double height = 35.0 + (125.0 * progress);
          // Border radius goes from full pill (20) to rounded rect (40)
          final double borderRadius = 20.0 + (20.0 * progress);

          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Collapsed State (Fades out quickly)
                Opacity(
                  opacity: (1.0 - (_controller.value * 3)).clamp(0.0, 1.0),
                  child: IgnorePointer(
                    ignoring: widget.isExpanded,
                    child: widget.collapsedChild,
                  ),
                ),
                
                // Expanded State (Fades in later)
                Opacity(
                  opacity: ((_controller.value - 0.3) * 1.5).clamp(0.0, 1.0),
                  child: IgnorePointer(
                    ignoring: !widget.isExpanded,
                    child: widget.expandedChild,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
