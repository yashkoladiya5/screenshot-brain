extension ObjectExtensions<T> on T {
  /// Kotlin-style `let` function.
  /// Executes the given function [block] with this value as its argument and returns its result.
  R let<R>(R Function(T) block) {
    return block(this);
  }

  /// Kotlin-style `also` function.
  /// Executes the given function [block] with this value as its argument and returns this value.
  T also(void Function(T) block) {
    block(this);
    return this;
  }
}

extension NullableObjectExtensions<T extends Object> on T? {
  /// Kotlin-style `let` for nullable objects.
  /// Executes the given function [block] only if the object is not null.
  R? letIfNotNull<R>(R Function(T) block) {
    if (this != null) {
      return block(this as T);
    }
    return null;
  }
}
