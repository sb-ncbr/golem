import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:golem_ui/analysis/organism.dart';
import 'package:golem_ui/genes/stage_selection.dart';
import 'package:golem_ui/genes/gene.dart';
import 'package:golem_ui/utilities/series.dart';

/// Holds a list of genes
class GeneList extends Equatable {
  /// Name of the organism. This is used for auto detecting colors and stage order
  final Organism? organism;

  final List<dynamic> errors;

  /// List of stages. Key is stage name, value is a list of Gene.ids for that stage (unvalidated) This can be `null` if not supplied
  final Map<String, Set<String>>? stages;

  /// Transcription rates for each stage
  ///
  /// Key is stage name, value is a [Series] of all transcription rates for that stage
  /// Used in calculating percentiles.
  final Map<String, Series> transcriptionRates;

  final Map<String, Color>? _colors;
  final List<Gene> _genes;

  @override
  List<Object?> get props => [genes, transcriptionRates];

  List<Gene> get genes => _genes;

  /// Map of colors to be applied for given stage
  Map<String, Color> get colors => _colors ?? _colorsFromStages();

  /// Stroke width for stages
  Map<String, int> get stroke => _strokeFromStages();

  GeneList._({
    required this.organism,
    required List<Gene> genes,
    required this.stages,
    required Map<String, Color>? colors,
    required this.errors,
  })  : _genes = genes,
        transcriptionRates = _transcriptionRates(genes),
        _colors = colors;

  /// Parse fasta file into list of genes.
  ///
  /// Feed the result to [GeneList.fromList]
  static Future<(List<Gene>, List<dynamic>)> parseFasta(String data, Function(double progress) progressCallback) async {
    final chunks = data.split('>');
    final genes = <Gene>[];
    final errors = <dynamic>[];
    int cnt = 0;
    for (final chunk in chunks) {
      // Insert a delay so that we do not block the UI thread for too long
      if (cnt++ % 1000 == 0) {
        progressCallback(cnt / chunks.length);
        await Future.delayed(const Duration(milliseconds: 20));
      }
      if (chunk.isEmpty) {
        continue;
      }
      final lines = '>$chunk'.split('\n');
      try {
        final gene = Gene.fromFasta(lines);
        genes.add(gene);
      } catch (error) {
        errors.add(error);
      }
    }
    debugPrint('.fasta parsing completed with ${genes.length} genes and ${errors.length} errors');
    return (genes, errors);
  }

  /// Takes the first transcript from each gene only
  ///
  /// Feed the result to [GeneList.fromList]
  static Future<(List<Gene>, List<dynamic>)> takeSingleTranscript(
      List<Gene> genes, List<dynamic> errors, Function(double progress) progressCallback) async {
    Map<String, List<String>> keys = {};

    for (final gene in genes) {
      final geneCode = gene.geneCode;
      keys[geneCode] = [...(keys[geneCode] ?? []), gene.geneId];
    }

    List<Gene> merged = [];
    int cnt = 0;
    for (final key in keys.keys) {
      // Insert a delay so that we do not block the UI thread for too long
      if (cnt++ % 1000 == 0) {
        progressCallback(cnt / keys.length);
        await Future.delayed(const Duration(milliseconds: 20));
      }
      keys[key]!.sort();
      final first = keys[key]!.first;
      merged.add(genes.firstWhere((gene) => gene.geneId == first));
    }
    debugPrint('.fasta transcript filtering completed with ${merged.length} genes and ${errors.length} errors');
    return (merged, errors);
  }

  /// Create a new GeneList from list of genes.
  ///
  /// Obtain the list by calling [parseFasta]
  factory GeneList.fromList({required List<Gene> genes, required List<dynamic> errors, Organism? organism}) {
    GeneList result;
    result = GeneList._(
      organism: organism,
      genes: genes,
      errors: errors,
      stages: null,
      colors: null,
    );
    debugPrint('.fasta analysis completed with ${result.genes.length} genes and ${result.errors.length} errors');
    return result;
  }

  GeneList copyWith({
    Organism? organism,
    List<Gene>? genes,
    Map<String, Set<String>>? stages,
    Map<String, Color>? colors,
    List<dynamic>? errors,
  }) {
    return GeneList._(
      organism: organism ?? this.organism,
      genes: genes ?? _genes,
      stages: stages ?? this.stages,
      colors: colors ?? this.colors,
      errors: errors ?? this.errors,
    );
  }

