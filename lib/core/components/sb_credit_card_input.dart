import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design/tokens.dart';

class SbCreditCardInput extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final String? Function(String?)? validator;

  const SbCreditCardInput({
    super.key,
    this.controller,
    this.hintText = '0000 0000 0000 0000',
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(16),
        _CreditCardFormatter(),
      ],
      validator: validator,
      style: theme.textTheme.bodyLarge?.copyWith(
        color: colorScheme.onSurface,
        letterSpacing: 2.0, // Wider letter spacing for CC numbers
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: theme.textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          letterSpacing: 2.0,
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
        prefixIcon: Icon(
          Icons.credit_card_rounded,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _CreditCardFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    // Regroup from the digits only. The old loop walked the incoming string,
    // which still carries the separators this formatter inserted, and added a
    // space after every 4th *character*: '1234 5678' + '9' came back as
    // '1234  56,78 9'-style double spaces with the groups drifting by one.
    final digits = text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }

    final string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}
