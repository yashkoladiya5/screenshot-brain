import 'package:flutter/material.dart';

class SbAnimatedIcon extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final Color? color;
  final double? size;
  final Duration duration;
  final Curve curve;

  const SbAnimatedIcon({
    super.key,
    required this.icon,
    required this.isSelected,
    this.color,
    this.size,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOutBack,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: curve,
      switchOutCurve: curve,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return ScaleTransition(
          scale: animation,
          child: child,
        );
      },
      child: Icon(
        icon,
        key: ValueKey<bool>(isSelected), // Triggers the AnimatedSwitcher
        color: color,
        size: size,
      ),
    );
  }
}
