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
}
