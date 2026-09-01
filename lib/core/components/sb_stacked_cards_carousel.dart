import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbStackedCardsCarousel extends StatefulWidget {
  final List<Widget> cards;
  final double cardWidth;
  final double cardHeight;
  final double visibleOffset;
  final double depthFactor;

  const SbStackedCardsCarousel({
    super.key,
    required this.cards,
    this.cardWidth = 300.0,
    this.cardHeight = 400.0,
    this.visibleOffset = 30.0,
    this.depthFactor = 0.1, // Scale reduction per card backwards
  });

  @override
  State<SbStackedCardsCarousel> createState() => _SbStackedCardsCarouselState();
}

class _SbStackedCardsCarouselState extends State<SbStackedCardsCarousel> {
  late PageController _pageController;
  double _currentPage = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0.0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) return const SizedBox();

    return SizedBox(
      height: widget.cardHeight + (widget.cards.length * widget.visibleOffset),
      width: double.infinity,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Render cards from back to front
          ...List.generate(widget.cards.length, (index) {
            // Calculate how far this card is from the current focal page
            final double relativePosition = index - _currentPage;
            
            // If it's a previous card (scrolled past), we hide it or slide it out.
            // Let's slide it aggressively out to the left and fade it.
            if (relativePosition < -0.5) {
               final double slideOut = (relativePosition + 0.5) * widget.cardWidth;
               return Positioned(
                 top: 0,
                 child: Transform.translate(
                   offset: Offset(slideOut, 0),
                   child: Opacity(
                     opacity: (1.0 + (relativePosition + 0.5) * 2).clamp(0.0, 1.0),
                     child: SizedBox(
                       width: widget.cardWidth,
                       height: widget.cardHeight,
                       child: widget.cards[index],
                     ),
                   ),
                 ),
               );
            }

            // For cards at or behind the current page:
            // Calculate depth and vertical offset
            final double clampedRelativePosition = math.max(0.0, relativePosition);
            
            // Scale decreases as cards go further back
            final double scale = math.max(0.0, 1.0 - (clampedRelativePosition * widget.depthFactor));
            
            // Vertical offset pushes cards down so they peek out
            final double verticalOffset = clampedRelativePosition * widget.visibleOffset;

            // Opacity decreases slightly for background cards
            final double opacity = math.max(0.0, 1.0 - (clampedRelativePosition * 0.3));

            return Positioned(
              top: verticalOffset,
              child: Transform.scale(
                scale: scale,
                alignment: Alignment.topCenter,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: widget.cardWidth,
                    height: widget.cardHeight,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 15.0,
                          offset: const Offset(0, 10),
                        )
                      ]
                    ),
                    child: widget.cards[index],
                  ),
                ),
              ),
            );
          }).reversed, // Reverse to ensure index 0 is on top when currentPage is 0

          // An invisible PageView to handle the scrolling gestures
          Positioned.fill(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.cards.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                return Container(color: Colors.transparent);
              },
            ),
          ),
        ],
      ),
    );
  }
}
