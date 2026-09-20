import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbMorphingCardDeck extends StatefulWidget {
  final List<Widget> cards;
  final double cardWidth;
  final double cardHeight;
  final double spreadRadius;

  const SbMorphingCardDeck({
    super.key,
    required this.cards,
    this.cardWidth = 250.0,
    this.cardHeight = 350.0,
    this.spreadRadius = 100.0,
  });

  @override
  State<SbMorphingCardDeck> createState() => _SbMorphingCardDeckState();
}

class _SbMorphingCardDeckState extends State<SbMorphingCardDeck> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isSpread = false;

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

  void _toggleDeck() {
    if (_isSpread) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    setState(() {
      _isSpread = !_isSpread;
    });
  }

  @override
  Widget build(BuildContext context) {
    // If there are no cards, return empty
    if (widget.cards.isEmpty) return const SizedBox();

    return GestureDetector(
      onTap: _toggleDeck,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        // The container needs to be wide/tall enough to hold the spread cards
        width: widget.cardWidth + (widget.spreadRadius * 2),
        height: widget.cardHeight + (widget.spreadRadius * 2),
        child: Stack(
          alignment: Alignment.center,
          children: List.generate(widget.cards.length, (index) {
            // We calculate exactly how far to spread this specific card
            // We want them evenly fanned out in a semi-circle or full circle
            // For a deck of cards, a fan shape (e.g. -45 deg to +45 deg) looks best
            final double fanAngleSpan = math.pi / 2; // 90 degrees total spread
            
            // Calculate the angle for this specific card
            // If length is 1, it just stays at 0. Otherwise, spread evenly.
            final double normalizedIndex = widget.cards.length > 1 
                ? (index / (widget.cards.length - 1)) - 0.5 
                : 0.0;
            
            final double targetAngle = normalizedIndex * fanAngleSpan;
            
            // We also want them to move out slightly along the Y and X axis to create the fan shape
            final double targetX = math.sin(targetAngle) * widget.spreadRadius;
            
            // Cards on the edges should drop down slightly lower than center cards
            // Cosine of 0 is 1 (center card). Cosine of +/- 45 deg is ~0.7.
            // So we invert it: center card stays high, edge cards drop down.
            final double dropDistance = widget.spreadRadius * 0.5;
            final double targetY = (1.0 - math.cos(targetAngle)) * dropDistance;

            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                // We use a spring curve for the spread animation
                final double curvedValue = Curves.easeOutBack.transform(_controller.value);
                
                // Interpolate position and rotation
                final double currentX = targetX * curvedValue;
                final double currentY = targetY * curvedValue;
                final double currentRotation = targetAngle * curvedValue;

                // Scale down background cards slightly when collapsed so they look like a stack
                final double reverseIndex = (widget.cards.length - 1 - index).toDouble();
                final double collapsedScale = 1.0 - (reverseIndex * 0.02);
                final double currentScale = collapsedScale + ((1.0 - collapsedScale) * curvedValue);

                return Transform.translate(
                  offset: Offset(currentX, currentY),
                  child: Transform.rotate(
                    angle: currentRotation,
                    child: Transform.scale(
                      scale: currentScale,
                      child: Container(
                        width: widget.cardWidth,
                        height: widget.cardHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 15,
                              // Shadow drops down and right, moves further away when spread
                              offset: Offset(2 * (index + 1).toDouble(), 5 + (5 * curvedValue)),
                            )
                          ]
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: widget.cards[index],
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}
