import 'package:flutter/material.dart';

class SbAnimatedCardStack extends StatefulWidget {
  final List<Widget> cards;
  final double cardWidth;
  final double cardHeight;
  final double spacing;

  const SbAnimatedCardStack({
    super.key,
    required this.cards,
    this.cardWidth = 300.0,
    this.cardHeight = 400.0,
    this.spacing = 15.0,
  });

  @override
  State<SbAnimatedCardStack> createState() => _SbAnimatedCardStackState();
}

class _SbAnimatedCardStackState extends State<SbAnimatedCardStack> {
  int _currentIndex = 0;

  void _onPanEnd(DragEndDetails details) {
    if (details.primaryVelocity! < 0) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % widget.cards.length;
      });
    } else if (details.primaryVelocity! > 0) {
      setState(() {
        _currentIndex = (_currentIndex - 1 + widget.cards.length) % widget.cards.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: _onPanEnd,
      child: SizedBox(
        width: widget.cardWidth,
        height: widget.cardHeight + (widget.spacing * 3),
        child: Stack(
          alignment: Alignment.topCenter,
          children: List.generate(widget.cards.length, (index) {
            int relativeIndex = (index - _currentIndex + widget.cards.length) % widget.cards.length;
            
            if (relativeIndex > 3) return const SizedBox.shrink();

            final double scale = 1.0 - (relativeIndex * 0.05);
            final double topOffset = relativeIndex * widget.spacing;
            final double opacity = 1.0 - (relativeIndex * 0.2);

            return AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              top: topOffset,
              child: AnimatedScale(
                scale: scale,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: AnimatedOpacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  duration: const Duration(milliseconds: 400),
                  child: Container(
                    width: widget.cardWidth,
                    height: widget.cardHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        )
                      ]
                    ),
                    child: widget.cards[index],
                  ),
                ),
              ),
            );
          }).reversed.toList(), 
        ),
      ),
    );
  }
}
