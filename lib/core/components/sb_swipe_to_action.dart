import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbSwipeActionData {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const SbSwipeActionData({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class SbSwipeToAction extends StatefulWidget {
  final Widget child;
  final List<SbSwipeActionData>? leftActions;
  final List<SbSwipeActionData>? rightActions;
  final double actionWidth;
  final double swipeThreshold;

  const SbSwipeToAction({
    super.key,
    required this.child,
    this.leftActions,
    this.rightActions,
    this.actionWidth = 80.0,
    this.swipeThreshold = 0.3,
  });

  @override
  State<SbSwipeToAction> createState() => _SbSwipeToActionState();
}

class _SbSwipeToActionState extends State<SbSwipeToAction> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  double _dragOffset = 0.0;
  bool _isDragging = false;
  double _maxLeftOffset = 0.0;
  double _maxRightOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _maxLeftOffset = (widget.leftActions?.length ?? 0) * widget.actionWidth;
    _maxRightOffset = (widget.rightActions?.length ?? 0) * widget.actionWidth;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    if (_controller.isAnimating) return;
    
    setState(() {
      _isDragging = true;
    });
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    
    setState(() {
      _dragOffset += details.delta.dx;
      
      // Add resistance when pulling past the max actions width
      if (_dragOffset > _maxLeftOffset) {
        _dragOffset = _maxLeftOffset + (_dragOffset - _maxLeftOffset) * 0.2;
      } else if (_dragOffset < -_maxRightOffset) {
        _dragOffset = -_maxRightOffset + (_dragOffset + _maxRightOffset) * 0.2;
      }
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (!_isDragging) return;
    _isDragging = false;
    
    double targetOffset = 0.0;
    
    // Check left swipe (revealing right actions)
    if (_dragOffset < 0 && widget.rightActions != null) {
      if (_dragOffset.abs() > _maxRightOffset * widget.swipeThreshold || details.primaryVelocity! < -500) {
        targetOffset = -_maxRightOffset;
      }
    }
    
    // Check right swipe (revealing left actions)
    else if (_dragOffset > 0 && widget.leftActions != null) {
      if (_dragOffset > _maxLeftOffset * widget.swipeThreshold || details.primaryVelocity! > 500) {
        targetOffset = _maxLeftOffset;
      }
    }
    
    _animation = Tween<double>(begin: _dragOffset, end: targetOffset).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    
    _controller.forward(from: 0).then((_) {
      setState(() {
        _dragOffset = targetOffset;
      });
    });
  }

  void _closeAndExecute(VoidCallback action) {
    _animation = Tween<double>(begin: _dragOffset, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    
    _controller.forward(from: 0).then((_) {
      setState(() {
        _dragOffset = 0.0;
      });
      action();
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayOffset = _isDragging ? _dragOffset : (_controller.isAnimating ? _animation.value : _dragOffset);
    
    return Stack(
      children: [
        // Background Actions Layer
        Positioned.fill(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left Actions
              if (widget.leftActions != null && displayOffset > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.leftActions!.map((action) => _buildActionButton(action)).toList(),
                )
              else
                const SizedBox.shrink(),
                
              // Right Actions
              if (widget.rightActions != null && displayOffset < 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.rightActions!.map((action) => _buildActionButton(action)).toList(),
                )
              else
                const SizedBox.shrink(),
            ],
          ),
        ),
        
        // Foreground Content
        GestureDetector(
          onHorizontalDragStart: _onHorizontalDragStart,
          onHorizontalDragUpdate: _onHorizontalDragUpdate,
          onHorizontalDragEnd: _onHorizontalDragEnd,
          child: Transform.translate(
            offset: Offset(displayOffset, 0),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: displayOffset != 0 ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: Offset(displayOffset > 0 ? 5 : -5, 0),
                  )
                ] : null,
              ),
              child: widget.child,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(SbSwipeActionData action) {
    return GestureDetector(
      onTap: () => _closeAndExecute(action.onTap),
      child: Container(
        width: widget.actionWidth,
        height: double.infinity,
        color: action.color,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(action.icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              action.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
