class StringValidators {
  /// Checks if a string contains at least one uppercase letter.
  static bool hasUpperCase(String value) {
    return value.contains(RegExp(r'[A-Z]'));
  }

  /// Checks if a string contains at least one lowercase letter.
  static bool hasLowerCase(String value) {
    return value.contains(RegExp(r'[a-z]'));
  }

  /// Checks if a string contains at least one digit.
  static bool hasDigit(String value) {
    return value.contains(RegExp(r'[0-9]'));
  }

  /// Checks if a string contains at least one special character.
  static bool hasSpecialCharacter(String value) {
    return value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  }

  /// Checks if a string is a valid URL.
  static bool isValidUrl(String value) {
    final urlRegExp = RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
    );
    return urlRegExp.hasMatch(value);
  }
}
