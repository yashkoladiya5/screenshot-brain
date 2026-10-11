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

  /// Splits the list into consecutive batches of at most [size] elements.
  ///
  /// The last chunk may be shorter. Throws if [size] is not positive.
  /// `[1, 2, 3, 4, 5].chunkBy(2)` -> `[[1, 2], [3, 4], [5]]`.
  List<List<T>> chunkBy(int size) {
    assert(size > 0, 'chunkBy requires a positive size, got $size');
    final chunks = <List<T>>[];
    for (var start = 0; start < length; start += size) {
      final end = start + size > length ? length : start + size;
      chunks.add(sublist(start, end));
    }
    return chunks;
  }

  /// Keeps the first occurrence for every key produced by [keySelector].
  ///
  /// Similar to [uniqueBy] but with an ecosystem-familiar name and a
  /// guaranteed stable (first-wins) choice.
  List<T> distinctBy<K>(K Function(T element) keySelector) {
    final seen = <K>{};
    final result = <T>[];
    for (final element in this) {
      if (seen.add(keySelector(element))) result.add(element);
    }
    return result;
  }

  /// The second element, or null when there are fewer than two items.
  T? get secondOrNull => length > 1 ? this[1] : null;

  /// A copy sorted by [keySelector], leaving the original untouched.
  ///
  /// `[3, 1, 2].sortedBy((e) => e)` -> `[1, 2, 3]`; pass
  /// `descending: true` for reverse order.
  List<T> sortedBy<K extends Comparable<K>>(
    K Function(T element) keySelector, {
    bool descending = false,
  }) {
    final copy = List<T>.of(this);
    copy.sort((a, b) {
      final order = keySelector(a).compareTo(keySelector(b));
      return descending ? -order : order;
    });
    return copy;
  }

  /// Pairs elements with [other], stopping at the shorter of the two lists.
  Iterable<R> zip<U, R>(List<U> other, R Function(T a, U b) transform) sync* {
    final left = iterator;
    final right = other.iterator;
    while (left.moveNext() && right.moveNext()) {
      yield transform(left.current, right.current);
    }
  }
}

extension NumListExtensions<T extends num> on List<T> {
  /// Trailing moving average over a sliding [window], averaging over the
  /// available elements at the start (the window grows to full size).
  ///
  /// `[1, 2, 3, 4].movingAverage(2)` -> `[1.0, 1.5, 2.5, 3.5]`.
  List<double> movingAverage(int window) {
    assert(window > 0, 'movingAverage requires a positive window, got $window');
    final result = <double>[];
    for (var i = 0; i < length; i++) {
      final start = i - window + 1 < 0 ? 0 : i - window + 1;
      var sum = 0.0;
      for (var j = start; j <= i; j++) {
        sum += this[j];
      }
      result.add(sum / (i - start + 1));
    }
    return result;
  }
}
