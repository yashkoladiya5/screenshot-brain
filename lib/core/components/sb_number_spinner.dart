import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design/tokens.dart';

class SbNumberSpinner extends StatefulWidget {
  final int initialValue;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;
  final double width;
  final Color? activeColor;

  const SbNumberSpinner({
    super.key,
    this.initialValue = 0,
    this.min = 0,
    this.max = 100,
    this.step = 1,
    required this.onChanged,
    this.width = 140.0,
    this.activeColor,
  }) : assert(min < max),
       assert(initialValue >= min && initialValue <= max);

  @override
  State<SbNumberSpinner> createState() => _SbNumberSpinnerState();
}

class _SbNumberSpinnerState extends State<SbNumberSpinner> {
  late int _currentValue;
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
    _controller = TextEditingController(text: _currentValue.toString());
    
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _validateAndSubmit(_controller.text);
      }
    });
  }

  @override
  void didUpdateWidget(SbNumberSpinner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue && !_focusNode.hasFocus) {
      _currentValue = widget.initialValue;
      _controller.text = _currentValue.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _validateAndSubmit(String value) {
    int? parsed = int.tryParse(value);
    if (parsed != null) {
      _updateValue(parsed);
    } else {
      _controller.text = _currentValue.toString();
    }
  }

  void _updateValue(int newValue) {
    final clamped = newValue.clamp(widget.min, widget.max);
    if (clamped != _currentValue) {
      setState(() {
        _currentValue = clamped;
        _controller.text = clamped.toString();
      });
      widget.onChanged(_currentValue);
    } else if (newValue != clamped) {
      // Just update text if clamped
      _controller.text = clamped.toString();
    }
  }

  void _increment() {
    _updateValue(_currentValue + widget.step);
    HapticFeedback.lightImpact();
  }

  void _decrement() {
    _updateValue(_currentValue - widget.step);
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final active = widget.activeColor ?? colorScheme.primary;
    
    final bool canDecrement = _currentValue > widget.min;
    final bool canIncrement = _currentValue < widget.max;

    return Container(
      width: widget.width,
      height: 48.0,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(SBRadius.full),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Decrement Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: canDecrement ? _decrement : null,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(SBRadius.full),
                bottomLeft: Radius.circular(SBRadius.full),
              ),
              child: SizedBox(
                width: 40,
                height: double.infinity,
                child: Icon(
                  Icons.remove_rounded,
                  color: canDecrement ? active : colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  size: 20,
                ),
              ),
            ),
          ),
          
          // Divider
          Container(
            width: 1,
            height: 24,
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          
          // Text Input
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              onSubmitted: _validateAndSubmit,
            ),
          ),
          
          // Divider
          Container(
            width: 1,
            height: 24,
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),

          // Increment Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: canIncrement ? _increment : null,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(SBRadius.full),
                bottomRight: Radius.circular(SBRadius.full),
              ),
              child: SizedBox(
                width: 40,
                height: double.infinity,
                child: Icon(
                  Icons.add_rounded,
                  color: canIncrement ? active : colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
