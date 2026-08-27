import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbSwipeableDeleteItem extends StatefulWidget {
  final Widget child;
  final VoidCallback onDelete;
  final Widget backgroundIcon;
  final Color backgroundColor;
  final double deleteThreshold; // How far to swipe before triggering delete

  const SbSwipeableDeleteItem({
    super.key,
    required this.child,
    required this.onDelete,
    this.backgroundIcon = const Icon(Icons.delete, color: Colors.white, size: 30),
    this.backgroundColor = Colors.redAccent,
    this.deleteThreshold = 0.4, // 40% of screen width
  });

  @override
  State<SbSwipeableDeleteItem> createState() => _SbSwipeableDeleteItemState();
}

class _SbSwipeableDeleteItemState extends State<SbSwipeableDeleteItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _dragOffset = 0.0;
  bool _isDragging = false;
  bool _willDelete = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
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
    setState(() {
      // Only allow swiping left (negative offset)
      _dragOffset += details.delta.dx;
      if (_dragOffset > 0) _dragOffset = 0;
      
      // Determine if we've crossed the threshold to trigger delete
      final double screenWidth = MediaQuery.of(context).size.width;
      _willDelete = (_dragOffset.abs() / screenWidth) > widget.deleteThreshold;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });
    
    final double screenWidth = MediaQuery.of(context).size.width;
    
    // Snap back or delete based on threshold and velocity
    if (_willDelete || details.velocity.pixelsPerSecond.dx < -800) {
      // Animate off screen
      final Animation<double> slideOff = Tween<double>(
        begin: _dragOffset,
        end: -screenWidth,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
      
      slideOff.addListener(() {
        setState(() {
          _dragOffset = slideOff.value;
        });
      });
      
      _controller.forward(from: 0.0).then((_) {
        widget.onDelete();
      });
    } else {
      // Snap back to 0
      final Animation<double> snapBack = Tween<double>(
        begin: _dragOffset,
        end: 0.0,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
      
      snapBack.addListener(() {
        setState(() {
          _dragOffset = snapBack.value;
        });
      });
      
      _controller.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    // How much the item is currently swiped out (0.0 to 1.0+)
    final double swipePercent = _dragOffset.abs() / MediaQuery.of(context).size.width;
    
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onPanCancel: () => _onPanEnd(DragEndDetails()),
      child: Stack(
        children: [
          // 1. The Background Action Layer (Revealed as you swipe)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: _willDelete 
                    ? widget.backgroundColor 
                    : widget.backgroundColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(SBRadius.md),
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 20.0),
                  child: Transform.scale(
                    // Pop the icon when it crosses the deletion threshold
                    scale: _willDelete ? 1.2 : 0.8 + (swipePercent * 0.4).clamp(0.0, 0.2),
                    child: widget.backgroundIcon,
                  ),
                ),
              ),
            ),
          ),
          
          // 2. The Actual Foreground Item (Shifts left based on drag)
          Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
