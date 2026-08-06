import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbTextArea extends StatelessWidget {
  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final int minLines;
  final int maxLines;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  const SbTextArea({
    super.key,
    required this.label,
    this.hintText,
    this.controller,
    this.minLines = 3,
    this.maxLines = 5,
    this.errorText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: SBSpacing.xs),
        TextField(
          controller: controller,
          onChanged: onChanged,
          minLines: minLines,
          maxLines: maxLines,
          keyboardType: TextInputType.multiline,
          style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            errorText: errorText,
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: SBSpacing.md, vertical: SBSpacing.md),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SBRadius.md),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SBRadius.md),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SBRadius.md),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SBRadius.md),
              borderSide: BorderSide(color: colorScheme.error, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SBRadius.md),
              borderSide: BorderSide(color: colorScheme.error, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
