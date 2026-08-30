import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbSwipeableCards extends StatefulWidget {
  final List<Widget> cards;
  final Function(int, SwipeDirection)? onSwiped;
  final VoidCallback? onStackEmpty;

  const SbSwipeableCards({
    super.key,
    required this.cards,
    this.onSwiped,
    this.onStackEmpty,
  });

  @override
  State<SbSwipeableCards> createState() => _SbSwipeableCardsState();
}

enum SwipeDirection { left, right }

class _SbSwipeableCardsState extends State<SbSwipeableCards> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Offset _dragOffset = Offset.zero;
  double _dragAngle = 0.0;
  bool _isDragging = false;
  
  // Track the index of the top card
  int _currentIndex = 0;
  
  // Track swipe out animation
  Offset _swipeOutOffset = Offset.zero;
  double _swipeOutAngle = 0.0;

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
    if (_currentIndex >= widget.cards.length) return;
    setState(() {
      _isDragging = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_currentIndex >= widget.cards.length) return;
    
    setState(() {
      _dragOffset += details.delta;
      // Calculate angle based on how far it's dragged horizontally
      // Dragging right tilts it right, dragging left tilts it left
      _dragAngle = (_dragOffset.dx / MediaQuery.of(context).size.width) * (math.pi / 8);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentIndex >= widget.cards.length) return;
    
    setState(() {
      _isDragging = false;
    });

    final screenWidth = MediaQuery.of(context).size.width;
    final velocityX = details.velocity.pixelsPerSecond.dx;
    
    // Threshold to swipe away is 30% of screen width or a fast flick
    if (_dragOffset.dx > screenWidth * 0.3 || velocityX > 800) {
      _swipeAway(SwipeDirection.right, screenWidth);
    } else if (_dragOffset.dx < -screenWidth * 0.3 || velocityX < -800) {
      _swipeAway(SwipeDirection.left, screenWidth);
    } else {
      _snapBack();
    }
  }
  
  void _swipeAway(SwipeDirection direction, double screenWidth) {
    // Calculate final offset well off screen
    final endX = direction == SwipeDirection.right ? screenWidth * 1.5 : -screenWidth * 1.5;
    final endY = _dragOffset.dy + (_dragOffset.dy > 0 ? 200.0 : -200.0); // Keep momentum
    
    final animOffset = Tween<Offset>(begin: _dragOffset, end: Offset(endX, endY)).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut)
    );
    
    final endAngle = direction == SwipeDirection.right ? math.pi / 4 : -math.pi / 4;
    final animAngle = Tween<double>(begin: _dragAngle, end: endAngle).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut)
    );
    
    animOffset.addListener(() {
      setState(() {
        _swipeOutOffset = animOffset.value;
        _swipeOutAngle = animAngle.value;
      });
    });
    
    _controller.forward(from: 0.0).then((_) {
      if (widget.onSwiped != null) {
        widget.onSwiped!(_currentIndex, direction);
      }
      
      setState(() {
        _currentIndex++;
        _dragOffset = Offset.zero;
        _dragAngle = 0.0;
        _swipeOutOffset = Offset.zero;
        _swipeOutAngle = 0.0;
      });
      
      if (_currentIndex >= widget.cards.length && widget.onStackEmpty != null) {
        widget.onStackEmpty!();
      }
    });
  }
  
  void _snapBack() {
    final animOffset = Tween<Offset>(begin: _dragOffset, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut)
    );
    
    final animAngle = Tween<double>(begin: _dragAngle, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut)
    );
    
    animOffset.addListener(() {
      setState(() {
        _dragOffset = animOffset.value;
        _dragAngle = animAngle.value;
      });
    });
    
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex >= widget.cards.length) {
      return const Center(child: Text("All caught up!", style: TextStyle(color: Colors.grey)));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Render the cards in reverse order so the top one is last in the Stack
            for (int i = widget.cards.length - 1; i >= _currentIndex; i--)
              _buildCard(
                index: i,
                isTopCard: i == _currentIndex,
                constraints: constraints,
              ),
          ],
        );
      },
    );
  }
  
  Widget _buildCard({
    required int index,
    required bool isTopCard,
    required BoxConstraints constraints,
  }) {
    // Determine offset and scale based on its depth in the stack
    final int depth = index - _currentIndex;
    
    // Only show top 3 cards for performance and visuals
    if (depth > 2) return const SizedBox.shrink();
    
    // Calculate stationary stack effects
    // Each card down the stack is slightly smaller and lower
    final double scale = 1.0 - (depth * 0.05);
    final double yOffset = depth * 20.0;
    
    // If it's the top card, apply drag/swipe transforms
    Offset currentOffset = isTopCard ? (_controller.isAnimating && !_isDragging ? _swipeOutOffset : _dragOffset) : Offset.zero;
    double currentAngle = isTopCard ? (_controller.isAnimating && !_isDragging ? _swipeOutAngle : _dragAngle) : 0.0;
    
    // If not top card, apply depth offset
    if (!isTopCard) {
      currentOffset = Offset(0, yOffset);
    }
    
    return Positioned(
      child: IgnorePointer(
        ignoring: !isTopCard, // Only top card receives touch
        child: GestureDetector(
          onPanStart: isTopCard ? _onPanStart : null,
          onPanUpdate: isTopCard ? _onPanUpdate : null,
          onPanEnd: isTopCard ? _onPanEnd : null,
          child: Transform.translate(
            offset: currentOffset,
            child: Transform.rotate(
              angle: currentAngle,
              child: Transform.scale(
                scale: scale,
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: constraints.maxWidth * 0.9,
                  height: constraints.maxHeight * 0.8,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                        offset: const Offset(0, 5),
                      )
                    ]
                  ),
                  child: widget.cards[index],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
