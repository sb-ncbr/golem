import 'package:flutter/material.dart';
import 'package:golem_ui/analysis/analysis_result.dart';

/// Holds the result of series distribution
class Distribution {
  /// The minimum position to include in the distribution
  final int min;

  /// The maximum position to include in the distribution
  final int max;

  /// The bucket size to use for the distribution
  final int bucketSize;

  /// The marker to which data is aligned (usually ATG or TSS)
  final String? alignMarker;

  /// The name of the series
  final String name;

  /// The color of the series
  final Color? color;

  Map<int, int>? _counts;

  late int _totalCount;

  /// Total count of motifs
  int get totalCount => _totalCount;

  Map<int, Set<String>>? _genes;

  late int _totalGenesCount;

  /// Total count of genes
  int get totalGenesCount => _totalGenesCount;

  late int _totalGenesWithMotifCount;

  /// Total count of genes with motif
  int get totalGenesWithMotifCount => _totalGenesWithMotifCount;

  Distribution({
    required this.min,
    required this.max,
    required this.bucketSize,
    this.alignMarker,
    required this.name,
    required this.color,
  });

  /// Returns the distribution as a list of [DistributionDataPoint]
  List<DistributionDataPoint>? get dataPoints {
    if (_counts == null || _genes == null) return null;
    return [
      for (var i = 0; i < (max - min) ~/ bucketSize; i++)
        DistributionDataPoint(
          min: min + i * bucketSize,
          max: min + (i + 1) * bucketSize,
          count: _counts![i] ?? 0,
          percent: (_counts![i] ?? 0) / _totalCount,
          genes: _genes![i] ?? {},
          genesPercent: (_genes![i]?.length ?? 0) / _totalGenesCount,
        ),
    ];
  }

  /// Calculates the distribution from the list of [results]
  void run(List<AnalysisResult> results, int totalGenesCount) {
    Map<int, int> counts = {};
    Map<int, Set<String>> geneCounts = {};
    for (final result in results) {
      final position = result.position - (alignMarker != null ? result.gene.markers[alignMarker]! : 0);
      if (position < min || position > max) {
        continue;
      }
      final intervalIndex = (position - min) ~/ bucketSize;
      counts[intervalIndex] = (counts[intervalIndex] ?? 0) + 1;
      if (geneCounts[intervalIndex] == null) {
        geneCounts[intervalIndex] = {};
      }
      geneCounts[intervalIndex]!.add(result.gene.geneId);
    }
    _counts = counts;
    _genes = {
      for (final key in geneCounts.keys) key: geneCounts[key]!,
    };
    _totalCount = results.length;
    _totalGenesCount = totalGenesCount;
    _totalGenesWithMotifCount = results.map((result) => result.gene.geneId).toSet().length;
  }
}

/// Holds a datapoint of the distribution
class DistributionDataPoint {
  /// The minimum position of the interval (inclusive)
  final int min;

  /// The maximum position of the interval (exclusive)
  final int max;

  /// The number of matches in the interval
  final int count;

  /// The percentage of matches in the interval
  final double percent;

  /// The genes with the motif in the interval
  final Set<String> genes;

  /// The percentage of genes with the motif in the interval
  final double genesPercent;
  DistributionDataPoint(
      {required this.min,
      required this.max,
      required this.count,
      required this.percent,
      required this.genes,
      required this.genesPercent});

  int get genesCount => genes.length;

  String get label {
    return '<$min; $max)';
  }
}
