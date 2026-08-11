import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbPasswordField extends StatefulWidget {
  final TextEditingController? controller;
  final String hintText;
  final String? Function(String?)? validator;

  const SbPasswordField({
    super.key,
    this.controller,
    this.hintText = 'Password',
    this.validator,
  });

  @override
  State<SbPasswordField> createState() => _SbPasswordFieldState();
}

class _SbPasswordFieldState extends State<SbPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextFormField(
      controller: widget.controller,
      obscureText: _obscureText,
      validator: widget.validator,
      style: theme.textTheme.bodyLarge?.copyWith(
        color: colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: theme.textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        contentPadding: const EdgeInsets.symmetric(horizontal: SBSpacing.md, vertical: SBSpacing.sm),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SBRadius.md),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SBRadius.md),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SBRadius.md),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SBRadius.md),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: colorScheme.onSurfaceVariant,
          ),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        ),
      ),
    );
  }
}
