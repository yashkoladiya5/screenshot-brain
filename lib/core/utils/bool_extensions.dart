extension BoolExtensions on bool {
  /// Converts the boolean to an integer (true = 1, false = 0).
  int toInt() => this ? 1 : 0;

  /// Returns [onTrue] if true, otherwise [onFalse].
  T fold<T>(T onTrue, T onFalse) {
    return this ? onTrue : onFalse;
  }

  /// Returns the string "Yes" if true, "No" if false.
  String toYesNo() => this ? 'Yes' : 'No';

  /// Returns the string "On" if true, "Off" if false.
  String toOnOff() => this ? 'On' : 'Off';
  
  /// Toggles the current boolean value.
  bool toggle() => !this;
}

extension NullableBoolExtensions on bool? {
  /// Safely returns false if the boolean is null.
  bool get orFalse => this ?? false;

  /// Safely returns true if the boolean is null.
  bool get orTrue => this ?? true;
}