  /// Get keys for all stages
  ///
  /// Uses [stages] or [transcriptionRates]
  /// Returns stages ordered by developments stage for known organisms
  List<String> get stageKeys {
    final detected = stages != null ? stages!.keys.toList() : transcriptionRates.keys.toList();
    final List<String> result = [];
    if (organism?.stages.isNotEmpty == true) {
      for (final stage in organism!.stages) {
        if (detected.contains(stage.stage)) {
          result.add(stage.stage);
        }
      }
      for (final stage in detected) {
        if (!result.contains(stage)) {
          result.add(stage);
        }
      }
    } else {
      result.addAll(detected);
    }
    return result;
  }

  /// Get keys for stages that should be selected by default
  List<String> get defaultSelectedStageKeys {
    final keys = stageKeys;
    if (organism?.stages.isNotEmpty == true) {
      return organism!.stages.where((s) => s.isCheckedByDefault && keys.contains(s.stage)).map((s) => s.stage).toList();
    }
    return keys;
  }

  /// Filters gene for given [stage]. Either uses [stages] or applies [stageSelection], if specified
  GeneList filter({required String stage, required StageSelection stageSelection}) {
    assert(stageKeys.contains(stage), 'Unknown stage $stage');
    if (stages != null) {
      assert(stages![stage] != null && stages![stage]!.isNotEmpty, 'No genes for stage $stage');
      final ids = stages![stage]!;
      return copyWith(genes: genes.where((gene) => ids.contains(gene.geneId)).toList());
    }

    assert(stageSelection.selectedStages.contains(stage));
    genes.sort((a, b) => a.transcriptionRates[stage]!.compareTo(b.transcriptionRates[stage]!));
    if (stageSelection.selection == FilterSelection.percentile) {
      if (stageSelection.strategy == FilterStrategy.top) {
        return copyWith(genes: _topPercentile(stageSelection.percentile!, stage));
      } else {
        return copyWith(genes: _bottomPercentile(stageSelection.percentile!, stage));
      }
    } else {
      if (stageSelection.strategy == FilterStrategy.top) {
        return copyWith(genes: _top(stageSelection.count!));
      } else {
        return copyWith(genes: _bottom(stageSelection.count!));
      }
    }
  }

  static Map<String, Series> _transcriptionRates(List<Gene> genes) {
    final result = <String, List<num>>{};
    for (final gene in genes) {
      for (final key in gene.transcriptionRates.keys) {
        if (result.containsKey(key)) {
          result[key]!.add(gene.transcriptionRates[key]!);
        } else {
          result[key] = [gene.transcriptionRates[key]!];
        }
      }
    }
    return {
      for (final key in result.keys) key: Series(result[key]!),
    };
  }

  List<Gene> _top(int count) {
    final list = genes.reversed.take(count.clamp(0, genes.length));
    return list.toList();
  }

  List<Gene> _bottom(int count) {
    final list = genes.take(count.clamp(0, genes.length));
    return list.toList();
  }

  List<Gene> _topPercentile(double percentile, String transcriptionKey) {
    final totalRate =
        transcriptionRates[transcriptionKey]!.sum + 0.0001; // correction fo floating point operations error
    final list = genes.reversed.toList();
    var rate = 0.0;
    var i = 0;
    List<Gene> result = [];
    while (rate < totalRate * percentile && i < list.length) {
      result.add(list[i]);
      rate += list[i].transcriptionRates[transcriptionKey]!;
      i++;
    }
    /*
    print('$rate <= $totalRate, $i th gene');
    final sequence = list.getRange(i - 10.clamp(0, list.length), (i + 10).clamp(0, list.length));
    for (final gene in sequence) {
      print('${gene.geneId} ${gene.transcriptionRates[transcriptionKey]!}');
    }
    */
    return result.toList();
  }

  List<Gene> _bottomPercentile(double percentile, String transcriptionKey) {
    final totalRate =
        transcriptionRates[transcriptionKey]!.sum + 0.0001; // correction fo floating point operations error;
    final list = genes;
    var rate = 0.0;
    var i = 0;
    List<Gene> result = [];
    while (rate < totalRate * percentile && i < list.length) {
      result.add(list[i]);
      rate += list[i].transcriptionRates[transcriptionKey]!;
      i++;
    }
    return result.toList();
  }

  Map<String, Color> _colorsFromStages() {
    if (organism?.stages.isNotEmpty == true) {
      final result = <String, Color>{};
      for (final stage in organism!.stages) {
        result[stage.stage] = stage.color;
      }
      return result;
    }
    return {};
  }

  Map<String, int> _strokeFromStages() {
    if (organism?.stages.isNotEmpty == true) {
      final result = <String, int>{};
      for (final stage in organism!.stages) {
        result[stage.stage] = stage.stroke;
      }
      return result;
    }
    return {};
  }
}
