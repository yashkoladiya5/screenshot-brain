extension ListExtensions<T> on List<T> {
  /// Returns the element at the given index if it exists, otherwise returns null.
  T? elementAtOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }

  /// Returns a new list with unique elements based on the provided selector.
  List<T> uniqueBy<K>(K Function(T) selector) {
    final seen = <K>{};
    return where((element) => seen.add(selector(element))).toList();
  }

  /// Separates the list by the given separator builder.
  List<T> separatedBy(T Function(int index) separatorBuilder) {
    if (isEmpty) return this;
    final result = <T>[];
    for (var i = 0; i < length; i++) {
      result.add(this[i]);
      if (i < length - 1) {
        result.add(separatorBuilder(i));
      }
    }
    return result;
  }
}
