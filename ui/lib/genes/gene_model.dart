import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:golem_ui/analysis/analysis_series.dart';
import 'package:golem_ui/analysis/analysis_options.dart';
import 'package:golem_ui/analysis/motif.dart';
import 'package:golem_ui/analysis/organism.dart';
import 'package:golem_ui/genes/gene.dart';
import 'package:golem_ui/genes/stage_selection.dart';
import 'package:golem_ui/genes/gene_list.dart';
import 'package:provider/provider.dart';
import 'package:universal_file/universal_file.dart';

/// Main model for the UI app
class GeneModel extends ChangeNotifier {
  static const kAllStages = '__ALL__';

  /// Flag that the analyis has been cancelled by the user
  bool get analysisCancelled => _analysisCancelled;
  bool _analysisCancelled = false;

  /// Name of the organism
  String? name;

  /// List of genes
  GeneList? sourceGenes;

  /// List of analysis series
  List<AnalysisSeries> analyses = [];

  /// Progress of the analysis
  double? analysisProgress;

  /// Options for the analysis
  AnalysisOptions analysisOptions = AnalysisOptions();
  StageSelection? _stageSelection;

  /// Selected stages
  StageSelection? get stageSelection => _stageSelection;
  List<Motif> _motifs = [];

  /// All motifs
  List<Motif> get motifs => _motifs;

  /// Number of series the analysis will produce
  int get expectedSeriesCount => motifs.length * (stageSelection?.selectedStages.length ?? 0);

  GeneModel();

  static GeneModel of(BuildContext context) => Provider.of<GeneModel>(context, listen: false);

  void _reset({bool preserveSource = false}) {
    if (!preserveSource) {
      name = null;
      sourceGenes = null;
    }
    analyses = [];
    analysisProgress = null;
    analysisOptions = AnalysisOptions();
    _stageSelection = null;
    _motifs = [];
  }

  void cancelAnalysis() {
    _analysisCancelled = true;
    notifyListeners();
  }

  void setAnalyses(List<AnalysisSeries> analyses) {
    this.analyses = analyses;
    notifyListeners();
  }

  void setMotifs(List<Motif> newMotifs) {
    _motifs = newMotifs;
    notifyListeners();
  }

  void setStageSelection(StageSelection? selection) {
    _stageSelection = selection;
    notifyListeners();
  }

  void setOptions(AnalysisOptions options) {
    analyses = [];
    analysisProgress = null;
    analysisOptions = options;
    notifyListeners();
  }

  void removeAnalysis(String name) {
    analyses = analyses.where((a) => a.name != name).toList();
    notifyListeners();
  }

  void removeAnalyses() {
    analyses = [];
    notifyListeners();
  }

  void resetAnalysisOptions() {
    final alignMarkers = sourceGenes?.genes.first.markers.keys.toList();
    alignMarkers?.sort();
    if (alignMarkers != null && alignMarkers.isNotEmpty) {
      analysisOptions = AnalysisOptions(alignMarker: alignMarkers.first, min: -1000, max: 1000, bucketSize: 30);
    } else {
      analysisOptions = AnalysisOptions();
    }
  }

  void resetFilter() {
    final selectedStages = sourceGenes?.defaultSelectedStageKeys ?? [];
    _stageSelection = StageSelection(
      selectedStages: [kAllStages, ...selectedStages],
      strategy: sourceGenes?.stages != null ? null : FilterStrategy.top,
      selection: sourceGenes?.stages != null ? null : FilterSelection.percentile,
      percentile: sourceGenes?.stages != null ? null : 0.9,
      count: sourceGenes?.stages != null ? null : 3200,
    );
  }

