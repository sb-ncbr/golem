import 'package:golem_ui/analysis/motif.dart';
import 'package:golem_ui/genes/gene.dart';

/// Holds the result of a single motif position in the gene
class AnalysisResult {
  /// The gene the motif was found in
  final Gene gene;

  /// The motif that was found
  final Motif motif;

  /// The position of the motif midpoint (in the string, starting from 0)
  final num position;

  /// The raw position of the motif (in the string, starting from 0)
  final num rawPosition;

  /// The concrete motif definition that matched (e.g. 'ACTN')
  final String match;

  /// The actual sequence that matched (e.g. 'ACTA')
  final String matchedSequence;

  /// returns a broader matched sequence
  String get broadMatch {
    final safeSequence = '          ${gene.data}          ';
    return safeSequence.substring(rawPosition.toInt() + 2, rawPosition.toInt() + match.length + 18);
  }

  AnalysisResult({
    required this.gene,
    required this.motif,
    required this.rawPosition,
    required this.position,
    required this.match,
    required this.matchedSequence,
  });
}
