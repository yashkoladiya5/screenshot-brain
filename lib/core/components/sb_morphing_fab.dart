import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../design/tokens.dart';

class SbMorphingFab extends StatefulWidget {
  final Widget openIcon;
  final Widget closeIcon;
  final List<Widget> children;
  final Color primaryColor;
  final Color secondaryColor;
  final double fabSize;

  const SbMorphingFab({
    super.key,
    this.openIcon = const Icon(Icons.add, color: Colors.white),
    this.closeIcon = const Icon(Icons.close, color: Colors.white),
    required this.children,
    this.primaryColor = Colors.blueAccent,
    this.secondaryColor = Colors.redAccent,
    this.fabSize = 56.0,
  });

  @override
  State<SbMorphingFab> createState() => _SbMorphingFabState();
}

class _SbMorphingFabState extends State<SbMorphingFab> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
    });
    if (_isOpen) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine the total size needed when expanded
    // We assume vertical expansion upwards for a standard FAB layout
    final double expandedHeight = widget.fabSize + (widget.children.length * (widget.fabSize + 16.0));

    return SizedBox(
      width: widget.fabSize,
      height: expandedHeight, // Fixed height to allow stack positioning without layout shifts
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // 1. The morphing background pill/container
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              // Morph from a circle (fabSize x fabSize) to a tall rounded rectangle
              final double currentHeight = widget.fabSize + (_controller.value * (expandedHeight - widget.fabSize));
              // Color morphs from primary to secondary
              final Color? currentColor = Color.lerp(widget.primaryColor, widget.secondaryColor, _controller.value);
              
              return Container(
                width: widget.fabSize,
                height: currentHeight,
                decoration: BoxDecoration(
                  color: currentColor,
                  borderRadius: BorderRadius.circular(widget.fabSize / 2),
                  boxShadow: [
                    BoxShadow(
                      color: (currentColor ?? Colors.black).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
              );
            },
          ),

          // 2. The Children (MenuItems)
          // Positioned absolutely within the stack so they don't affect layout
          ...List.generate(widget.children.length, (index) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                // Staggered entrance animation
                final double start = (index / widget.children.length) * 0.5;
                final double end = start + 0.5;
                
                final CurvedAnimation curve = CurvedAnimation(
                  parent: _controller,
                  curve: Interval(start, end, curve: Curves.easeOutBack),
                );

                // Calculate the final Y position for this item
                // Bottom is 0, so higher index goes higher up
                final double targetBottom = widget.fabSize + 16.0 + (index * (widget.fabSize * 0.8 + 16.0));
                final double currentBottom = curve.value * targetBottom;

                return Positioned(
                  bottom: currentBottom,
                  child: Transform.scale(
                    scale: curve.value.clamp(0.0, 1.0), // Scale up as it appears
                    child: Opacity(
                      opacity: curve.value.clamp(0.0, 1.0),
                      child: SizedBox(
                        width: widget.fabSize,
                        height: widget.fabSize * 0.8, // Slightly smaller than FAB
                        child: Center(
                          child: widget.children[index],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),

          // 3. The Main Toggle Button (Stays at the bottom)
          Positioned(
            bottom: 0,
            child: GestureDetector(
              onTap: _toggle,
              child: Container(
                width: widget.fabSize,
                height: widget.fabSize,
                color: Colors.transparent, // Capture taps
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    // Rotate the icon as it opens
                    return Transform.rotate(
                      angle: _controller.value * math.pi, // 180 degree rotation
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Opacity(
                            opacity: 1.0 - _controller.value,
                            child: widget.openIcon,
                          ),
                          Opacity(
                            opacity: _controller.value,
                            child: widget.closeIcon,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
