import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../design/tokens.dart';

class SbInteractiveCardStack extends StatefulWidget {
  final List<Widget> cards;
  final Function(int, bool)? onSwipe; // int index, bool isRightSwipe
  final VoidCallback? onStackEmpty;
  final double cardWidth;
  final double cardHeight;

  const SbInteractiveCardStack({
    super.key,
    required this.cards,
    this.onSwipe,
    this.onStackEmpty,
    this.cardWidth = 300.0,
    this.cardHeight = 400.0,
  }) : assert(cards.length > 0);

  @override
  State<SbInteractiveCardStack> createState() => _SbInteractiveCardStackState();
}

class _SbInteractiveCardStackState extends State<SbInteractiveCardStack> with SingleTickerProviderStateMixin {
  late List<Widget> _currentCards;
  
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;
  double _dragAngle = 0.0;
  
  late AnimationController _snapController;
  late Animation<Offset> _snapAnimation;
  late Animation<double> _angleAnimation;

  @override
  void initState() {
    super.initState();
    // Reverse the list so the first item visually appears on top of the stack
    _currentCards = List.from(widget.cards.reversed);
    
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void didUpdateWidget(SbInteractiveCardStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cards != oldWidget.cards) {
      _currentCards = List.from(widget.cards.reversed);
    }
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    if (_currentCards.isEmpty) return;
    if (_snapController.isAnimating) _snapController.stop();
    setState(() {
      _isDragging = true;
      _dragOffset = Offset.zero;
      _dragAngle = 0.0;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_currentCards.isEmpty) return;
    setState(() {
      _dragOffset += details.delta;
      // Rotate card slightly based on X drag distance
      _dragAngle = (_dragOffset.dx / widget.cardWidth) * 0.2; 
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentCards.isEmpty) return;
    setState(() {
      _isDragging = false;
    });

    final double screenWidth = MediaQuery.of(context).size.width;
    final double escapeThreshold = widget.cardWidth * 0.4;
    
    // Check if swiped far enough or fast enough
    if (_dragOffset.dx.abs() > escapeThreshold || details.velocity.pixelsPerSecond.dx.abs() > 1000) {
      // Swiped away!
      final bool isRightSwipe = _dragOffset.dx > 0 || details.velocity.pixelsPerSecond.dx > 1000;
      
      // Calculate offscreen endpoint
      final double endX = isRightSwipe ? screenWidth : -screenWidth;
      final double endY = _dragOffset.dy + (details.velocity.pixelsPerSecond.dy * 0.3);

      _snapAnimation = Tween<Offset>(
        begin: _dragOffset,
        end: Offset(endX, endY),
      ).animate(CurvedAnimation(parent: _snapController, curve: Curves.easeOut));
      
      _angleAnimation = Tween<double>(
        begin: _dragAngle,
        end: isRightSwipe ? 0.5 : -0.5,
      ).animate(CurvedAnimation(parent: _snapController, curve: Curves.easeOut));

      _snapController.forward(from: 0.0).then((_) {
        // Remove the top card (which is the last in the list)
        final removedIndex = widget.cards.length - _currentCards.length;
        setState(() {
          _currentCards.removeLast();
          _dragOffset = Offset.zero;
          _dragAngle = 0.0;
        });
        
        widget.onSwipe?.call(removedIndex, isRightSwipe);
        
        if (_currentCards.isEmpty) {
          widget.onStackEmpty?.call();
        }
      });
      
    } else {
      // Snap back to center
      _snapAnimation = Tween<Offset>(
        begin: _dragOffset,
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _snapController, curve: Curves.elasticOut));
      
      _angleAnimation = Tween<double>(
        begin: _dragAngle,
        end: 0.0,
      ).animate(CurvedAnimation(parent: _snapController, curve: Curves.elasticOut));

      _snapController.addListener(_updateSnapState);
      _snapController.forward(from: 0.0).then((_) {
        _snapController.removeListener(_updateSnapState);
      });
    }
  }
  
  void _updateSnapState() {
    setState(() {
      _dragOffset = _snapAnimation.value;
      _dragAngle = _angleAnimation.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentCards.isEmpty) {
      return SizedBox(
        width: widget.cardWidth,
        height: widget.cardHeight,
        child: const Center(
          child: Text('No more cards'),
        ),
      );
    }

    return SizedBox(
      width: widget.cardWidth,
      height: widget.cardHeight,
      child: Stack(
        alignment: Alignment.center,
        children: _currentCards.asMap().entries.map((entry) {
          final int idx = entry.key;
          final Widget card = entry.value;
          
          final bool isTopCard = idx == _currentCards.length - 1;
          
          // Background cards scale down and shift down slightly
          final int depthIndex = _currentCards.length - 1 - idx;
          
          // Calculate scale and translation for background cards
          double scale = 1.0;
          double translateY = 0.0;
          
          if (!isTopCard) {
            // As top card is dragged, the next card scales up to become the new top card
            final double dragPercent = (_dragOffset.dx.abs() / (widget.cardWidth * 0.5)).clamp(0.0, 1.0);
            
            // Current depth offset minus the progress of the top card dragging away
            final double effectiveDepth = math.max(0.0, depthIndex - dragPercent);
            
            scale = 1.0 - (effectiveDepth * 0.05);
            translateY = effectiveDepth * 15.0;
          }
          
          // Apply drag transformations only to the top card
          final Offset offset = isTopCard ? _dragOffset : Offset(0, translateY);
          final double angle = isTopCard ? _dragAngle : 0.0;

          Widget positionedCard = Transform.translate(
            offset: offset,
            child: Transform.rotate(
              angle: angle,
              child: Transform.scale(
                scale: scale,
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: widget.cardWidth,
                  height: widget.cardHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(SBRadius.xl),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1 + (isTopCard ? 0.1 : 0.0)),
                        blurRadius: isTopCard && _isDragging ? 20 : 10,
                        spreadRadius: 1,
                        offset: Offset(0, isTopCard && _isDragging ? 10 : 5),
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(SBRadius.xl),
                    child: card,
                  ),
                ),
              ),
            ),
          );

          if (isTopCard) {
            return GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: positionedCard,
            );
          }

          return positionedCard;
        }).toList(),
      ),
    );
  }
}
