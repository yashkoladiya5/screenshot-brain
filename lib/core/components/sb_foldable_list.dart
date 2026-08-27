import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../design/tokens.dart';

class SbFoldableList extends StatefulWidget {
  final List<Widget> items;
  final Widget header;
  final double itemHeight;
  final Color backgroundColor;

  const SbFoldableList({
    super.key,
    required this.items,
    required this.header,
    this.itemHeight = 60.0,
    this.backgroundColor = Colors.white,
  });

  @override
  State<SbFoldableList> createState() => _SbFoldableListState();
}

class _SbFoldableListState extends State<SbFoldableList> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    if (_isExpanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The Header that triggers the fold
        GestureDetector(
          onTap: _toggle,
          child: widget.header,
        ),
        
        // The folding items
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(widget.items.length, (index) {
                // Calculate stagger so items fold out one by one
                final double start = (index / widget.items.length) * 0.5;
                final double end = start + 0.5;
                
                final Animation<double> foldAnim = CurvedAnimation(
                  parent: _controller,
                  curve: Interval(start, end, curve: Curves.easeOutCubic),
                );
                
                if (foldAnim.value == 0) return const SizedBox.shrink();

                // Rotate around the top edge (X-axis)
                // When 0: rotated -90 degrees (folded flat, invisible)
                // When 1: rotated 0 degrees (fully unfolded)
                final double angle = (1.0 - foldAnim.value) * -math.pi / 2;

                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.002) // Perspective
                    ..rotateX(angle),
                  alignment: FractionalOffset.topCenter,
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: foldAnim.value, // Compress height to simulate folding out
                    child: Container(
                      height: widget.itemHeight,
                      decoration: BoxDecoration(
                        color: widget.backgroundColor,
                        // Add shadow to bottom edge to give depth during folding
                        boxShadow: [
                          if (foldAnim.value < 1.0)
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1 * (1.0 - foldAnim.value)),
                              blurRadius: 4,
                              offset: const Offset(0, 4),
                            )
                        ],
                      ),
                      child: widget.items[index],
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }
}
