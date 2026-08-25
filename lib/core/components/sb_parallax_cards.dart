import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbParallaxCardData {
  final String title;
  final String subtitle;
  final String imageUrl;
  final Color overlayColor;

  const SbParallaxCardData({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.overlayColor = Colors.black54,
  });
}

class SbParallaxCards extends StatefulWidget {
  final List<SbParallaxCardData> cards;
  final double height;
  final double viewportFraction;

  const SbParallaxCards({
    super.key,
    required this.cards,
    this.height = 350.0,
    this.viewportFraction = 0.85,
  });

  @override
  State<SbParallaxCards> createState() => _SbParallaxCardsState();
}

class _SbParallaxCardsState extends State<SbParallaxCards> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: widget.viewportFraction);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.cards.length,
        itemBuilder: (context, index) {
          final card = widget.cards[index];

          return AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              double pageOffset = 0.0;
              if (_pageController.position.haveDimensions) {
                pageOffset = _pageController.page! - index;
              }

              // Parallax calculation
              final double alignmentOffset = pageOffset * 0.5; // Controls the strength of the parallax effect

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: SBSpacing.sm, vertical: SBSpacing.md),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(SBRadius.xl),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(SBRadius.xl),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Image with parallax shift
                      Image.network(
                        card.imageUrl,
                        fit: BoxFit.cover,
                        alignment: Alignment(alignmentOffset, 0),
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey.shade800,
                          child: const Center(child: Icon(Icons.image_not_supported, color: Colors.white, size: 50)),
                        ),
                      ),
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              card.overlayColor,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      // Text content
                      Padding(
                        padding: const EdgeInsets.all(SBSpacing.xl),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              card.title,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  const Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))
                                ],
                              ),
                            ),
                            const SizedBox(height: SBSpacing.xs),
                            Text(
                              card.subtitle,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                                shadows: [
                                  const Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
