import 'package:flutter/material.dart';

class SbSwipeableDeck extends StatefulWidget {
  final List<Widget> cards;
  final double cardWidth;
  final double cardHeight;
  final double offsetFactor;

  const SbSwipeableDeck({
    super.key,
    required this.cards,
    this.cardWidth = 300.0,
    this.cardHeight = 400.0,
    this.offsetFactor = 15.0, 
  });

  @override
  State<SbSwipeableDeck> createState() => _SbSwipeableDeckState();
}

class _SbSwipeableDeckState extends State<SbSwipeableDeck> {
  late List<Widget> _currentCards;
  
  @override
  void initState() {
    super.initState();
    _currentCards = List.from(widget.cards);
  }

  @override
  void didUpdateWidget(SbSwipeableDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cards != oldWidget.cards) {
      _currentCards = List.from(widget.cards);
    }
  }

  void _onSwipe(DismissDirection direction) {
    setState(() {
      final frontCard = _currentCards.removeLast();
      _currentCards.insert(0, frontCard);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentCards.isEmpty) return const SizedBox();

    return SizedBox(
      width: widget.cardWidth,
      height: widget.cardHeight + (widget.cards.length * widget.offsetFactor),
      child: Stack(
        alignment: Alignment.topCenter,
        children: List.generate(_currentCards.length, (index) {
          final int reverseIndex = _currentCards.length - 1 - index;
          
          final double topOffset = reverseIndex * widget.offsetFactor;
          final double scale = 1.0 - (reverseIndex * 0.05); 

          final Widget cardContent = Transform.scale(
            scale: scale,
            alignment: Alignment.bottomCenter,
            child: Container(
              width: widget.cardWidth,
              height: widget.cardHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10.0,
                    offset: const Offset(0, 8),
                  )
                ]
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.0),
                child: _currentCards[index],
              ),
            ),
          );

          if (index == _currentCards.length - 1) {
            return Positioned(
              top: topOffset,
              child: Dismissible(
                key: UniqueKey(), 
                direction: DismissDirection.horizontal,
                onDismissed: _onSwipe,
                child: cardContent,
              ),
            );
          } else {
            return AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              top: topOffset,
              child: cardContent,
            );
          }
        }),
      ),
    );
  }
}
