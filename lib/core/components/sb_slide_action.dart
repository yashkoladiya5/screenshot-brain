import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbSlideAction extends StatefulWidget {
  final String text;
  final Future<bool> Function() onSlideCompleted;
  final IconData icon;
  final double height;

  const SbSlideAction({
    super.key,
    required this.text,
    required this.onSlideCompleted,
    this.icon = Icons.chevron_right_rounded,
    this.height = 64.0,
  });

  @override
  State<SbSlideAction> createState() => _SbSlideActionState();
}

class _SbSlideActionState extends State<SbSlideAction> with SingleTickerProviderStateMixin {
  double _dragPosition = 0.0;
  bool _isLoading = false;
  late AnimationController _animationController;
  final GlobalKey _containerKey = GlobalKey();
  double _containerWidth = 0.0;
  
  static const double _thumbPadding = 4.0;
  double get _thumbSize => widget.height - (_thumbPadding * 2);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.addListener(() {
      setState(() {
        _dragPosition = _animationController.value;
      });
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final renderBox = _containerKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        _containerWidth = renderBox.size.width;
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_isLoading || _containerWidth == 0.0) return;
    
    final maxDrag = _containerWidth - _thumbSize - (_thumbPadding * 2);
    setState(() {
      _dragPosition += details.delta.dx;
      _dragPosition = _dragPosition.clamp(0.0, maxDrag);
    });
  }

  Future<void> _onHorizontalDragEnd(DragEndDetails details) async {
    if (_isLoading || _containerWidth == 0.0) return;
    
    final maxDrag = _containerWidth - _thumbSize - (_thumbPadding * 2);
    
    if (_dragPosition >= maxDrag * 0.9) {
      // Completed slide
      setState(() {
        _dragPosition = maxDrag;
        _isLoading = true;
      });
      
      final success = await widget.onSlideCompleted();
      
      if (mounted) {
        if (!success) {
          // Reset if failed
          _animateToZero();
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      // Did not complete slide, animate back to 0
      _animateToZero();
    }
  }
  
  void _animateToZero() {
    _animationController.value = _dragPosition;
    _animationController.animateTo(0.0, curve: Curves.easeOutBack);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      key: _containerKey,
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(SBRadius.full),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Text
          Opacity(
            opacity: 1.0 - (_containerWidth > 0 ? (_dragPosition / _containerWidth).clamp(0.0, 1.0) : 0.0),
            child: Text(
              widget.text.toUpperCase(),
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          
          // Draggable Thumb
          Positioned(
            left: _thumbPadding + _dragPosition,
            child: GestureDetector(
              onHorizontalDragUpdate: _onHorizontalDragUpdate,
              onHorizontalDragEnd: _onHorizontalDragEnd,
              child: Container(
                width: _thumbSize,
                height: _thumbSize,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _isLoading
                    ? Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : Icon(
                        widget.icon,
                        color: colorScheme.onPrimary,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
