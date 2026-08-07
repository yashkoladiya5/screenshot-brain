import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbCarousel extends StatefulWidget {
  final List<Widget> items;
  final double height;
  final bool autoPlay;
  final Duration autoPlayInterval;
  final bool showIndicators;

  const SbCarousel({
    super.key,
    required this.items,
    this.height = 200.0,
    this.autoPlay = false,
    this.autoPlayInterval = const Duration(seconds: 4),
    this.showIndicators = true,
  }) : assert(items.length > 0);

  @override
  State<SbCarousel> createState() => _SbCarouselState();
}

class _SbCarouselState extends State<SbCarousel> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.autoPlay && widget.items.length > 1) {
      _startAutoPlay();
    }
  }

  void _startAutoPlay() {
    Future.delayed(widget.autoPlayInterval, () {
      if (!mounted) return;
      final nextPage = (_currentPage + 1) % widget.items.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      _startAutoPlay();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.height,
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: widget.items,
          ),
        ),
        if (widget.showIndicators && widget.items.length > 1) ...[
          const SizedBox(height: SBSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.items.length,
              (index) => Container(
                width: _currentPage == index ? 24.0 : 8.0,
                height: 8.0,
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4.0),
                  color: _currentPage == index
                      ? colorScheme.primary
                      : colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
