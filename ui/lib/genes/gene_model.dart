import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geneweb/analysis/analysis_series.dart';
import 'package:geneweb/analysis/analysis_options.dart';
import 'package:geneweb/api/auth.dart';
import 'package:geneweb/models/motif.dart';
import 'package:geneweb/models/user.dart';
import 'package:geneweb/models/organism.dart';
import 'package:geneweb/genes/gene.dart';
import 'package:geneweb/genes/stage_selection.dart';
import 'package:geneweb/genes/gene_list.dart';
import 'package:geneweb/genes/stages_data.dart';
import 'package:geneweb/genes/tpm_data.dart';
import 'package:geneweb/utilities/color.dart';
import 'package:geneweb/utilities/list.dart';
import 'package:geneweb/utilities/stages.dart';
import 'package:provider/provider.dart';
import 'package:universal_file/universal_file.dart';

class LoadingState {
  String? message;
  bool isLoading = false;
  double progress = 0;

  LoadingState({this.message, this.progress = 0, required this.isLoading});

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is LoadingState &&
            message == other.message &&
            isLoading == other.isLoading &&
            progress == other.progress);
  }

  @override
  int get hashCode => Object.hash(message, isLoading, progress);

  LoadingState copyWith({String? message, bool? isLoading, double? progress}) {
    return LoadingState(
        message: message ?? this.message,
        isLoading: isLoading ?? this.isLoading,
        progress: progress ?? this.progress);
  }
}

/// Main model for the UI app
/// TODO: this should be split into multiple notifiers at some point
class GeneModel extends ChangeNotifier {
  static const kAllStages = '__ALL__';

  final ValueNotifier<User?> _userNotifier = ValueNotifier<User?>(null);

  /// Currently logged in user
  User? _user;

  User? get user => _user;
  ValueNotifier<User?> get userNotifier => _userNotifier;

  set user(User? value) {
    _user = value;
    _userNotifier.value = value;

    if (user == null) {
      _reset();
    }

    notifyListeners();
  }

  OrganismMetadata? _metadata;
  OrganismMetadata? get metadata => _metadata;

  set metadata(OrganismMetadata? metadata) {
    _metadata = metadata;
    resetAnalysisOptions();
    notifyListeners();
  }

  LoadingState? _loading;
  LoadingState get loading => _loading ?? LoadingState(isLoading: false);

  set loading(LoadingState state) {
    if (_loading != state) {
      _loading = state;
      notifyListeners();
    }
  }

  // Check if user is signed in
  bool get isSignedIn => _user != null;
  bool get isAdmin =>
      isSignedIn &&
      _user!.groups
              // TODO: probably shouldn't be hardcoded
              .firstWhereOrNull((group) => group.name == 'administrators') !=
          null;

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
  AnalysisOptions analysisOptions = const AnalysisOptions();
  StageSelection? _stageSelection;

  /// Selected stages
  StageSelection? get stageSelection => _stageSelection;
  List<Motif> _motifs = [];

  /// All motifs
  List<Motif> get motifs => _motifs;

  List<String> get alignMarkers =>
      metadata?.genes.values.firstOrNull?.markers.keys.toList() ??
      sourceGenes?.genes.first.markers.keys.toList() ??
      [];

  /// Whether to match only when ALL motifs are found in a gene.
  bool _matchWhenAll = false;
  bool get matchWhenAll => motifs.length > 1 && _matchWhenAll;
  set matchWhenAll(bool value) {
    _matchWhenAll = value;
    notifyListeners();
  }

  /// Number of series the analysis will produce
  int get expectedSeriesCount =>
      motifs.length *
      (stageSelection?.selectedStages.length ?? 0) *
      (stageSelection?.percentiles?.length ?? 0);

  List<String>? get stageKeys => (metadata?.stages ?? {}).keys.isNotEmpty
      // new metadata json format
      ? metadata!.stages.keys.toList()
      // old format or no stage metadata provided -> take transcription rates keys from the first gene
      : metadata?.genes.values.firstOrNull?.transcriptionRates.keys.toList();

  GeneModel();

  static GeneModel of(BuildContext context) =>
      Provider.of<GeneModel>(context, listen: false);

