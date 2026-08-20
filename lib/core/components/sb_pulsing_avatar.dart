import 'package:flutter/material.dart';
import 'sb_circular_avatar.dart';

class SbPulsingAvatar extends StatefulWidget {
  final String imageUrl;
  final double size;
  final Color pulseColor;
  final Duration duration;
  final bool isPulsing;

  const SbPulsingAvatar({
    super.key,
    required this.imageUrl,
    this.size = 56.0,
    this.pulseColor = Colors.blue,
    this.duration = const Duration(milliseconds: 1500),
    this.isPulsing = true,
  });

  @override
  State<SbPulsingAvatar> createState() => _SbPulsingAvatarState();
}

class _SbPulsingAvatarState extends State<SbPulsingAvatar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    
    _animation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    if (widget.isPulsing) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(SbPulsingAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing != oldWidget.isPulsing) {
      if (widget.isPulsing) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (widget.isPulsing)
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final scale = _animation.value;
              // Fade out as it expands
              final opacity = (1.4 - scale).clamp(0.0, 0.4) / 0.4; // 1.0 down to 0.0
              
              return Container(
                width: widget.size * scale,
                height: widget.size * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.pulseColor.withValues(alpha: opacity * 0.5),
                ),
              );
            },
          ),
        SbCircularAvatar(
          imageUrl: widget.imageUrl,
          size: widget.size,
        ),
      ],
    );
  }
}
