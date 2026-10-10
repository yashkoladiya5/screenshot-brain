import 'string_validators.dart';

/// Form-field validators: thin wrappers that turn the boolean checks in
/// [StringValidators] into `String?` error messages suitable for
/// `TextFormField.validator`. Error message semantics match the historical
/// behavior ('X is required' / 'Enter a valid ...').
class ValidatorUtils {
  ValidatorUtils._();

  /// Validates if an email is formatted correctly.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!StringValidators.isValidEmail(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Validates if a password meets minimum security requirements.
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    return null;
  }

  /// Validates if a required field is filled.
  static String? validateRequired(
    String? value, [
    String fieldName = 'This field',
  ]) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Required + maximum length in one validator (e.g. merchant notes).
  static String? validateRequiredWithMaxLength(
    String? value,
    int maxLength, {
    String fieldName = 'This field',
  }) {
    final required = validateRequired(value, fieldName);
    if (required != null) return required;
    if (value!.trim().length > maxLength) {
      return '$fieldName must be at most $maxLength characters';
    }
    return null;
  }

  /// Validates a phone number (E.164 with a 10-digit national fallback).
  static String? validatePhone(String? value, {bool required = true}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'Phone number is required' : null;
    }
    if (!StringValidators.isValidPhone(value)) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  /// Validates a URL (http/https, scheme optional).
  static String? validateUrl(String? value, {bool required = true}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'URL is required' : null;
    }
    if (!StringValidators.isValidUrl(value)) {
      return 'Enter a valid URL';
    }
    return null;
  }

  /// Validates an amount string in any currency format the app extracts
  /// (₹1,29,900 / $1,299.90 / 1.299,90 / 1299).
  static String? validateAmount(String? value, {bool required = true}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'Amount is required' : null;
    }
    if (!StringValidators.isValidAmount(value)) {
      return 'Enter a valid amount';
    }
    return null;
  }
}
