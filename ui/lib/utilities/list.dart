extension IterableExtension<T> on List<T> {
  /// Returns items that are distinct based on the provided function.
  Iterable<T> distinctBy(Object Function(T e) getCompareValue) {
    final idSet = <Object>{};
    final distinct = <T>[];
    for (final item in this) {
      if (idSet.add(getCompareValue(item))) {
        distinct.add(item);
      }
    }

    return distinct;
  }
}
