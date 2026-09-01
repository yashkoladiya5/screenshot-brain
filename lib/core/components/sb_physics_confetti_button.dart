import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbPhysicsConfettiButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final int pieceCount;

  const SbPhysicsConfettiButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.pieceCount = 50,
  });

  @override
  State<SbPhysicsConfettiButton> createState() => _SbPhysicsConfettiButtonState();
}

class _SbPhysicsConfettiButtonState extends State<SbPhysicsConfettiButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<_ConfettiPiece> _pieces = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _trigger() {
    widget.onPressed();
    
    _pieces = List.generate(widget.pieceCount, (index) {
      return _ConfettiPiece(
        xOffset: (_random.nextDouble() * 2 - 1) * 150,
        yOffset: -100 - (_random.nextDouble() * 150),
        color: _getRandomColor(),
        size: 5.0 + _random.nextDouble() * 8.0,
        rotation: _random.nextDouble() * math.pi * 2,
        spinSpeed: (_random.nextDouble() - 0.5) * 10,
      );
    });

    _controller.forward(from: 0.0);
  }

  Color _getRandomColor() {
    const List<Color> colors = [
      Colors.red, Colors.blue, Colors.green, Colors.yellow, 
      Colors.purple, Colors.orange, Colors.pink
    ];
    return colors[_random.nextInt(colors.length)];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _trigger,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              if (_controller.value == 0.0 || _controller.value == 1.0) {
                return const SizedBox.shrink();
              }

              final double t = _controller.value;
              
              return Stack(
                clipBehavior: Clip.none,
                children: _pieces.map((piece) {
                  final double friction = Curves.easeOutCubic.transform(t);
                  final double dx = piece.xOffset * friction;
                  
                  final double gravity = 400.0 * (t * t); 
                  final double initialVelocity = piece.yOffset * 2 * t; 
                  final double dy = initialVelocity + gravity;

                  final double opacity = t > 0.7 
                      ? (1.0 - ((t - 0.7) / 0.3)).clamp(0.0, 1.0) 
                      : 1.0;

                  return Transform.translate(
                    offset: Offset(dx, dy),
                    child: Transform.rotate(
                      angle: piece.rotation + (piece.spinSpeed * t),
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
                          width: piece.size,
                          height: piece.size * 0.6, 
                          color: piece.color,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final double scale = _controller.value > 0.0 && _controller.value < 0.2 
                  ? 1.0 - math.sin(_controller.value * math.pi * 5) * 0.1
                  : 1.0;
                  
              return Transform.scale(
                scale: scale,
                child: widget.child,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ConfettiPiece {
  final double xOffset;
  final double yOffset;
  final Color color;
  final double size;
  final double rotation;
  final double spinSpeed;

  _ConfettiPiece({
    required this.xOffset,
    required this.yOffset,
    required this.color,
    required this.size,
    required this.rotation,
    required this.spinSpeed,
  });
}
