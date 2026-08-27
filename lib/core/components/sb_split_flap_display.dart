import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../design/tokens.dart';

class SbSplitFlapDisplay extends StatefulWidget {
  final String text;
  final TextStyle? textStyle;
  final Color? backgroundColor;
  final double widthPerChar;
  final double height;
  final double spacing;

  const SbSplitFlapDisplay({
    super.key,
    required this.text,
    this.textStyle,
    this.backgroundColor,
    this.widthPerChar = 40.0,
    this.height = 60.0,
    this.spacing = 4.0,
  });

  @override
  State<SbSplitFlapDisplay> createState() => _SbSplitFlapDisplayState();
}

class _SbSplitFlapDisplayState extends State<SbSplitFlapDisplay> {
  // Store previous text to know what characters need to flip
  String _oldText = '';

  @override
  void initState() {
    super.initState();
    _oldText = widget.text;
  }

  @override
  void didUpdateWidget(SbSplitFlapDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) {
      _oldText = oldWidget.text;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pad the shorter string with spaces so they match in length during transition
    String currentText = widget.text;
    String previousText = _oldText;
    
    final int maxLength = math.max(currentText.length, previousText.length);
    currentText = currentText.padRight(maxLength, ' ');
    previousText = previousText.padRight(maxLength, ' ');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxLength, (index) {
        final char = currentText[index];
        final oldChar = previousText[index];
        
        return Padding(
          padding: EdgeInsets.only(right: index == maxLength - 1 ? 0 : widget.spacing),
          child: _SplitFlapCharacter(
            character: char,
            oldCharacter: oldChar,
            width: widget.widthPerChar,
            height: widget.height,
            textStyle: widget.textStyle,
            backgroundColor: widget.backgroundColor,
          ),
        );
      }),
    );
  }
}

class _SplitFlapCharacter extends StatefulWidget {
  final String character;
  final String oldCharacter;
  final double width;
  final double height;
  final TextStyle? textStyle;
  final Color? backgroundColor;

  const _SplitFlapCharacter({
    required this.character,
    required this.oldCharacter,
    required this.width,
    required this.height,
    this.textStyle,
    this.backgroundColor,
  });

  @override
  State<_SplitFlapCharacter> createState() => _SplitFlapCharacterState();
}

class _SplitFlapCharacterState extends State<_SplitFlapCharacter> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String _currentChar = ' ';
  String _nextChar = ' ';

  @override
  void initState() {
    super.initState();
    _currentChar = widget.oldCharacter;
    _nextChar = widget.character;
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    if (_currentChar != _nextChar) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(_SplitFlapCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.character != _nextChar) {
      _currentChar = _nextChar;
      _nextChar = widget.character;
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = widget.backgroundColor ?? theme.colorScheme.surfaceContainerHighest;
    final style = widget.textStyle ?? theme.textTheme.headlineMedium?.copyWith(
      color: theme.colorScheme.onSurface,
      fontWeight: FontWeight.bold,
    );

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.black, // Dark gap behind flaps
        borderRadius: BorderRadius.circular(SBRadius.sm),
      ),
      child: Stack(
        children: [
          // 1. Static Top Half (Shows Next Char)
          ClipRect(
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: 0.5,
              child: _buildPanel(context, _nextChar, bg, style!),
            ),
          ),
          
          // 2. Static Bottom Half (Shows Current Char)
          ClipRect(
            child: Align(
              alignment: Alignment.bottomCenter,
              heightFactor: 0.5,
              child: _buildPanel(context, _currentChar, bg, style),
            ),
          ),

          // 3. Animated Flap
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final double value = _controller.value;
              
              if (value == 0.0) {
                // If not animating, don't show the extra flap
                return const SizedBox.shrink();
              }
              
              // The flap flips from 0 to pi (180 degrees)
              final double angle = value * math.pi;

              // Top flap falls down (0 to pi/2)
              if (value <= 0.5) {
                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.002)
                    ..rotateX(-angle),
                  alignment: Alignment.center,
                  child: ClipRect(
                    child: Align(
                      alignment: Alignment.topCenter,
                      heightFactor: 0.5,
                      child: _buildPanel(context, _currentChar, bg, style),
                    ),
                  ),
                );
              } 
              // Bottom flap falls into place (pi/2 to pi)
              else {
                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.002)
                    ..rotateX(math.pi - angle),
                  alignment: Alignment.center,
                  child: ClipRect(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      heightFactor: 0.5,
                      child: _buildPanel(context, _nextChar, bg, style),
                    ),
                  ),
                );
              }
            },
          ),
          
          // Horizontal divider line
          Align(
            alignment: Alignment.center,
            child: Container(
              height: 2,
              color: Colors.black.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanel(BuildContext context, String char, Color bg, TextStyle style) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(SBRadius.sm),
      ),
      alignment: Alignment.center,
      child: Text(
        char,
        style: style,
      ),
    );
  }
}
