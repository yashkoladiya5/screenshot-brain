import 'package:flutter/material.dart';
import 'dart:async';

class SbTypingText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration typingSpeed;
  final Duration cursorBlinkSpeed;
  final bool showCursor;
  final String cursorChar;
  final Color? cursorColor;
  final VoidCallback? onCompleted;
  final TextAlign? textAlign;

  const SbTypingText(
    this.text, {
    super.key,
    this.style,
    this.typingSpeed = const Duration(milliseconds: 50),
    this.cursorBlinkSpeed = const Duration(milliseconds: 500),
    this.showCursor = true,
    this.cursorChar = '|',
    this.cursorColor,
    this.onCompleted,
    this.textAlign,
  });

  @override
  State<SbTypingText> createState() => _SbTypingTextState();
}

class _SbTypingTextState extends State<SbTypingText> with SingleTickerProviderStateMixin {
  late String _displayedText;
  late int _currentIndex;
  Timer? _typingTimer;
  
  late AnimationController _cursorController;
  late Animation<double> _cursorAnimation;

  @override
  void initState() {
    super.initState();
    _displayedText = '';
    _currentIndex = 0;

    _cursorController = AnimationController(
      vsync: this,
      duration: widget.cursorBlinkSpeed,
    )..repeat(reverse: true);

    _cursorAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cursorController, curve: Curves.linear),
    );

    _startTyping();
  }

  @override
  void didUpdateWidget(SbTypingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) {
      _typingTimer?.cancel();
      _displayedText = '';
      _currentIndex = 0;
      _startTyping();
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _cursorController.dispose();
    super.dispose();
  }

  void _startTyping() {
    _typingTimer = Timer.periodic(widget.typingSpeed, (timer) {
      if (_currentIndex < widget.text.length) {
        setState(() {
          _currentIndex++;
          _displayedText = widget.text.substring(0, _currentIndex);
        });
      } else {
        timer.cancel();
        widget.onCompleted?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = widget.style ?? theme.textTheme.bodyMedium;
    final cColor = widget.cursorColor ?? theme.colorScheme.primary;

    return RichText(
      textAlign: widget.textAlign ?? TextAlign.start,
      text: TextSpan(
        children: [
          TextSpan(
            text: _displayedText,
            style: textStyle,
          ),
          if (widget.showCursor)
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: AnimatedBuilder(
                animation: _cursorAnimation,
                builder: (context, child) {
                  return Opacity(
                    // Create a stepped blink effect rather than smooth fade
                    opacity: _cursorAnimation.value > 0.5 ? 1.0 : 0.0,
                    child: Text(
                      widget.cursorChar,
                      style: textStyle?.copyWith(
                        color: cColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
