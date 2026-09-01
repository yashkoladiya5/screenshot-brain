import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbBouncingTypingIndicator extends StatefulWidget {
  final Color bubbleColor;
  final Color dotColor;
  final double bubbleWidth;
  final double bubbleHeight;

  const SbBouncingTypingIndicator({
    super.key,
    this.bubbleColor = const Color(0xFFE5E5EA),
    this.dotColor = const Color(0xFF8E8E93),
    this.bubbleWidth = 70.0,
    this.bubbleHeight = 40.0,
  });

  @override
  State<SbBouncingTypingIndicator> createState() => _SbBouncingTypingIndicatorState();
}

class _SbBouncingTypingIndicatorState extends State<SbBouncingTypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.bubbleWidth,
      height: widget.bubbleHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: widget.bubbleWidth,
            height: widget.bubbleHeight,
            decoration: BoxDecoration(
              color: widget.bubbleColor,
              borderRadius: BorderRadius.circular(widget.bubbleHeight / 2),
            ),
          ),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDot(0),
              const SizedBox(width: 4),
              _buildDot(1),
              const SizedBox(width: 4),
              _buildDot(2),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    final double phaseOffset = index * (math.pi / 4);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double animationValue = (_controller.value * 2 * math.pi) - phaseOffset;
        
        final double yOffset = math.sin(animationValue) * -4.0;
        
        final double opacity = 0.4 + ((math.sin(animationValue) + 1) / 2) * 0.6; 

        return Transform.translate(
          offset: Offset(0, yOffset),
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: widget.dotColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}
