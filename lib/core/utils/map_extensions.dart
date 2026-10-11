extension MapExtensions<K, V> on Map<K, V> {
  /// Safely gets a value of type T from the map, or null if it doesn't exist or is the wrong type.
  T? getAs<T>(K key) {
    final value = this[key];
    if (value is T) {
      return value;
    }
    return null;
  }

  /// Removes all null values from the map.
  Map<K, V> compact() {
    final newMap = <K, V>{};
    forEach((key, value) {
      if (value != null) {
        newMap[key] = value;
      }
    });
    return newMap;
  }

  /// Builds a new map with keys transformed by [transform].
  ///
  /// When two keys map to the same new key, the later entry wins unless
  /// [onCollision] is given, which chooses between the existing and the
  /// incoming value. Iteration order of the source map decides "later".
  Map<K2, V> mapKeys<K2>(
    K2 Function(K key, V value) transform, {
    V Function(V existing, V incoming)? onCollision,
  }) {
    final result = <K2, V>{};
    forEach((key, value) {
      final newKey = transform(key, value);
      if (onCollision != null && result.containsKey(newKey)) {
        result[newKey] = onCollision(result[newKey] as V, value);
      } else {
        result[newKey] = value;
      }
    });
    return result;
  }

  /// Builds a new map with the same keys and values transformed by [transform].
  Map<K, V2> mapValues<V2>(V2 Function(K key, V value) transform) {
    final result = <K, V2>{};
    forEach((key, value) {
      result[key] = transform(key, value);
    });
    return result;
  }

  /// Swaps keys and values.
  ///
  /// Duplicate values collapse into one key; the last entry wins unless
  /// [onCollision] chooses between the existing and incoming original key.
  Map<V, K> invert({K Function(K existing, K incoming)? onCollision}) {
    final result = <V, K>{};
    forEach((key, value) {
      if (onCollision != null && result.containsKey(value)) {
        result[value] = onCollision(result[value] as K, key);
      } else {
        result[value] = key;
      }
    });
    return result;
  }
}

extension ComparableValueMapExtensions<K, V extends Comparable<V>>
    on Map<K, V> {
  /// Returns a new map with entries ordered by their values.
  ///
  /// Insertion order of a Dart map is preserved, so the result of iterating
  /// this map follows the sorted order.
  Map<K, V> sortByValue({bool descending = false}) {
    final entries = this.entries.toList();
    entries.sort((a, b) {
      final order = a.value.compareTo(b.value);
      return descending ? -order : order;
    });
    return Map<K, V>.fromEntries(entries);
  }
}

extension DeepMergeMapExtensions on Map<String, dynamic> {
  /// Recursively merges [other] into a copy of this map; values from
  /// [other] win, except when both sides hold a `Map<String, dynamic>`,
  /// in which case the nested maps are merged the same way.
  ///
  /// Suited for JSON-shaped settings documents. Lists are replaced whole.
  Map<String, dynamic> deepMerge(Map<String, dynamic> other) {
    final result = Map<String, dynamic>.of(this);
    other.forEach((key, value) {
      final existing = result[key];
      if (existing is Map<String, dynamic> && value is Map<String, dynamic>) {
        result[key] = existing.deepMerge(value);
      } else {
        result[key] = value;
      }
    });
    return result;
  }
}
