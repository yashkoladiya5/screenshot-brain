import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbFoldableMenu extends StatefulWidget {
  final Widget header;
  final List<Widget> children;
  final double itemHeight;
  final Color baseColor;

  const SbFoldableMenu({
    super.key,
    required this.header,
    required this.children,
    this.itemHeight = 60.0,
    this.baseColor = const Color(0xFF2C2C2E),
  });

  @override
  State<SbFoldableMenu> createState() => _SbFoldableMenuState();
}

class _SbFoldableMenuState extends State<SbFoldableMenu> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isOpen = !_isOpen;
    });
    if (_isOpen) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The Header that you tap to open/close
        GestureDetector(
          onTap: _toggleMenu,
          child: Container(
            height: widget.itemHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              color: widget.baseColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft: Radius.circular(_isOpen ? 0 : 12),
                bottomRight: Radius.circular(_isOpen ? 0 : 12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  offset: const Offset(0, 4),
                  blurRadius: 8,
                )
              ]
            ),
            child: widget.header,
          ),
        ),
        
        // The 3D Foldable Children
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(widget.children.length, (index) {
                // Calculate animation phase for this specific item
                // Items fold down sequentially (cascade effect)
                final double start = (index / widget.children.length) * 0.5;
                final double end = start + 0.5;
                
                final Animation<double> foldAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _controller,
                    curve: Interval(start, end, curve: Curves.easeOutCubic),
                  )
                );
                
                // When 0.0, it is folded up (-90 degrees). When 1.0, it is flat (0 degrees).
                final double rotationAngle = (1.0 - foldAnimation.value) * (math.pi / -2);
                
                // Determine if this is the last item for border radius
                final bool isLast = index == widget.children.length - 1;

                return Align(
                  alignment: Alignment.topCenter,
                  // Height factor naturally clips/hides the item as it folds up
                  heightFactor: foldAnimation.value,
                  child: Transform(
                    alignment: Alignment.topCenter,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001) // 3D Perspective
                      ..rotateX(rotationAngle),
                    child: Opacity(
                      opacity: (foldAnimation.value * 1.5).clamp(0.0, 1.0),
                      child: Container(
                        height: widget.itemHeight,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: widget.baseColor.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(isLast ? 12 : 0),
                            bottomRight: Radius.circular(isLast ? 12 : 0),
                          ),
                          border: Border(
                            top: BorderSide(
                              color: Colors.white.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          )
                        ),
                        child: widget.children[index],
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }
}
