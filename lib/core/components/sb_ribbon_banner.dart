import 'package:flutter/material.dart';

class SbRibbonBanner extends StatelessWidget {
  final Widget child;
  final String text;
  final Color color;
  final Color textColor;

  const SbRibbonBanner({
    super.key,
    required this.child,
    required this.text,
    this.color = Colors.red,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        children: [
          child,
          Positioned(
            top: 20,
            right: -30,
            child: Transform.rotate(
              angle: 0.785398, // 45 degrees in radians
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 4),
                color: color,
                child: Text(
                  text.toUpperCase(),
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
