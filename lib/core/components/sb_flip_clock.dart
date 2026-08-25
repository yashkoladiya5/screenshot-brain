import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../design/tokens.dart';

class SbFlipClockDigit extends StatefulWidget {
  final int value;
  final TextStyle? textStyle;
  final Color? backgroundColor;

  const SbFlipClockDigit({
    super.key,
    required this.value,
    this.textStyle,
    this.backgroundColor,
  }) : assert(value >= 0 && value <= 9);

  @override
  State<SbFlipClockDigit> createState() => _SbFlipClockDigitState();
}

class _SbFlipClockDigitState extends State<SbFlipClockDigit> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _previousValue = 0;
  int _currentValue = 0;

  @override
  void initState() {
    super.initState();
    _previousValue = widget.value;
    _currentValue = widget.value;
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _animation = Tween<double>(begin: 0, end: math.pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(SbFlipClockDigit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _previousValue = oldWidget.value;
      _currentValue = widget.value;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final bg = widget.backgroundColor ?? colorScheme.surfaceContainerHighest;
    final style = widget.textStyle ?? theme.textTheme.displayMedium?.copyWith(
      fontWeight: FontWeight.w900,
      color: colorScheme.onSurface,
    );

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final isFlippedHalfway = _animation.value >= math.pi / 2;
        
        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(SBRadius.sm),
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(SBRadius.sm),
            child: Stack(
              children: [
                // Background static full digit (shows the new value)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  child: Text(_currentValue.toString(), style: style),
                ),
                
                // Top Half (Static Previous Value)
                ClipRect(
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: 0.5,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                      child: Text(_previousValue.toString(), style: style),
                    ),
                  ),
                ),
                
                // Bottom Half (Static New Value)
                ClipRect(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    heightFactor: 0.5,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                      child: Text(_currentValue.toString(), style: style),
                    ),
                  ),
                ),

                // Flap (Animated)
                Positioned.fill(
                  child: Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.002) // Perspective
                      ..rotateX(isFlippedHalfway ? _animation.value - math.pi : _animation.value),
                    alignment: isFlippedHalfway ? Alignment.bottomCenter : Alignment.topCenter,
                    child: ClipRect(
                      child: Align(
                        alignment: isFlippedHalfway ? Alignment.bottomCenter : Alignment.topCenter,
                        heightFactor: 0.5,
                        child: Container(
                          color: bg,
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                          child: Text(
                            isFlippedHalfway ? _currentValue.toString() : _previousValue.toString(),
                            style: style,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Horizontal divider line
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      height: 2,
                      color: colorScheme.surface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
