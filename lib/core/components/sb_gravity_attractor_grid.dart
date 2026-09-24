import 'package:flutter/material.dart';

class SbGravityAttractorGrid extends StatefulWidget {
  final int rows;
  final int columns;
  final double itemSize;
  final double spacing;
  final Widget Function(BuildContext, int, int) itemBuilder;
  final double gravityRadius;
  final double maxDisplacement;

  const SbGravityAttractorGrid({
    super.key,
    this.rows = 8,
    this.columns = 6,
    this.itemSize = 40.0,
    this.spacing = 10.0,
    required this.itemBuilder,
    this.gravityRadius = 150.0,
    this.maxDisplacement = 30.0,
  });

  @override
  State<SbGravityAttractorGrid> createState() => _SbGravityAttractorGridState();
}

class _SbGravityAttractorGridState extends State<SbGravityAttractorGrid> with SingleTickerProviderStateMixin {
  Offset? _touchPosition;
  late AnimationController _springController;
  
  // When touch ends, we use this to animate back to normal
  Offset? _lastTouchPosition;
  bool _isReleasing = false;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _springController.addListener(() {
      if (_isReleasing) {
        setState(() {}); // Re-render with decaying spring
      }
    });
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _onPanUpdate(Offset localPosition) {
    setState(() {
      _touchPosition = localPosition;
      _isReleasing = false;
    });
  }

  void _onPanEnd() {
    if (_touchPosition != null) {
      _lastTouchPosition = _touchPosition;
      _touchPosition = null;
      _isReleasing = true;
      
      _springController.forward(from: 0.0).then((_) {
        _isReleasing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double gridWidth = (widget.columns * widget.itemSize) + ((widget.columns - 1) * widget.spacing);
    final double gridHeight = (widget.rows * widget.itemSize) + ((widget.rows - 1) * widget.spacing);

    return GestureDetector(
      onPanDown: (details) => _onPanUpdate(details.localPosition),
      onPanUpdate: (details) => _onPanUpdate(details.localPosition),
      onPanEnd: (_) => _onPanEnd(),
      onPanCancel: _onPanEnd,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: gridWidth,
        height: gridHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: _buildGridItems(),
        ),
      ),
    );
  }

  List<Widget> _buildGridItems() {
    final List<Widget> items = [];
    
    // We calculate the spring decay if the user just let go
    final double springFactor = _isReleasing 
        ? (1.0 - Curves.elasticOut.transform(_springController.value))
        : 1.0;
        
    final Offset? activeTouch = _touchPosition ?? (_isReleasing ? _lastTouchPosition : null);

    for (int r = 0; r < widget.rows; r++) {
      for (int c = 0; c < widget.columns; c++) {
        // Calculate base position of this item
        final double baseX = c * (widget.itemSize + widget.spacing);
        final double baseY = r * (widget.itemSize + widget.spacing);
        
        final Offset itemCenter = Offset(baseX + (widget.itemSize / 2), baseY + (widget.itemSize / 2));
        
        double displacementX = 0;
        double displacementY = 0;
        double scale = 1.0;
        
        if (activeTouch != null) {
          // Vector from item to touch point
          final Offset vectorToTouch = activeTouch - itemCenter;
          final double distance = vectorToTouch.distance;
          
          if (distance < widget.gravityRadius) {
            // The closer it is, the stronger the pull
            // 1.0 = right at touch point, 0.0 = at edge of gravity radius
            final double pullStrength = (widget.gravityRadius - distance) / widget.gravityRadius;
            
            // Calculate how far to move it
            // We want it to move TOWARDS the finger, so we use the vector direction
            final Offset normalizedVector = vectorToTouch / (distance == 0 ? 1 : distance);
            
            final double pullAmount = widget.maxDisplacement * pullStrength;
            
            displacementX = normalizedVector.dx * pullAmount * springFactor;
            displacementY = normalizedVector.dy * pullAmount * springFactor;
            
            // Items directly under finger scale down slightly to look like they are pressed in
            scale = 1.0 - (pullStrength * 0.2 * springFactor);
          }
        }

        items.add(
          Positioned(
            left: baseX,
            top: baseY,
            width: widget.itemSize,
            height: widget.itemSize,
            child: Transform.translate(
              offset: Offset(displacementX, displacementY),
              child: Transform.scale(
                scale: scale,
                child: widget.itemBuilder(context, r, c),
              ),
            ),
          ),
        );
      }
    }
    
    return items;
  }
}
