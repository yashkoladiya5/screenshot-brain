import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../design/tokens.dart';

class Sb3DFlipCard extends StatefulWidget {
  final Widget front;
  final Widget back;
  final double width;
  final double height;
  final Duration duration;

  const Sb3DFlipCard({
    super.key,
    required this.front,
    required this.back,
    this.width = 300.0,
    this.height = 200.0,
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  State<Sb3DFlipCard> createState() => _Sb3DFlipCardState();
}

class _Sb3DFlipCardState extends State<Sb3DFlipCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack)
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    setState(() {
      _isFront = !_isFront;
    });
    if (_isFront) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final double value = _animation.value;
            // Angle in radians (0 to Pi)
            final double angle = value * math.pi;

            // Are we past the halfway point (90 degrees)?
            final bool showBack = angle > (math.pi / 2);

            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001) // perspective
                ..rotateY(angle),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(SBRadius.md),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(SBRadius.md),
                  child: showBack
                      ? Transform(
                          // When showing the back, we need to flip it horizontally again
                          // so the content isn't mirrored!
                          alignment: Alignment.center,
                          transform: Matrix4.rotationY(math.pi),
                          child: widget.back,
                        )
                      : widget.front,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
