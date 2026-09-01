import 'package:flutter/material.dart';

class SbRippleRingButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Color rippleColor;
  final double size;
  final int rippleCount;

  const SbRippleRingButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.rippleColor = Colors.blueAccent,
    this.size = 80.0,
    this.rippleCount = 3,
  });

  @override
  State<SbRippleRingButton> createState() => _SbRippleRingButtonState();
}

class _SbRippleRingButtonState extends State<SbRippleRingButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      child: SizedBox(
        width: widget.size * 2, // Extra space for ripples to expand
        height: widget.size * 2,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Generate multiple ripple rings
            ...List.generate(widget.rippleCount, (index) {
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  // Phase shift each ripple so they don't overlap perfectly
                  final double delay = index / widget.rippleCount;
                  double progress = _controller.value - delay;
                  
                  // Keep progress between 0.0 and 1.0
                  if (progress < 0) {
                    progress += 1.0;
                  }

                  // Ripple grows in size
                  final double scale = 1.0 + (progress * 1.5);
                  // Ripple fades out as it grows
                  final double opacity = 1.0 - progress;

                  return Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: opacity.clamp(0.0, 1.0),
                      child: Container(
                        width: widget.size,
                        height: widget.size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.rippleColor,
                            width: 2.0, // Fixed width border expands outwards
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
            
            // The actual core button
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.rippleColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.rippleColor.withValues(alpha: 0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ]
              ),
              child: Center(child: widget.child),
            ),
          ],
        ),
      ),
    );
  }
}
