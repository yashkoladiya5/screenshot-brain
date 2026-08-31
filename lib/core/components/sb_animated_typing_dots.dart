import 'package:flutter/material.dart';

class SbAnimatedTypingDots extends StatefulWidget {
  final Color dotColor;
  final double dotSize;
  final Duration animationDuration;

  const SbAnimatedTypingDots({
    super.key,
    this.dotColor = Colors.grey,
    this.dotSize = 8.0,
    this.animationDuration = const Duration(milliseconds: 1000),
  });

  @override
  State<SbAnimatedTypingDots> createState() => _SbAnimatedTypingDotsState();
}

class _SbAnimatedTypingDotsState extends State<SbAnimatedTypingDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _dot1Animation;
  late Animation<double> _dot2Animation;
  late Animation<double> _dot3Animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    )..repeat();

    _dot1Animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeInOutSine),
      ),
    );

    _dot2Animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.6, curve: Curves.easeInOutSine),
      ),
    );

    _dot3Animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.8, curve: Curves.easeInOutSine),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildDot(Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        double value = animation.value;
        double displacement = 0;
        
        if (value > 0 && value < 0.5) {
          displacement = (value * 2) * -10.0;
        } else if (value >= 0.5 && value < 1.0) {
          displacement = ((1.0 - value) * 2) * -10.0;
        }

        return Transform.translate(
          offset: Offset(0, displacement),
          child: Container(
            width: widget.dotSize,
            height: widget.dotSize,
            decoration: BoxDecoration(
              color: widget.dotColor,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDot(_dot1Animation),
          const SizedBox(width: 6),
          _buildDot(_dot2Animation),
          const SizedBox(width: 6),
          _buildDot(_dot3Animation),
        ],
      ),
    );
  }
}
