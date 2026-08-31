import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbFoldingTicket extends StatefulWidget {
  final Widget topHalf;
  final Widget bottomHalf;
  final Widget innerTop;
  final Widget innerBottom;
  final double width;
  final double height;

  const SbFoldingTicket({
    super.key,
    required this.topHalf,
    required this.bottomHalf,
    required this.innerTop,
    required this.innerBottom,
    this.width = 300,
    this.height = 400,
  });

  @override
  State<SbFoldingTicket> createState() => _SbFoldingTicketState();
}

class _SbFoldingTicketState extends State<SbFoldingTicket> with SingleTickerProviderStateMixin {
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

  void _toggle() {
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
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // The rotation goes from 0 to 180 degrees (pi radians)
          final angle = _controller.value * math.pi;
          
          return SizedBox(
            width: widget.width,
            height: widget.height,
            child: Stack(
              children: [
                // 1. The Bottom Inner Content (Always stationary at the bottom)
                Positioned(
                  top: widget.height / 2,
                  left: 0,
                  right: 0,
                  height: widget.height / 2,
                  child: widget.innerBottom,
                ),
                
                // 2. The Top Inner Content (Always stationary at the top)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: widget.height / 2,
                  child: widget.innerTop,
                ),
                
                // 3. The Top Cover (Stationary)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: widget.height / 2,
                  child: widget.topHalf,
                ),

                // 4. The Bottom Cover (This folds up!)
                // We anchor the transform at the top of this half (which is the middle of the ticket)
                Positioned(
                  top: widget.height / 2,
                  left: 0,
                  right: 0,
                  height: widget.height / 2,
                  child: Transform(
                    alignment: Alignment.topCenter,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.002) // Perspective
                      ..rotateX(-angle), // Rotate upwards
                    child: angle > math.pi / 2
                      ? const SizedBox.shrink() // Hide when folded past 90 degrees so we can see inside
                      : widget.bottomHalf,
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
