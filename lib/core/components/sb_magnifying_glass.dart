import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class SbMagnifyingGlass extends StatefulWidget {
  final Widget child;
  final double radius;
  final double magnificationScale;
  final Color borderColor;
  final double borderWidth;

  const SbMagnifyingGlass({
    super.key,
    required this.child,
    this.radius = 60.0,
    this.magnificationScale = 2.0,
    this.borderColor = Colors.white,
    this.borderWidth = 3.0,
  });

  @override
  State<SbMagnifyingGlass> createState() => _SbMagnifyingGlassState();
}

class _SbMagnifyingGlassState extends State<SbMagnifyingGlass> {
  Offset? _magnifierPosition;
  bool _isMagnifying = false;

  void _updatePosition(Offset globalPosition) {
    // We need to convert global position to local position within this widget
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(globalPosition);
    
    // Constrain to bounds
    final size = renderBox.size;
    if (localPosition.dx < 0 || localPosition.dx > size.width || 
        localPosition.dy < 0 || localPosition.dy > size.height) {
      setState(() {
        _isMagnifying = false;
      });
      return;
    }

    setState(() {
      _isMagnifying = true;
      _magnifierPosition = localPosition;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanDown: (details) => _updatePosition(details.globalPosition),
      onPanUpdate: (details) => _updatePosition(details.globalPosition),
      onPanEnd: (_) => setState(() => _isMagnifying = false),
      onPanCancel: () => setState(() => _isMagnifying = false),
      child: Stack(
        children: [
          // 1. Base content
          widget.child,
          
          // 2. Magnifying Glass
          if (_isMagnifying && _magnifierPosition != null)
            Positioned(
              left: _magnifierPosition!.dx - widget.radius,
              top: _magnifierPosition!.dy - widget.radius,
              child: IgnorePointer(
                child: Container(
                  width: widget.radius * 2,
                  height: widget.radius * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.borderColor,
                      width: widget.borderWidth,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: ClipOval(
                    child: BackdropFilter(
                      // The ImageFilter.matrix applies the magnification transformation
                      filter: ui.ImageFilter.matrix(
                        Matrix4.identity()
                          // Move origin to center of magnifier to scale from center
                          ..translate(_magnifierPosition!.dx, _magnifierPosition!.dy)
                          ..scale(widget.magnificationScale)
                          ..translate(-_magnifierPosition!.dx, -_magnifierPosition!.dy)
                          .storage,
                      ),
                      child: Container(
                        color: Colors.transparent, // Required to make BackdropFilter work
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
