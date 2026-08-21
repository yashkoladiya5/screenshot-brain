import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbSlidingPanel extends StatefulWidget {
  final Widget child;
  final Widget panelContent;
  final double panelHeight;

  const SbSlidingPanel({
    super.key,
    required this.child,
    required this.panelContent,
    this.panelHeight = 300.0,
  });

  @override
  State<SbSlidingPanel> createState() => _SbSlidingPanelState();
}

class _SbSlidingPanelState extends State<SbSlidingPanel> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePanel() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Stack(
      children: [
        widget.child,
        
        // Backdrop overlay
        if (_isOpen || _controller.isAnimating)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return IgnorePointer(
                ignoring: !_isOpen,
                child: GestureDetector(
                  onTap: _togglePanel,
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.3 * _controller.value),
                  ),
                ),
              );
            },
          ),
          
        // The Sliding Panel
        Align(
          alignment: Alignment.bottomCenter,
          child: AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              return FractionalTranslation(
                translation: Offset(0, _slideAnimation.value),
                child: child,
              );
            },
            child: Container(
              height: widget.panelHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(SBRadius.xl),
                  topRight: Radius.circular(SBRadius.xl),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  )
                ],
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _togglePanel,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: SBSpacing.md),
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(SBRadius.full),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: widget.panelContent,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
