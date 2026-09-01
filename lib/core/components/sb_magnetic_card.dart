import 'package:flutter/material.dart';

class SbMagneticCard extends StatefulWidget {
  final Widget child;
  final double width;
  final double height;
  final double magneticStrength; // Max pixels it can move towards the cursor
  final Color backgroundColor;

  const SbMagneticCard({
    super.key,
    required this.child,
    this.width = 300.0,
    this.height = 200.0,
    this.magneticStrength = 20.0,
    this.backgroundColor = const Color(0xFF1E1E1E),
  });

  @override
  State<SbMagneticCard> createState() => _SbMagneticCardState();
}

class _SbMagneticCardState extends State<SbMagneticCard> with SingleTickerProviderStateMixin {
  Offset _currentOffset = Offset.zero;
  late AnimationController _resetController;
  late Animation<Offset> _resetAnimation;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _resetController.addListener(() {
      setState(() {
        _currentOffset = _resetAnimation.value;
      });
    });
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _onPointerMove(Offset localPosition) {
    if (_resetController.isAnimating) {
      _resetController.stop();
    }
    
    // Calculate the distance of the cursor from the absolute center of the card
    final double centerX = widget.width / 2;
    final double centerY = widget.height / 2;
    
    // Normalized distance from center (-1.0 to 1.0)
    final double normalizedX = ((localPosition.dx - centerX) / centerX).clamp(-1.0, 1.0);
    final double normalizedY = ((localPosition.dy - centerY) / centerY).clamp(-1.0, 1.0);
    
    setState(() {
      _isHovering = true;
      // Multiply the normalized vector by the magnetic strength
      _currentOffset = Offset(
        normalizedX * widget.magneticStrength,
        normalizedY * widget.magneticStrength,
      );
    });
  }

  void _onPointerExit() {
    setState(() {
      _isHovering = false;
    });
    
    // Spring back to center
    _resetAnimation = Tween<Offset>(
      begin: _currentOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _resetController,
      curve: Curves.elasticOut, // Elastic curve for that bouncy magnetic snap
    ));
    
    _resetController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) => _onPointerMove(event.localPosition),
      onExit: (_) => _onPointerExit(),
      child: GestureDetector(
        onPanUpdate: (details) => _onPointerMove(details.localPosition),
        onPanEnd: (_) => _onPointerExit(),
        child: SizedBox(
          width: widget.width + widget.magneticStrength * 2, // Give space for movement
          height: widget.height + widget.magneticStrength * 2,
          child: Center(
            child: Transform.translate(
              offset: _currentOffset,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: _isHovering ? 0.3 : 0.1),
                      blurRadius: _isHovering ? 20.0 : 10.0,
                      offset: Offset(
                        -_currentOffset.dx * 0.5, 
                        -_currentOffset.dy * 0.5 + (_isHovering ? 10.0 : 5.0)
                      ), // Shadow shifts opposite to movement
                    )
                  ]
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
