extension IterableExtensions<T> on Iterable<T> {
  /// Maps each element along with its index.
  Iterable<R> mapIndexed<R>(R Function(int index, T item) f) sync* {
    var index = 0;
    for (final item in this) {
      yield f(index, item);
      index++;
    }
  }

  /// Groups elements by a key returned by the provided function.
  Map<K, List<T>> groupBy<K>(K Function(T item) keyFunction) {
    final map = <K, List<T>>{};
    for (final element in this) {
      final key = keyFunction(element);
      map.putIfAbsent(key, () => []).add(element);
    }
    return map;
  }

  /// Returns the first element matching the predicate, or null if none is found.
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }

  /// Groups by [keySelector] and sums [valueSelector] per group.
  ///
  /// Int sums stay `int`, mixed int/double sums widen to `double` via
  /// normal Dart num arithmetic. Typical use: total spend per category.
  Map<K, num> groupBySum<K>(
    K Function(T element) keySelector,
    num Function(T element) valueSelector,
  ) {
    final result = <K, num>{};
    for (final element in this) {
      final key = keySelector(element);
      result[key] = (result[key] ?? 0) + valueSelector(element);
    }
    return result;
  }
}
