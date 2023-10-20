import 'package:flutter/material.dart';
import 'package:golem_ui/analysis/analysis_result.dart';
import 'package:golem_ui/analysis/distribution.dart';
import 'package:golem_ui/analysis/motif.dart';
import 'package:golem_ui/genes/gene.dart';
import 'package:golem_ui/genes/gene_list.dart';

/// One series in the analysis
class AnalysisSeries {
  /// The [GeneList] analysis was run on
  final GeneList geneList;

  /// The name of the series
  final String name;

  /// The [Motif] that was searched
  final Motif motif;

  /// The color of the series
  final Color color;

  /// The stroke width of the series
  final int stroke;

  /// Whether the series is visible
  final bool visible;

  /// When `true`, analysis will filter overlapping matches
  final bool noOverlaps;

  /// The results of the analysis (i.e. the motifs found in the genes)
  final List<AnalysisResult>? result;

  /// The distribution of the analysis
  final Distribution? distribution;

  AnalysisSeries._({
    required this.geneList,
    required this.noOverlaps,
    required this.motif,
    required this.name,
    required this.color,
    required this.stroke,
    this.visible = true,
    required this.result,
    required this.distribution,
  });

  AnalysisSeries copyWith({Color? color, int? stroke, bool? visible}) {
    return AnalysisSeries._(
      geneList: geneList,
      noOverlaps: noOverlaps,
      name: name,
      motif: motif,
      color: color ?? this.color,
      stroke: stroke ?? this.stroke,
      visible: visible ?? this.visible,
      result: result,
      distribution: distribution,
    );
  }

  /// Runs the analysis on the given [geneList]
  factory AnalysisSeries.run({
    /// The [GeneList] to run the analysis on
    required GeneList geneList,

    /// When `true`, analysis will filter overlapping matches
    noOverlaps = true,

    /// The minimum position to include in the distribution
    required int min,

    /// The maximum position to include in the distribution
    required int max,

    /// The bucket size to use for the distribution
    required int bucketSize,

    /// The [Motif] to search for
    required Motif motif,

    /// The name of the series
    required String name,

    /// The color of the series
    required Color color,

    /// What alignment market to use (normally ATG or TSS)
    String? alignMarker,

    /// The stroke width of the series
    int? stroke,

    /// Whether the series is visible
    bool visible = true,
  }) {
    /// find the matches
    List<AnalysisResult> results = [];
    for (var gene in geneList.genes) {
      results.addAll(_findMatches(gene, motif, noOverlaps));
    }

    /// calculate the distribution
    final distribution = Distribution(
      min: min,
      max: max,
      bucketSize: bucketSize,
      alignMarker: alignMarker,
      name: name,
      color: color,
    )..run(results, geneList.genes.length);

    return AnalysisSeries._(
      geneList: geneList,
      noOverlaps: noOverlaps,
      motif: motif,
      name: name,
      color: color,
      stroke: stroke ?? 4,
      result: results,
      distribution: distribution,
    );
  }

  /// Get [result] as a map of geneId to list of [AnalysisResult] instead of a List.
  Map<String, List<AnalysisResult>> get resultsMap {
    Map<String, List<AnalysisResult>> map = {};
    for (final item in result!) {
      if (!map.containsKey(item.gene.geneId)) {
        map[item.gene.geneId] = [];
      }
      map[item.gene.geneId]!.add(item);
    }
    return map;
  }

  static List<AnalysisResult> _findMatches(Gene gene, Motif motif, bool noOverlaps) {
    List<AnalysisResult> result = [];
    final definitions = {
      ...motif.regExp,
      ...motif.reverseComplementRegExp,
    };
    for (final definition in definitions.keys) {
      final regexp = definitions[definition]!;
      final matches = regexp.allMatches(gene.data).map((match) {
        final midMatchDelta = (match.group(0)!.length / 2).floor();
        return AnalysisResult(
          gene: gene,
          motif: motif,
          rawPosition: match.start,
          position: match.start + midMatchDelta,
          match: definition,
          matchedSequence: match.group(0)!,
        );
      }).toList();
      result.addAll(matches);
    }
    return noOverlaps ? filterOverlappingMatches(result) : result;
  }

  /// Filter out matches that overlap each other
  static List<AnalysisResult> filterOverlappingMatches(List<AnalysisResult> list) {
    list.sort(
      (a, b) => a.rawPosition.compareTo(b.rawPosition),
    );

    final List<AnalysisResult> excludedResults = [];
    final List<AnalysisResult> includedResults = [];

    for (final result in list) {
      if (excludedResults.contains(result)) continue;
      includedResults.add(result);
      final overlaps = list.where((e) =>
          result != e &&
          e.rawPosition >= result.rawPosition &&
          e.rawPosition < result.rawPosition + result.match.length);
      excludedResults.addAll(overlaps);
    }
    assert(includedResults.length + excludedResults.length == list.length);
    return includedResults;
  }

  /// Get a list of patterns that can be used drill down on the analysis
  List<DrillDownResult> drillDown(String? pattern) {
    final filteredResult = pattern == null
        ? result!
        : result!.where((e) => Motif.toRegExp(pattern, true).hasMatch(e.matchedSequence)).toList();
    List<String> testPatterns;
    if (pattern != null) {
      testPatterns = [
        for (int i = 0; i < pattern.length; i++)
          for (final code in Motif.drillDownCodes(pattern[i]))
            '${pattern.substring(0, i)}$code${pattern.substring(i + 1)}',
      ];
    } else {
      testPatterns = [
        ...motif.definitions,
        ...motif.reverseDefinitions,
      ];
    }
    Map<String, int> counts = {};
    for (final testPattern in testPatterns) {
      counts[testPattern] =
          filteredResult.where((e) => Motif.toRegExp(testPattern, true).hasMatch(e.matchedSequence)).length;
    }
    final List<DrillDownResult> drillDownResults = [
      for (final testPattern in counts.keys)
        DrillDownResult(
          testPattern,
          counts[testPattern]!,
          counts[testPattern]! / filteredResult.length,
          counts[testPattern]! / result!.length,
        ),
    ];
    drillDownResults.sort((a, b) => b.count.compareTo(a.count));
    return drillDownResults;
  }
}

/// The result of a drill down
class DrillDownResult {
  final String pattern;
  final int count;
  final double share;
  final double shareOfAll;

  DrillDownResult(this.pattern, this.count, this.share, this.shareOfAll);
}
