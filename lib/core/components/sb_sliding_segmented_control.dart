import 'package:flutter/material.dart';

class SbSlidingSegmentedControl extends StatefulWidget {
  final List<String> segments;
  final int initialIndex;
  final ValueChanged<int> onValueChanged;
  final double height;
  final double width;
  final Color backgroundColor;
  final Color thumbColor;

  const SbSlidingSegmentedControl({
    super.key,
    required this.segments,
    required this.onValueChanged,
    this.initialIndex = 0,
    this.height = 40.0,
    this.width = double.infinity,
    this.backgroundColor = const Color(0xFFE5E5EA), // Standard iOS light grey
    this.thumbColor = Colors.white,
  });

  @override
  State<SbSlidingSegmentedControl> createState() => _SbSlidingSegmentedControlState();
}

class _SbSlidingSegmentedControlState extends State<SbSlidingSegmentedControl> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onSegmentTapped(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
      widget.onValueChanged(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = widget.width == double.infinity ? constraints.maxWidth : widget.width;
        final double segmentWidth = (maxWidth - 4) / widget.segments.length;

        return Container(
          width: maxWidth,
          height: widget.height,
          padding: const EdgeInsets.all(2.0),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Stack(
            children: [
              // The sliding thumb
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                left: _currentIndex * segmentWidth,
                top: 0,
                bottom: 0,
                width: segmentWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.thumbColor,
                    borderRadius: BorderRadius.circular(6.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 1,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
              
              // The text labels
              Row(
                children: List.generate(widget.segments.length, (index) {
                  final bool isSelected = _currentIndex == index;
                  
                  return GestureDetector(
                    onTap: () => _onSegmentTapped(index),
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: segmentWidth,
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.black54,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            fontSize: 14.0,
                          ),
                          child: Text(widget.segments[index]),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}
