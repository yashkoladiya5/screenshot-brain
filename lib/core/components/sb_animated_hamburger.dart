import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbAnimatedHamburger extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onPressed;
  final Color color;
  final double size;
  final Duration duration;

  const SbAnimatedHamburger({
    super.key,
    required this.isOpen,
    required this.onPressed,
    this.color = Colors.black87,
    this.size = 24.0,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<SbAnimatedHamburger> createState() => _SbAnimatedHamburgerState();
}

class _SbAnimatedHamburgerState extends State<SbAnimatedHamburger> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: widget.isOpen ? 1.0 : 0.0,
    );
  }

  @override
  void didUpdateWidget(SbAnimatedHamburger oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen != oldWidget.isOpen) {
      if (widget.isOpen) {
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
    final double strokeWidth = widget.size / 10;
    
    return GestureDetector(
      onTap: widget.onPressed,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final double progress = Curves.easeInOutCubic.transform(_controller.value);
            
            return Stack(
              alignment: Alignment.center,
              children: [
                // Top Bar (Rotates down to form \ of X)
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..translate(
                      0.0,
                      // Move down to center
                      (widget.size / 3) * progress,
                    )
                    ..rotateZ(progress * math.pi / 4),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      height: strokeWidth,
                      width: widget.size,
                      decoration: BoxDecoration(
                        color: widget.color,
                        borderRadius: BorderRadius.circular(strokeWidth / 2),
                      ),
                    ),
                  ),
                ),
                
                // Middle Bar (Fades out and scales down)
                Transform.scale(
                  scale: 1.0 - progress,
                  child: Opacity(
                    opacity: 1.0 - progress,
                    child: Align(
                      alignment: Alignment.center,
                      child: Container(
                        height: strokeWidth,
                        width: widget.size,
                        decoration: BoxDecoration(
                          color: widget.color,
                          borderRadius: BorderRadius.circular(strokeWidth / 2),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Bottom Bar (Rotates up to form / of X)
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..translate(
                      0.0,
                      // Move up to center
                      -(widget.size / 3) * progress,
                    )
                    ..rotateZ(-progress * math.pi / 4),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: strokeWidth,
                      width: widget.size,
                      decoration: BoxDecoration(
                        color: widget.color,
                        borderRadius: BorderRadius.circular(strokeWidth / 2),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
