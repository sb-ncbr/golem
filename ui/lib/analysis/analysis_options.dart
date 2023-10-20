/// Options for the analysis
class AnalysisOptions {
  /// The minimum value of the distribution
  final int min;

  /// The maximum value of the distribution
  final int max;

  /// The size of the buckets in the distribution
  final int bucketSize;

  /// The marker to align the distribution to (usually ATG or TSS)
  final String? alignMarker;

  AnalysisOptions({this.min = 0, this.max = 10000, this.bucketSize = 30, this.alignMarker});
}
