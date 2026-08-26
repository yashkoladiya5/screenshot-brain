import 'package:flutter/material.dart';
import 'dart:math' as math;

enum SbFlipDirection { horizontal, vertical }

class SbFlipCard extends StatefulWidget {
  final Widget front;
  final Widget back;
  final Duration duration;
  final SbFlipDirection direction;
  final bool initialIsFront;

  const SbFlipCard({
    super.key,
    required this.front,
    required this.back,
    this.duration = const Duration(milliseconds: 600),
    this.direction = SbFlipDirection.horizontal,
    this.initialIsFront = true,
  });

  @override
  State<SbFlipCard> createState() => _SbFlipCardState();
}

class _SbFlipCardState extends State<SbFlipCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late bool _isFront;

  @override
  void initState() {
    super.initState();
    _isFront = widget.initialIsFront;
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    
    if (!_isFront) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void flip() {
    setState(() {
      _isFront = !_isFront;
      if (_isFront) {
        _controller.reverse();
      } else {
        _controller.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: flip,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final isUnder = _animation.value > 0.5;
          final angle = _animation.value * math.pi;
          
          final frontMatrix = Matrix4.identity()..setEntry(3, 2, 0.001);
          final backMatrix = Matrix4.identity()..setEntry(3, 2, 0.001);

          if (widget.direction == SbFlipDirection.horizontal) {
            frontMatrix.rotateY(angle);
            backMatrix.rotateY(angle + math.pi);
          } else {
            frontMatrix.rotateX(angle);
            backMatrix.rotateX(angle + math.pi);
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              if (!isUnder)
                Transform(
                  transform: frontMatrix,
                  alignment: Alignment.center,
                  child: widget.front,
                ),
              if (isUnder)
                Transform(
                  transform: backMatrix,
                  alignment: Alignment.center,
                  child: widget.back,
                ),
            ],
          );
        },
      ),
    );
  }
}
