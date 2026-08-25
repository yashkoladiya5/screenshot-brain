import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design/tokens.dart';

class SbOtpInput extends StatefulWidget {
  final int length;
  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  const SbOtpInput({
    super.key,
    this.length = 6,
    this.onCompleted,
    this.onChanged,
    this.autofocus = true,
  });

  @override
  State<SbOtpInput> createState() => _SbOtpInputState();
}

class _SbOtpInputState extends State<SbOtpInput> {
  late List<FocusNode> _focusNodes;
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(widget.length, (index) => FocusNode());
    _controllers = List.generate(widget.length, (index) => TextEditingController());

    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).requestFocus(_focusNodes[0]);
      });
    }
  }

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    // Collect full string
    String currentCode = _controllers.map((c) => c.text).join();
    widget.onChanged?.call(currentCode);

    // Auto-advance
    if (value.isNotEmpty && index < widget.length - 1) {
      _focusNodes[index].unfocus();
      FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
    }

    // Trigger completion if full
    if (currentCode.length == widget.length) {
      widget.onCompleted?.call(currentCode);
      _focusNodes[index].unfocus();
    }
  }

  void _onKeyEvent(KeyEvent event, int index) {
    // Handle backspace when empty
    if (event is KeyDownEvent && 
        event.logicalKey == LogicalKeyboardKey.backspace && 
        _controllers[index].text.isEmpty && 
        index > 0) {
      _focusNodes[index].unfocus();
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
      _controllers[index - 1].clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.length, (index) {
        return Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: KeyboardListener(
              focusNode: FocusNode(), // Dummy node for listener
              onKeyEvent: (event) => _onKeyEvent(event, index),
              child: TextFormField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                autofocus: widget.autofocus && index == 0,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(1),
                ],
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  counterText: "",
                  filled: true,
                  fillColor: colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: SBSpacing.lg),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(SBRadius.md),
                    borderSide: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(SBRadius.md),
                    borderSide: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(SBRadius.md),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 2.0,
                    ),
                  ),
                ),
                onChanged: (value) => _onChanged(value, index),
              ),
            ),
          ),
        );
      }),
    );
  }
}
