import 'package:flutter/material.dart';

class SbPillBadge extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final bool isPulsing;

  const SbPillBadge({
    super.key,
    required this.text,
    this.backgroundColor = Colors.red,
    this.textColor = Colors.white,
    this.isPulsing = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    if (isPulsing) {
      return _PulsingWrapper(child: badge);
    }
    return badge;
  }
}

class _PulsingWrapper extends StatefulWidget {
  final Widget child;
  const _PulsingWrapper({required this.child});

  @override
  State<_PulsingWrapper> createState() => _PulsingWrapperState();
}

class _PulsingWrapperState extends State<_PulsingWrapper> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: widget.child,
    );
  }
}
