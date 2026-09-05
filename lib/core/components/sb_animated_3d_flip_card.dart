import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbAnimated3DFlipCard extends StatefulWidget {
  final Widget front;
  final Widget back;
  final double width;
  final double height;
  final Duration duration;
  final bool isHorizontal; 

  const SbAnimated3DFlipCard({
    super.key,
    required this.front,
    required this.back,
    this.width = 300.0,
    this.height = 400.0,
    this.duration = const Duration(milliseconds: 600),
    this.isHorizontal = true,
  });

  @override
  State<SbAnimated3DFlipCard> createState() => _SbAnimated3DFlipCardState();
}

class _SbAnimated3DFlipCardState extends State<SbAnimated3DFlipCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleCard() {
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    _isFront = !_isFront;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleCard,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final double rotationValue = _controller.value * math.pi;
          
          final bool isUnderThreshold = rotationValue < (math.pi / 2);

          final double curvedRotation = Curves.easeInOutBack.transform(_controller.value) * math.pi;

          return SizedBox(
            width: widget.width,
            height: widget.height,
            child: Transform(
              alignment: FractionalOffset.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0015) 
                ..rotateX(widget.isHorizontal ? 0 : curvedRotation)
                ..rotateY(widget.isHorizontal ? curvedRotation : 0),
              child: isUnderThreshold
                  ? widget.front 
                  : Transform(
                      alignment: FractionalOffset.center,
                      transform: Matrix4.identity()
                        ..rotateX(widget.isHorizontal ? 0 : math.pi)
                        ..rotateY(widget.isHorizontal ? math.pi : 0),
                      child: widget.back,
                    ),
            ),
          );
        },
      ),
    );
  }
}
