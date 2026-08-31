import 'package:flutter/material.dart';

enum ButtonState { idle, loading, success, error }

class SbProgressButton extends StatefulWidget {
  final Future<void> Function() onPressed;
  final String idleText;
  final String successText;
  final String errorText;
  final double width;
  final double height;
  final Color baseColor;

  const SbProgressButton({
    super.key,
    required this.onPressed,
    this.idleText = 'Submit',
    this.successText = 'Done!',
    this.errorText = 'Failed',
    this.width = 200.0,
    this.height = 50.0,
    this.baseColor = Colors.blueAccent,
  });

  @override
  State<SbProgressButton> createState() => _SbProgressButtonState();
}

class _SbProgressButtonState extends State<SbProgressButton> with TickerProviderStateMixin {
  ButtonState _state = ButtonState.idle;
  
  late AnimationController _widthController;
  late Animation<double> _widthAnimation;
  
  late AnimationController _colorController;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    
    // Controls shrinking to a circle
    _widthController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _widthAnimation = Tween<double>(begin: widget.width, end: widget.height).animate(
      CurvedAnimation(parent: _widthController, curve: Curves.easeInOutCubic),
    );

    // Controls color transitions for success/error
    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _colorAnimation = ColorTween(begin: widget.baseColor, end: Colors.green).animate(_colorController);
  }

  @override
  void dispose() {
    _widthController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _handlePress() async {
    if (_state != ButtonState.idle) return;

    setState(() {
      _state = ButtonState.loading;
    });
    
    // Shrink button to circle
    await _widthController.forward();
    
    try {
      await widget.onPressed();
      // Success!
      _colorAnimation = ColorTween(begin: widget.baseColor, end: Colors.green).animate(_colorController);
      _colorController.forward();
      setState(() {
        _state = ButtonState.success;
      });
    } catch (e) {
      // Error!
      _colorAnimation = ColorTween(begin: widget.baseColor, end: Colors.red).animate(_colorController);
      _colorController.forward();
      setState(() {
        _state = ButtonState.error;
      });
    }
    
    // Expand back to full width
    await _widthController.reverse();
    
    // Wait for user to read the message, then reset
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      _colorController.reverse();
      setState(() {
        _state = ButtonState.idle;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_widthController, _colorController]),
      builder: (context, child) {
        return GestureDetector(
          onTap: _handlePress,
          child: Container(
            width: _widthAnimation.value,
            height: widget.height,
            decoration: BoxDecoration(
              color: _colorAnimation.value,
              borderRadius: BorderRadius.circular(widget.height / 2),
              boxShadow: [
                BoxShadow(
                  color: (_colorAnimation.value ?? Colors.black).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            ),
            child: Center(
              child: _buildContent(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    if (_state == ButtonState.loading && _widthController.isCompleted) {
      // Show spinner when fully shrunk
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 3,
        ),
      );
    }
    
    // Only show text when fully expanded (or mostly expanded)
    if (_widthController.value < 0.2) {
      String text = widget.idleText;
      IconData? icon;
      
      if (_state == ButtonState.success) {
        text = widget.successText;
        icon = Icons.check;
      } else if (_state == ButtonState.error) {
        text = widget.errorText;
        icon = Icons.close;
      }

      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.fade,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      );
    }
    
    return const SizedBox.shrink(); // Empty during transition
  }
}
