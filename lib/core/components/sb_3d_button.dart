import 'package:flutter/material.dart';
import '../design/tokens.dart';

class Sb3dButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color color;
  final Color shadowColor;
  final double height;
  final double width;
  final double borderRadius;
  final double depth;

  const Sb3dButton({
    super.key,
    required this.onPressed,
    required this.child,
    required this.color,
    required this.shadowColor,
    this.height = 56.0,
    this.width = double.infinity,
    this.borderRadius = SBRadius.md,
    this.depth = 6.0,
  });

  @override
  State<Sb3dButton> createState() => _Sb3dButtonState();
}

class _Sb3dButtonState extends State<Sb3dButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isPressed = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          _isPressed = false;
        });
        widget.onPressed();
      },
      onTapCancel: () {
        setState(() {
          _isPressed = false;
        });
      },
      child: SizedBox(
        width: widget.width,
        height: widget.height + widget.depth,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Shadow / Base Layer
            Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                color: widget.shadowColor,
                borderRadius: BorderRadius.circular(widget.borderRadius),
              ),
            ),
            
            // Top layer that moves down
            AnimatedPositioned(
              duration: const Duration(milliseconds: 50),
              bottom: _isPressed ? 0 : widget.depth,
              left: 0,
              right: 0,
              child: Container(
                height: widget.height,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                ),
                child: Center(child: widget.child),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
