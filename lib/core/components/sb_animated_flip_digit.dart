import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbAnimatedFlipDigit extends StatefulWidget {
  final String initialValue;
  final String newValue;
  final double width;
  final double height;
  final Duration duration;

  const SbAnimatedFlipDigit({
    super.key,
    required this.initialValue,
    required this.newValue,
    this.width = 60.0,
    this.height = 80.0,
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  State<SbAnimatedFlipDigit> createState() => _SbAnimatedFlipDigitState();
}

class _SbAnimatedFlipDigitState extends State<SbAnimatedFlipDigit> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String _currentValue = '';
  String _nextValue = '';

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
    _nextValue = widget.newValue;
    
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    if (_currentValue != _nextValue) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(SbAnimatedFlipDigit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.newValue != oldWidget.newValue) {
      setState(() {
        _currentValue = oldWidget.newValue;
        _nextValue = widget.newValue;
      });
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 5),
          )
        ]
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final angle = _controller.value * math.pi;

          return Stack(
            children: [
              ClipRect(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  heightFactor: 0.5,
                  child: _buildDigitPanel(_nextValue),
                ),
              ),
              
              ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: 0.5,
                  child: _buildDigitPanel(_currentValue),
                ),
              ),

              Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.002) 
                  ..rotateX(angle),
                child: angle < math.pi / 2
                    ? ClipRect(
                        child: Align(
                          alignment: Alignment.topCenter,
                          heightFactor: 0.5,
                          child: _buildDigitPanel(_currentValue),
                        ),
                      )
                    : Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.rotationX(math.pi),
                        child: ClipRect(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            heightFactor: 0.5,
                            child: _buildDigitPanel(_nextValue),
                          ),
                        ),
                      ),
              ),
              
              Center(
                child: Container(
                  height: 2,
                  width: double.infinity,
                  color: Colors.black,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDigitPanel(String text) {
    return Container(
      width: widget.width,
      height: widget.height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: widget.height * 0.7,
          fontWeight: FontWeight.bold,
          height: 1.0, 
        ),
      ),
    );
  }
}
