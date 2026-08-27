import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbElasticToggle extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;
  final Color inactiveColor;
  final double width;
  final double height;

  const SbElasticToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor = Colors.greenAccent,
    this.inactiveColor = Colors.grey,
    this.width = 60.0,
    this.height = 32.0,
  });

  @override
  State<SbElasticToggle> createState() => _SbElasticToggleState();
}

class _SbElasticToggleState extends State<SbElasticToggle> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isDragging = false;
  double _dragOffset = 0.0;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      value: widget.value ? 1.0 : 0.0,
    );
  }

  @override
  void didUpdateWidget(SbElasticToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && !_isDragging) {
      if (widget.value) {
        _controller.animateTo(1.0, curve: Curves.elasticOut);
      } else {
        _controller.animateTo(0.0, curve: Curves.elasticOut);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    // Calculate movement percentage based on track width
    final double trackWidth = widget.width - widget.height; // Max travel distance
    final double delta = details.delta.dx / trackWidth;
    
    _controller.value = (_controller.value + delta).clamp(0.0, 1.0);
    
    // Calculate extra stretch if pulling past boundaries
    if (_controller.value == 0.0 && details.delta.dx < 0) {
      _dragOffset += details.delta.dx;
    } else if (_controller.value == 1.0 && details.delta.dx > 0) {
      _dragOffset += details.delta.dx;
    } else {
      _dragOffset = 0.0;
    }
    
    setState(() {});
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
      _dragOffset = 0.0;
    });
    
    // Snap to nearest side based on velocity or position
    final bool shouldBeActive = details.velocity.pixelsPerSecond.dx > 500 || 
                               (details.velocity.pixelsPerSecond.dx > -500 && _controller.value > 0.5);
    
    if (shouldBeActive != widget.value) {
      widget.onChanged(shouldBeActive);
    } else {
      // Animate back to current state
      if (widget.value) {
        _controller.animateTo(1.0, curve: Curves.elasticOut);
      } else {
        _controller.animateTo(0.0, curve: Curves.elasticOut);
      }
    }
  }

  void _toggle() {
    widget.onChanged(!widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final double padding = 2.0;
    final double thumbSize = widget.height - (padding * 2);
    final double trackTravel = widget.width - widget.height;

    return GestureDetector(
      onTap: _toggle,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onPanCancel: () => _onPanEnd(DragEndDetails()),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Color interpolation
          final Color? currentColor = Color.lerp(
            widget.inactiveColor, 
            widget.activeColor, 
            _controller.value
          );

          // Position calculation
          final double thumbPos = _controller.value * trackTravel;
          
          // Elastic deformation logic
          // When dragged past the edges, the thumb squishes and stretches
          double thumbWidth = thumbSize;
          double extraOffset = 0.0;
          
          if (_dragOffset < 0) {
            // Dragging left past 0
            final double stretch = (_dragOffset.abs() * 0.5).clamp(0.0, thumbSize * 0.5);
            thumbWidth = thumbSize + stretch;
          } else if (_dragOffset > 0) {
            // Dragging right past 1
            final double stretch = (_dragOffset * 0.5).clamp(0.0, thumbSize * 0.5);
            thumbWidth = thumbSize + stretch;
            extraOffset = -stretch; // Shift left so right edge stays at cursor
          }

          // If animating quickly between states, stretch the thumb slightly
          if (!_isDragging && _controller.isAnimating) {
            final double velocity = _controller.velocity.abs();
            if (velocity > 0) {
              // Peak stretch in the middle of the animation
              final double stretchFactor = 1.0 - (2 * (_controller.value - 0.5)).abs();
              thumbWidth = thumbSize + (stretchFactor * thumbSize * 0.4);
              if (_controller.velocity > 0) {
                // Moving right, grow towards left
                extraOffset = -(thumbWidth - thumbSize) / 2;
              } else {
                 // Moving left, grow towards right
                 extraOffset = -(thumbWidth - thumbSize) / 2;
              }
            }
          }

          return Container(
            width: widget.width,
            height: widget.height,
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: currentColor,
              borderRadius: BorderRadius.circular(widget.height / 2),
              boxShadow: [
                BoxShadow(
                  color: (currentColor ?? Colors.black).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Stack(
              children: [
                // Thumb
                Positioned(
                  left: thumbPos + extraOffset,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: thumbWidth,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(thumbSize / 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
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
