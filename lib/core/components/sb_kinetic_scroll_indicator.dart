import 'package:flutter/material.dart';

class SbKineticScrollIndicator extends StatefulWidget {
  final ScrollController scrollController;
  final Color color;
  final double width;
  final double minHeight;
  final double maxHeight;

  const SbKineticScrollIndicator({
    super.key,
    required this.scrollController,
    this.color = const Color(0xFFFF3D00),
    this.width = 6.0,
    this.minHeight = 40.0,
    this.maxHeight = 120.0,
  });

  @override
  State<SbKineticScrollIndicator> createState() => _SbKineticScrollIndicatorState();
}

class _SbKineticScrollIndicatorState extends State<SbKineticScrollIndicator> with SingleTickerProviderStateMixin {
  double _scrollProgress = 0.0;
  double _velocity = 0.0;
  
  // To calculate velocity manually since ScrollController's velocity isn't always reliable
  double _lastScrollOffset = 0.0;
  DateTime _lastScrollTime = DateTime.now();

  late AnimationController _springController;
  late Animation<double> _springAnimation;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
    
    // The spring controller snaps the stretched indicator back to its normal shape
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _springAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _springController,
        curve: Curves.elasticOut,
      )
    );
    
    _springAnimation.addListener(() {
      // If we aren't actively scrolling, we use the spring's value to bounce back to 0 velocity
      if (!widget.scrollController.position.isScrollingNotifier.value) {
        setState(() {
          _velocity = _springAnimation.value;
        });
      }
    });

    // Listen for when scrolling stops so we can trigger the elastic snap back
    widget.scrollController.position.isScrollingNotifier.addListener(_onScrollStateChanged);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    widget.scrollController.position.isScrollingNotifier.removeListener(_onScrollStateChanged);
    _springController.dispose();
    super.dispose();
  }

  void _onScrollStateChanged() {
    if (!widget.scrollController.position.isScrollingNotifier.value) {
      // Scrolling just stopped! We take the current velocity and animate it back to 0 with a spring
      _springAnimation = Tween<double>(
        begin: _velocity,
        end: 0.0,
      ).animate(
        CurvedAnimation(
          parent: _springController,
          curve: Curves.elasticOut,
        )
      );
      _springController.forward(from: 0.0);
    }
  }

  void _onScroll() {
    if (!widget.scrollController.hasClients) return;
    
    final position = widget.scrollController.position;
    final maxScroll = position.maxScrollExtent;
    
    if (maxScroll <= 0) return;

    // Calculate basic progress (0.0 to 1.0)
    final progress = (position.pixels / maxScroll).clamp(0.0, 1.0);
    
    // Manually calculate instantaneous velocity
    final now = DateTime.now();
    final dt = now.difference(_lastScrollTime).inMilliseconds.toDouble();
    
    double currentVelocity = 0.0;
    if (dt > 0) {
      final dx = position.pixels - _lastScrollOffset;
      // pixels per millisecond
      currentVelocity = dx / dt; 
    }
    
    // Smooth out the velocity reading slightly so it doesn't flicker wildly
    _velocity = (_velocity * 0.7) + (currentVelocity * 0.3);
    
    _lastScrollOffset = position.pixels;
    _lastScrollTime = now;

    setState(() {
      _scrollProgress = progress;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double trackHeight = constraints.maxHeight;
        
        // Base physics math
        // Absolute velocity determines how much it stretches
        final double absVelocity = _velocity.abs();
        
        // Stretch factor: 0.0 (no stretch) to 1.0 (max stretch)
        final double stretch = (absVelocity / 5.0).clamp(0.0, 1.0);
        
        // Dynamic height: grows as you scroll faster
        final double currentHeight = widget.minHeight + ((widget.maxHeight - widget.minHeight) * stretch);
        
        // Dynamic width: shrinks (squishes) as it stretches taller, maintaining mass
        final double currentWidth = widget.width * (1.0 - (stretch * 0.4));
        
        // Calculate the top position based on scroll progress
        // We need to account for the indicator's height so it doesn't bleed off the bottom
        final double topPosition = _scrollProgress * (trackHeight - currentHeight);
        
        // But wait! If we are actively stretching, we need to shift the anchor point.
        // If scrolling DOWN (positive velocity), it should stretch from the TOP (anchor top).
        // If scrolling UP (negative velocity), it should stretch from the BOTTOM (anchor bottom).
        // This makes it look like it's dragging behind the scroll point.
        
        double yOffset = 0.0;
        if (_velocity > 0) {
          // Stretching down. Top position remains the same, but the added height goes downward.
          yOffset = 0.0; 
        } else if (_velocity < 0) {
          // Stretching up. We must shift the top position UP by the amount it grew.
          final double heightDiff = currentHeight - widget.minHeight;
          yOffset = -heightDiff;
        }

        return Container(
          width: widget.width + 4, // Hitbox padding
          height: trackHeight,
          alignment: Alignment.topRight, // Always pin to the right edge
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: topPosition + yOffset,
                right: 2,
                child: Container(
                  width: currentWidth,
                  height: currentHeight,
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(currentWidth / 2),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.4),
                        blurRadius: 8 * stretch, // Glows harder when moving faster
                        spreadRadius: 1 * stretch,
                      )
                    ]
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}
