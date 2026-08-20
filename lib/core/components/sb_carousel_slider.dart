import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbCarouselSlider extends StatefulWidget {
  final List<Widget> items;
  final double height;
  final bool autoPlay;
  final Duration autoPlayInterval;
  final bool showIndicators;

  const SbCarouselSlider({
    super.key,
    required this.items,
    this.height = 200.0,
    this.autoPlay = false,
    this.autoPlayInterval = const Duration(seconds: 4),
    this.showIndicators = true,
  });

  @override
  State<SbCarouselSlider> createState() => _SbCarouselSliderState();
}

class _SbCarouselSliderState extends State<SbCarouselSlider> {
  late PageController _pageController;
  int _currentPage = 0;
  bool _isAutoPlaying = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.autoPlay && widget.items.isNotEmpty) {
      _startAutoPlay();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    if (_isAutoPlaying || widget.items.length <= 1) return;
    _isAutoPlaying = true;
    _autoPlayLoop();
  }

  Future<void> _autoPlayLoop() async {
    while (_isAutoPlaying && mounted) {
      await Future.delayed(widget.autoPlayInterval);
      if (!mounted) break;
      
      int nextPage = _currentPage + 1;
      if (nextPage >= widget.items.length) {
        nextPage = 0;
      }
      
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return SizedBox(height: widget.height);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      height: widget.height,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.items.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: SBSpacing.sm),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(SBRadius.lg),
                  child: widget.items[index],
                ),
              );
            },
          ),
          if (widget.showIndicators && widget.items.length > 1)
            Positioned(
              bottom: SBSpacing.sm,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: SBSpacing.sm, vertical: 4.0),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(SBRadius.full),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(widget.items.length, (index) {
                    final isActive = _currentPage == index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 2.0),
                      height: 6.0,
                      width: isActive ? 16.0 : 6.0,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(3.0),
                      ),
                    );
                  }),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
