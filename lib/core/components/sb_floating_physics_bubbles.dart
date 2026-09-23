import 'package:flutter/material.dart';
import 'dart:math' as math;


class SbFloatingPhysicsBubbles extends StatefulWidget {
  final List<Widget> bubbleChildren;
  final int bubbleCount;
  final double maxBubbleSize;
  final double minBubbleSize;
  final Color baseColor;

  const SbFloatingPhysicsBubbles({
    super.key,
    this.bubbleChildren = const [],
    this.bubbleCount = 15,
    this.maxBubbleSize = 80.0,
    this.minBubbleSize = 30.0,
    this.baseColor = const Color(0x884FC3F7), // Semi-transparent light blue
  });

  @override
  State<SbFloatingPhysicsBubbles> createState() => _SbFloatingPhysicsBubblesState();
}

class _SbFloatingPhysicsBubblesState extends State<SbFloatingPhysicsBubbles> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_PhysicsBubble> _bubbles = [];
  final math.Random _random = math.Random();
  
  Offset? _touchPosition;
  Offset? _touchVelocity;
  Offset? _lastTouchPosition;
  int _lastTouchTime = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16), // ~60fps physics loop
    )..addListener(_updatePhysics);
    
    // We can't generate the bubbles properly until we know the screen size,
    // so we'll do it in didChangeDependencies or the first build.
    // For now, we just start the loop.
    _controller.repeat();
  }

  void _initBubbles(Size size) {
    if (_bubbles.isNotEmpty) return;
    
    final int count = widget.bubbleChildren.isNotEmpty 
        ? widget.bubbleChildren.length 
        : widget.bubbleCount;

    for (int i = 0; i < count; i++) {
      final double radius = widget.minBubbleSize + 
          _random.nextDouble() * (widget.maxBubbleSize - widget.minBubbleSize);
          
      // Random position within screen
      final double x = _random.nextDouble() * size.width;
      final double y = _random.nextDouble() * size.height;
      
      // Random gentle drift velocity
      final double vx = (_random.nextDouble() - 0.5) * 1.5;
      final double vy = (_random.nextDouble() - 0.5) * 1.5;
      
      _bubbles.add(_PhysicsBubble(
        position: Offset(x, y),
        velocity: Offset(vx, vy),
        radius: radius,
        child: widget.bubbleChildren.isNotEmpty ? widget.bubbleChildren[i] : null,
      ));
    }
  }

  void _updatePhysics() {
    if (_bubbles.isEmpty) return;
    
    final Size size = MediaQuery.of(context).size;
    
    setState(() {
      for (final bubble in _bubbles) {
        // 1. Apply base velocity
        bubble.position += bubble.velocity;
        
        // 2. Apply touch repulsion force if finger is on screen
        if (_touchPosition != null && _touchVelocity != null) {
          final Offset vectorToBubble = bubble.position - _touchPosition!;
          final double distance = vectorToBubble.distance;
          
          // If the bubble is near the finger (within 150px)
          if (distance < 150.0 && distance > 0) {
            // Repulsion strength is stronger when closer
            final double strength = (150.0 - distance) / 150.0;
            
            // Normalize vector and apply force
            final Offset pushForce = (vectorToBubble / distance) * strength * _touchVelocity!.distance * 0.1;
            bubble.velocity += pushForce;
          }
        }
        
        // 3. Apply subtle friction so they don't accelerate to infinity
        bubble.velocity *= 0.98; 
        
        // 4. If they slow down too much, add a tiny bit of random drift back in to keep them alive
        if (bubble.velocity.distance < 0.5) {
          bubble.velocity += Offset((_random.nextDouble() - 0.5) * 0.1, (_random.nextDouble() - 0.5) * 0.1);
        }
        
        // 5. Screen boundary bouncing logic
        if (bubble.position.dx - bubble.radius < 0) {
          bubble.position = Offset(bubble.radius, bubble.position.dy);
          bubble.velocity = Offset(bubble.velocity.dx.abs(), bubble.velocity.dy);
        } else if (bubble.position.dx + bubble.radius > size.width) {
          bubble.position = Offset(size.width - bubble.radius, bubble.position.dy);
          bubble.velocity = Offset(-bubble.velocity.dx.abs(), bubble.velocity.dy);
        }
        
        if (bubble.position.dy - bubble.radius < 0) {
          bubble.position = Offset(bubble.position.dx, bubble.radius);
          bubble.velocity = Offset(bubble.velocity.dx, bubble.velocity.dy.abs());
        } else if (bubble.position.dy + bubble.radius > size.height) {
          bubble.position = Offset(bubble.position.dx, size.height - bubble.radius);
          bubble.velocity = Offset(bubble.velocity.dx, -bubble.velocity.dy.abs());
        }
      }
    });
  }

  void _onPanStart(DragStartDetails details) {
    _touchPosition = details.localPosition;
    _lastTouchPosition = details.localPosition;
    _lastTouchTime = DateTime.now().millisecondsSinceEpoch;
    _touchVelocity = Offset.zero;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final int currentTime = DateTime.now().millisecondsSinceEpoch;
    _touchPosition = details.localPosition;
    
    if (_lastTouchPosition != null && _lastTouchTime > 0) {
      final int deltaTime = currentTime - _lastTouchTime;
      if (deltaTime > 0) {
        final Offset deltaDistance = _touchPosition! - _lastTouchPosition!;
        _touchVelocity = deltaDistance / deltaTime.toDouble();
      }
    }
    
    _lastTouchPosition = _touchPosition;
    _lastTouchTime = currentTime;
  }

  void _onPanEnd(DragEndDetails details) {
    _touchPosition = null;
    _touchVelocity = null;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Initialize bubbles on first build when we have context size
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_bubbles.isEmpty && mounted) {
        _initBubbles(MediaQuery.of(context).size);
      }
    });

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onPanCancel: () => _onPanEnd(DragEndDetails()),
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.transparent, // Capture touches
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: _bubbles.map((bubble) {
            return Positioned(
              // Position is the center, so subtract radius for top/left
              left: bubble.position.dx - bubble.radius,
              top: bubble.position.dy - bubble.radius,
              child: Container(
                width: bubble.radius * 2,
                height: bubble.radius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.baseColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.5),
                      blurRadius: bubble.radius * 0.2,
                      spreadRadius: -bubble.radius * 0.1,
                      offset: Offset(-bubble.radius * 0.1, -bubble.radius * 0.1),
                      blurStyle: BlurStyle.inner, // Highlight for bubble reflection
                    )
                  ]
                ),
                alignment: Alignment.center,
                clipBehavior: Clip.antiAlias,
                child: bubble.child,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _PhysicsBubble {
  Offset position;
  Offset velocity;
  final double radius;
  final Widget? child;

  _PhysicsBubble({
    required this.position,
    required this.velocity,
    required this.radius,
    this.child,
  });
}
