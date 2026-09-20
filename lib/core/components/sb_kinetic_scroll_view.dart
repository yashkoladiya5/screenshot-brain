import 'package:flutter/material.dart';

class SbKineticScrollView extends StatefulWidget {
  final List<Widget> children;
  final double itemHeight;
  final double stretchFactor;

  const SbKineticScrollView({
    super.key,
    required this.children,
    this.itemHeight = 100.0,
    this.stretchFactor = 0.3, // How much items stretch when scrolling fast
  });

  @override
  State<SbKineticScrollView> createState() => _SbKineticScrollViewState();
}

class _SbKineticScrollViewState extends State<SbKineticScrollView> {
  late ScrollController _scrollController;
  double _scrollVelocity = 0.0;
  double _lastScrollOffset = 0.0;
  int _lastScrollTime = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final int currentTime = DateTime.now().millisecondsSinceEpoch;
    final double currentOffset = _scrollController.offset;
    
    // Calculate velocity: delta distance / delta time
    if (_lastScrollTime > 0) {
      final double deltaDistance = currentOffset - _lastScrollOffset;
      final int deltaTime = currentTime - _lastScrollTime;
      
      if (deltaTime > 0) {
        // Pixel per millisecond
        final double rawVelocity = deltaDistance / deltaTime;
        
        setState(() {
          // Smooth the velocity slightly and clamp it so it doesn't get completely ridiculous
          _scrollVelocity = rawVelocity.clamp(-3.0, 3.0);
        });
      }
    }

    _lastScrollOffset = currentOffset;
    _lastScrollTime = currentTime;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollEndNotification>(
      onNotification: (notification) {
        // When scroll ends, snap the velocity back to 0 so items bounce back to normal shape
        setState(() {
          _scrollVelocity = 0.0;
        });
        return false; // let the notification bubble up
      },
      child: ListView.builder(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        itemCount: widget.children.length,
        itemBuilder: (context, index) {
          // We calculate a dynamic stretch and scale based on scroll velocity
          
          // Stretching: If scrolling fast, the items stretch vertically
          final double stretch = 1.0 + (_scrollVelocity.abs() * widget.stretchFactor);
          
          // Rotation: If scrolling fast, the items tilt slightly up or down
          final double rotation = _scrollVelocity * -0.05;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            // We use AnimatedContainer instead of raw Transform so that when scrolling STOPS,
            // the items smoothly animate back to their default shape instead of snapping instantly
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutQuad,
              height: widget.itemHeight * stretch,
              transformAlignment: FractionalOffset.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001) // Add slight perspective
                ..rotateX(rotation), // Tilt based on velocity
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                ),
                clipBehavior: Clip.antiAlias,
                child: widget.children[index],
              ),
            ),
          );
        },
      ),
    );
  }
}
