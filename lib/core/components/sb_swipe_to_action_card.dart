import 'package:flutter/material.dart';

class SbSwipeToActionCard extends StatefulWidget {
  final Widget child;
  final Widget leftAction;
  final Widget rightAction;
  final Color leftColor;
  final Color rightColor;
  final VoidCallback onLeftSwipe;
  final VoidCallback onRightSwipe;
  final double threshold;

  const SbSwipeToActionCard({
    super.key,
    required this.child,
    required this.leftAction,
    required this.rightAction,
    required this.onLeftSwipe,
    required this.onRightSwipe,
    this.leftColor = Colors.green,
    this.rightColor = Colors.red,
    this.threshold = 0.4, // Percentage of screen width to trigger action
  });

  @override
  State<SbSwipeToActionCard> createState() => _SbSwipeToActionCardState();
}

class _SbSwipeToActionCardState extends State<SbSwipeToActionCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _dragOffset = 0.0;
  bool _isDragging = false;
  double _screenWidth = 0.0;

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
    if (_controller.isAnimating) _controller.stop();
    setState(() {
      _isDragging = true;
      _screenWidth = MediaQuery.of(context).size.width;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dx;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });

    final double velocity = details.primaryVelocity ?? 0.0;
    final double normalizedOffset = _dragOffset / _screenWidth;

    // Check if swiped past threshold OR swiped fast enough
    if (normalizedOffset > widget.threshold || velocity > 1000) {
      // Swiped Right
      _animateTo(
        _screenWidth, 
        () {
          widget.onLeftSwipe(); // Swiping right reveals left action
          _reset();
        }
      );
    } else if (normalizedOffset < -widget.threshold || velocity < -1000) {
      // Swiped Left
      _animateTo(
        -_screenWidth, 
        () {
          widget.onRightSwipe(); // Swiping left reveals right action
          _reset();
        }
      );
    } else {
      // Didn't swipe far enough, snap back to center
      _reset();
    }
  }

  void _animateTo(double targetOffset, VoidCallback onComplete) {
    _animation = Tween<double>(
      begin: _dragOffset,
      end: targetOffset,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _animation.addListener(() {
      setState(() {
        _dragOffset = _animation.value;
      });
    });

    _controller.forward(from: 0.0).then((_) => onComplete());
  }

  void _reset() {
    _animation = Tween<double>(
      begin: _dragOffset,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack, // Spring back physics
    ));

    _animation.addListener(() {
      setState(() {
        _dragOffset = _animation.value;
      });
    });

    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    // Calculate which background to show based on drag direction
    Color backgroundColor = Colors.transparent;
    Widget? actionWidget;
    Alignment actionAlignment = Alignment.center;

    if (_dragOffset > 0) {
      backgroundColor = widget.leftColor;
      actionWidget = widget.leftAction;
      actionAlignment = Alignment.centerLeft;
    } else if (_dragOffset < 0) {
      backgroundColor = widget.rightColor;
      actionWidget = widget.rightAction;
      actionAlignment = Alignment.centerRight;
    }

    // Scale the action icon based on how far we pulled
    final double normalizedPull = _screenWidth == 0 ? 0 : (_dragOffset.abs() / _screenWidth).clamp(0.0, 1.0);
    final double iconScale = 0.5 + (normalizedPull * 0.5);

    return Stack(
      children: [
        // The Background Action Layer
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Align(
                alignment: actionAlignment,
                child: Transform.scale(
                  scale: iconScale,
                  child: actionWidget ?? const SizedBox(),
                ),
              ),
            ),
          ),
        ),
        
        // The Foreground Draggable Card
        GestureDetector(
          onHorizontalDragStart: _onPanStart,
          onHorizontalDragUpdate: _onPanUpdate,
          onHorizontalDragEnd: _onPanEnd,
          child: Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: Container(
              decoration: BoxDecoration(
                boxShadow: _dragOffset != 0 ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ] : [],
              ),
              child: widget.child,
            ),
          ),
        ),
      ],
    );
  }
}