  void _reset({bool preserveSource = false}) {
    if (!preserveSource) {
      name = null;
      sourceGenes = null;
    }
    analyses = [];
    analysisProgress = null;
    resetAnalysisOptions();
    _stageSelection = null;
    _motifs = [];
    _matchWhenAll = false;
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

  void setStagePreferenceColor(String stageName, String color) {
    if (user == null) {
      return;
    }

    final preferences = user!.preferences;
    final organism = sourceGenes!.organism;
    final preference = preferences.firstWhereOrNull((pref) =>
        pref.stageName == stageName && pref.organismId == organism?.id);

    if (preference != null) {
      preference.color = color;
    } else {
      user!.preferences.add(StagePreference(
          organismId: sourceGenes?.organism?.id,
          stageName: stageName,
          color: color));
    }

    if (sourceGenes != null) {
      sourceGenes!.colors[stageName] = HexColor.fromHex(color);
    }

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
    final markers = alignMarkers;
    markers.sort();
    if (markers.isNotEmpty) {
      if (markers.contains(analysisOptions.alignMarker)) {
        // prevents the reset of motif mapping field while the organism is still loading
        return;
      }
      analysisOptions = AnalysisOptions(
          alignMarker: markers.first, min: -1000, max: 1000, bucketSize: 30);
    } else {
      analysisOptions = const AnalysisOptions();
    }
  }

  void resetFilter() {
    _stageSelection = StageSelection(
      selectedStages: [],
      strategy: sourceGenes?.stages != null ? null : FilterStrategy.top,
      selection:
          sourceGenes?.stages != null ? null : FilterSelection.percentile,
      count: sourceGenes?.stages != null ? null : 3200,
    );
  }

  /// Loads genes and transcript rates from .fasta data
  Future<void> loadFastaFromString(
      {required String data,
      Organism? organism,
      required Function(double progress) progressCallback}) async {
    // TODO exception

    _reset();
    name = organism?.name;
    List<Gene> genes;
    List<dynamic> errors;
    final takeSingleTranscript =
        organism == null || organism.takeFirstTranscriptOnly;
    (genes, errors) = switch (metadata) {
      // loading metadata from comments in fasta
      null => await GeneList.parseFastaWithComments(
          data,
          takeSingleTranscript
              ? (value) => progressCallback(value / 2)
              : progressCallback),
      _ => await GeneList.parseFasta(
          data,
          metadata!,
          takeSingleTranscript
              ? (value) => progressCallback(value / 2)
              : progressCallback),
    };

    resetAnalysisOptions();
    resetFilter();

    final defaultPreferences = await getDefaultPreferences();
    final userPreferences =
        user?.preferences.where((pref) => pref.organismId == organism?.id) ??
            [];
    final randomPreferences = organism!.stages.map((stage) => StagePreference(
        stageName: stage, color: randomStageColor(stage).toHex()));
    final preferences = [
      ...userPreferences, // user preferences have the highest priority
      ...defaultPreferences, // then preferences of the organism
      ...randomPreferences, // if no preferences were found, use random
    ].distinctBy((pref) => pref.stageName);

    final colors = <String, Color>{};
    for (StagePreference preference in preferences) {
      try {
        colors[preference.stageName] = HexColor.fromHex(preference.color);
      } catch (e) {
        debugPrint(
            'Unable to convert the color ${preference.color} ${preference.stageName} to hex');
      }
    }

    sourceGenes = GeneList.fromList(
        genes: genes, errors: errors, organism: organism, colors: colors);

    if (takeSingleTranscript) {
      (genes, errors) = await GeneList.takeSingleTranscript(
          genes, errors, (value) => progressCallback(0.5 + value / 2));
      sourceGenes = sourceGenes!.copyWith(genes: genes, errors: errors);
    }

    notifyListeners();
  }

  Future<void> loadFastaFromFile({
    required String path,
    String? filename,
    Organism? organism,
    required Function(double progress) progressCallback,
  }) async {
    final data = await File(path).readAsString();
    return await loadFastaFromString(
        data: data, organism: organism, progressCallback: progressCallback);
  }

  /// Loads info about stages and colors from CSV file
  ///
  /// See [StagesData]
  bool loadStagesFromString(String data) {
    _reset(preserveSource: true);
    assert(sourceGenes != null);
    final stages = StagesData.fromCsv(data);

    final List<dynamic> errors = [];
    final genes = sourceGenes!.genes.map((g) => g.geneId).toSet();
    for (final stageKey in stages.stages.keys) {
      final stageGenes = stages.stages[stageKey]!.toSet();
      final diff = stageGenes.difference(genes);
      if (diff.isNotEmpty) {
        errors.add(
            'Found ${diff.length} genes in stage $stageKey that are not in the gene list: ${diff.toList().take(3).join(', ')}${diff.length > 3 ? '…' : ''}');
      }
    }
    sourceGenes = sourceGenes?.copyWith(
        stages: stages.stages,
        colors: stages.colors,
        errors: errors.isEmpty ? null : [...errors, ...sourceGenes!.errors]);
    resetAnalysisOptions();
    resetFilter();
    notifyListeners();
    return errors.isEmpty;
  }

  Future<bool> loadStagesFromFile(String path) async {
    final data = await File(path).readAsString();
    return loadStagesFromString(data);
  }

  /// Loads TPM data for individual stages and colors from CSV file
  ///
  /// See [StagesData]
  bool loadTPMFromString(String data) {
    _reset(preserveSource: true);
    assert(sourceGenes != null);
    final tpm = TPMData.fromCsv(data);

    final List<dynamic> errors = [];
    final List<Gene> genes = [
      for (final gene in sourceGenes!.genes)
        if (tpm.stages.keys
            .every((stageKey) => tpm.stages[stageKey]![gene.geneId] != null))
          gene.copyWith(transcriptionRates: {
            for (final stage in tpm.stages.keys)
              stage: tpm.stages[stage]![gene.geneId]!,
          }),
    ];

    if (genes.length != sourceGenes!.genes.length) {
      errors.add(
          '${sourceGenes!.genes.length - genes.length} genes excluded due to lack of TPM data');
    }

    sourceGenes = sourceGenes?.copyWith(
        genes: genes,
        errors: errors.isEmpty ? null : [...errors, ...sourceGenes!.errors],
        colors: tpm.colors);

    resetAnalysisOptions();
    resetFilter();
    notifyListeners();
    return errors.isEmpty;
  }

  Future<bool> loadTPMFromFile(String path) async {
    final data = await File(path).readAsString();
    return loadTPMFromString(data);
  }

  void reset() {
    _reset();
    notifyListeners();
  }

  /// Runs analysis for all selected stages and motifs
  Future<bool> analyze() async {
    assert(stageSelection != null);
    assert(stageSelection!.selectedStages.isNotEmpty);
    assert(stageSelection!.percentiles != null);
    assert(stageSelection!.percentiles!.isNotEmpty);
    assert(motifs.isNotEmpty);
    final totalIterations = stageSelection!.selectedStages.length *
        motifs.length *
        stageSelection!.percentiles!.length;
    assert(totalIterations > 0);

    int iterations = 0;
    analysisProgress = 0.0;
    _analysisCancelled = false;
    notifyListeners();

    final Set<String>? intersectingGeneIds =
        matchWhenAll ? _identifyIntersectingGenes(sourceGenes!, motifs) : null;

    for (final motif in motifs) {
      for (final key in stageSelection!.selectedStages) {
        await Future.delayed(
            const Duration(milliseconds: 50)); // Allow UI to refresh on web
        if (_analysisCancelled) {
          analysisProgress = null;
          notifyListeners();
          return false;
        }

        final groupedGenes = switch (key) {
          kAllStages => {
              for (final p in stageSelection!.percentiles!) p: sourceGenes
            },
          _ => sourceGenes!
              .filterByPercentile(stage: key, stageSelection: stageSelection!),
        };

        for (final (i, entry) in groupedGenes.entries.indexed) {
          final percentile = entry.key;
          final genes = entry.value;

          final name =
              '${key == kAllStages ? 'all' : key} - ${motif.name} - ${(percentile * 100).round()}th percentile';
          final color = sourceGenes?.colors.isNotEmpty == true
              ? (sourceGenes!.colors[key] ?? Colors.grey)
              : _randomColorOf(name);
          final tintedColor = ColorMixing.tint(color, i / groupedGenes.length);

          final stroke = key == kAllStages ? 4 : sourceGenes?.stroke[key];
          removeAnalysis(name);

          final analysis = await compute(runAnalysis, {
            'genes': genes,
            'motif': motif,
            'name': name,
            'min': analysisOptions.min,
            'max': analysisOptions.max,
            'interval': analysisOptions.bucketSize,
            'alignMarker': analysisOptions.alignMarker,
            'color': tintedColor.value,
            'stroke': stroke,
            'allowedGeneIds': intersectingGeneIds
          });
          analyses.add(analysis);
          iterations++;
          analysisProgress = iterations / totalIterations;
          notifyListeners();
        }
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

  Set<String> _identifyIntersectingGenes(
      GeneList genesList, List<Motif> motifs) {
    List<Gene> candidates = genesList.genes;

    for (final motif in motifs) {
      if (candidates.isEmpty) {
        break;
      }
      final patterns = [
        ...motif.regExp.values,
        ...motif.reverseComplementRegExp.values
      ];

      final List<Gene> survivors = [];

      for (final gene in candidates) {
        bool matched = false;
        for (final pattern in patterns) {
          if (pattern.hasMatch(gene.data)) {
            matched = true;
            break;
          }
        }
        if (matched) {
          survivors.add(gene);
        }
      }

      candidates = survivors;
    }

    return candidates.map((c) => c.geneId).toSet();
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
  final allowedGeneIds = params['allowedGeneIds'] as Set<String>?;
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
    allowedGeneIds: allowedGeneIds,
  );
  return analysis;
}
