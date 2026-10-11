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

  /// Returns [value] when this boolean is true.
  ///
  /// When false, returns [orElse]; if [orElse] is missing or not a [T],
  /// a [StateError] is thrown. For nullable [T] a null [orElse] is valid.
  ///
  /// Example: `true.thenV(5)` -> `5`, `false.thenV(5, orElse: 6)` -> `6`.
  T thenV<T>(T value, {T? orElse}) {
    if (this) return value;
    if (orElse is T) return orElse;
    throw StateError(
      'thenV called on `false` without a non-null orElse of type $T',
    );
  }

  /// Flips the value only when [condition] is true, otherwise keeps it.
  ///
  /// Handy for "toggle if enabled" style state updates:
  /// `visible = visible.flipIf(userCanToggle)`.
  bool flipIf(bool condition) => condition ? !this : this;

  /// Logical implication: `a.implies(b)` is equivalent to `!a || b`.
  ///
  /// Useful for validation rules such as
  /// `hasReceipt.implies(receiptPath != null)`.
  bool implies(bool other) => !this || other;
}

extension NullableBoolExtensions on bool? {
  /// Safely returns false if the boolean is null.
  bool get orFalse => this ?? false;

  /// Safely returns true if the boolean is null.
  bool get orTrue => this ?? true;
}
