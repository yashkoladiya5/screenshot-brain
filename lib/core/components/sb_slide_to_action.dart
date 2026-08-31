import 'package:flutter/material.dart';

class SbSlideToAction extends StatefulWidget {
  final VoidCallback onActionCompleted;
  final String text;
  final Widget icon;
  final double width;
  final double height;
  final Color baseColor;
  final Color slideColor;

  const SbSlideToAction({
    super.key,
    required this.onActionCompleted,
    this.text = 'Slide to confirm',
    this.icon = const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
    this.width = 300.0,
    this.height = 60.0,
    this.baseColor = Colors.black12,
    this.slideColor = Colors.blueAccent,
  });

  @override
  State<SbSlideToAction> createState() => _SbSlideToActionState();
}

class _SbSlideToActionState extends State<SbSlideToAction> with SingleTickerProviderStateMixin {
  double _dragPosition = 0.0;
  bool _isCompleted = false;
  late AnimationController _springController;
  late Animation<double> _springAnimation;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _springController.addListener(() {
      setState(() {
        _dragPosition = _springAnimation.value;
      });
    });
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isCompleted) return;
    
    setState(() {
      _dragPosition += details.delta.dx;
      
      // Clamp between 0 and max sliding distance (width - height)
      if (_dragPosition < 0) {
        _dragPosition = 0;
      }
      
      final maxDrag = widget.width - widget.height;
      if (_dragPosition > maxDrag) {
        _dragPosition = maxDrag;
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isCompleted) return;

    final maxDrag = widget.width - widget.height;
    
    // If dragged past 80%, complete it
    if (_dragPosition > maxDrag * 0.8) {
      _springAnimation = Tween<double>(begin: _dragPosition, end: maxDrag).animate(
        CurvedAnimation(parent: _springController, curve: Curves.easeOutCubic)
      );
      
      _springController.forward(from: 0.0).then((_) {
        setState(() {
          _isCompleted = true;
        });
        widget.onActionCompleted();
      });
    } else {
      // Snap back to zero
      _springAnimation = Tween<double>(begin: _dragPosition, end: 0.0).animate(
        CurvedAnimation(parent: _springController, curve: Curves.elasticOut)
      );
      _springController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxDrag = widget.width - widget.height;
    final opacity = 1.0 - (_dragPosition / maxDrag).clamp(0.0, 1.0);

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.baseColor,
        borderRadius: BorderRadius.circular(widget.height / 2),
      ),
      child: Stack(
        children: [
          // Background Text
          Center(
            child: Opacity(
              opacity: opacity,
              child: Text(
                widget.text,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ),
          ),
          
          // The filled track that follows the slider
          Container(
            width: _dragPosition + widget.height,
            height: widget.height,
            decoration: BoxDecoration(
              color: widget.slideColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(widget.height / 2),
            ),
          ),
          
          // The Draggable Button
          Positioned(
            left: _dragPosition,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: Container(
                width: widget.height,
                height: widget.height,
                decoration: BoxDecoration(
                  color: widget.slideColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.slideColor.withValues(alpha: 0.4),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ]
                ),
                child: Center(
                  child: _isCompleted 
                      ? const Icon(Icons.check, color: Colors.white)
                      : widget.icon,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