  /// Loads genes and transcript rates from .fasta data
  Future<void> loadFastaFromString(
      {required String data, Organism? organism, required Function(double progress) progressCallback}) async {
    _reset();
    name = organism?.name;
    List<Gene> genes;
    List<dynamic> errors;
    final takeSingleTranscript = organism == null || organism.takeFirstTranscriptOnly;
    (genes, errors) = await GeneList.parseFasta(
        data, takeSingleTranscript ? (value) => progressCallback(value / 2) : progressCallback);
    if (takeSingleTranscript) {
      (genes, errors) =
          await GeneList.takeSingleTranscript(genes, errors, (value) => progressCallback(0.5 + value / 2));
    }
    sourceGenes = GeneList.fromList(genes: genes, errors: errors, organism: organism);
    resetAnalysisOptions();
    resetFilter();
    notifyListeners();
  }

  Future<void> loadFastaFromFile({
    required String path,
    String? filename,
    Organism? organism,
    required Function(double progress) progressCallback,
  }) async {
    final data = await File(path).readAsString();
    return await loadFastaFromString(data: data, organism: organism, progressCallback: progressCallback);
  }

  void reset() {
    _reset();
    notifyListeners();
  }

  /// Runs analysis for all selected stages and motifs
  Future<bool> analyze() async {
    assert(stageSelection != null);
    assert(stageSelection!.selectedStages.isNotEmpty);
    assert(motifs.isNotEmpty);
    final totalIterations = stageSelection!.selectedStages.length * motifs.length;
    assert(totalIterations > 0);
    int iterations = 0;
    analysisProgress = 0.0;
    _analysisCancelled = false;
    notifyListeners();
    for (final motif in motifs) {
      for (final key in stageSelection!.selectedStages) {
        await Future.delayed(const Duration(milliseconds: 50)); // Allow UI to refresh on web
        if (_analysisCancelled) {
          analysisProgress = null;
          notifyListeners();
          return false;
        }
        final filteredGenes =
            key == kAllStages ? sourceGenes : sourceGenes!.filter(stage: key, stageSelection: stageSelection!);
        final name = '${key == kAllStages ? 'all' : key} - ${motif.name}';
        final color =
            sourceGenes?.colors.isNotEmpty == true ? (sourceGenes!.colors[key] ?? Colors.grey) : _randomColorOf(name);
        final stroke = key == kAllStages ? 4 : sourceGenes?.stroke[key];
        removeAnalysis(name);

        final analysis = await compute(runAnalysis, {
          'genes': filteredGenes,
          'motif': motif,
          'name': name,
          'min': analysisOptions.min,
          'max': analysisOptions.max,
          'interval': analysisOptions.bucketSize,
          'alignMarker': analysisOptions.alignMarker,
          'color': color.value,
          'stroke': stroke,
        });
        analyses.add(analysis);
        iterations++;
        analysisProgress = iterations / totalIterations;
        notifyListeners();
      }
    }
    analysisProgress = null;
    notifyListeners();
    return true;
  }

  Color _randomColorOf(String text) {
    var hash = 0;
    for (var i = 0; i < text.length; i++) {
      hash = text.codeUnitAt(i) + ((hash << 5) - hash);
    }
    final finalHash = hash.abs() % (256 * 256 * 256);
    final red = ((finalHash & 0xFF0000) >> 16);
    final blue = ((finalHash & 0xFF00) >> 8);
    final green = ((finalHash & 0xFF));
    final color = Color.fromRGBO(red, green, blue, 1);
    return color;
  }
}

/// Runs the analysis (isolate)
Future<AnalysisSeries> runAnalysis(Map<String, dynamic> params) async {
  final list = params['genes'] as GeneList;
  final motif = params['motif'] as Motif;
  final name = params['name'] as String;
  final min = params['min'] as int;
  final max = params['max'] as int;
  final interval = params['interval'] as int;
  final alignMarker = params['alignMarker'] as String?;
  final color = Color(params['color'] as int);
  final stroke = params['stroke'] as int?;
  final analysis = AnalysisSeries.run(
    geneList: list,
    noOverlaps: true,
    min: min,
    max: max,
    bucketSize: interval,
    alignMarker: alignMarker,
    motif: motif,
    name: name,
    color: color,
    stroke: stroke,
  );
  return analysis;
}
