import 'package:flutter/material.dart';

class SbAnimatedToastMessage extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final Duration displayDuration;
  final VoidCallback onDismissed;

  const SbAnimatedToastMessage({
    super.key,
    required this.message,
    required this.onDismissed,
    this.icon = Icons.info_outline,
    this.backgroundColor = const Color(0xFF333333),
    this.textColor = Colors.white,
    this.displayDuration = const Duration(seconds: 3),
  });

  /// Static helper to easily show a toast on top of everything
  static void show(
    BuildContext context, {
    required String message,
    IconData icon = Icons.info_outline,
    Color backgroundColor = const Color(0xFF333333),
    Color textColor = Colors.white,
    Duration displayDuration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 20, // SafeArea + 20
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: SbAnimatedToastMessage(
            message: message,
            icon: icon,
            backgroundColor: backgroundColor,
            textColor: textColor,
            displayDuration: displayDuration,
            onDismissed: () {
              entry.remove();
            },
          ),
        ),
      ),
    );

    overlay.insert(entry);
  }

  @override
  State<SbAnimatedToastMessage> createState() => _SbAnimatedToastMessageState();
}

class _SbAnimatedToastMessageState extends State<SbAnimatedToastMessage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Slide down from top
    _slideAnimation = Tween<double>(begin: -100.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack), // Bouncy entrance
      ),
    );

    // Scale up slightly for impact
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    // Fade out when leaving
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
      ),
    );

    _playSequence();
  }

  Future<void> _playSequence() async {
    // 1. Animate in
    await _controller.animateTo(0.6);
    
    // 2. Wait for display duration
    await Future.delayed(widget.displayDuration);
    
    // 3. Ensure we are still mounted before animating out
    if (mounted) {
      // Animate out (fade and slide up slightly)
      await _controller.animateTo(1.0);
      widget.onDismissed();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // If we are in the second half of animation (leaving), we slide up slightly
        final double currentSlide = _controller.value > 0.6 
            ? Tween<double>(begin: 0.0, end: -30.0).transform((_controller.value - 0.6) / 0.4)
            : _slideAnimation.value;

        return Transform.translate(
          offset: Offset(0, currentSlide),
          child: Transform.scale(
            scale: _controller.value > 0.6 ? 1.0 : _scaleAnimation.value,
            child: Opacity(
              // Only fade when leaving or entering
              opacity: _controller.value < 0.2 
                  ? (_controller.value / 0.2) 
                  : _opacityAnimation.value,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: BorderRadius.circular(30.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 10),
                    )
                  ]
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.icon,
                      color: widget.textColor,
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        widget.message,
                        style: TextStyle(
                          color: widget.textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
