import 'package:flutter/material.dart';
import 'package:geneweb/analysis/analysis_options.dart';
import 'package:geneweb/analysis/motif.dart';
import 'package:geneweb/api/motif.dart';
import 'package:geneweb/genes/gene_list.dart';
import 'package:geneweb/genes/stage_selection.dart';
import 'package:geneweb/genes/gene_model.dart';
import 'package:geneweb/screens/analysis_screen.dart';
import 'package:geneweb/widgets/analysis_options_panel.dart';
import 'package:geneweb/widgets/loading.dart';
import 'package:geneweb/widgets/motif_panel.dart';
import 'package:geneweb/widgets/stage_panel.dart';
import 'package:geneweb/widgets/source_panel.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Widget that builds the contents of the Home Screen
class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late final _model = GeneModel.of(context);
  late Future<List<Motif>> _futureMotifs;
  late int _index = 0;

  @override
  void initState() {
    super.initState();
    _futureMotifs = fetchMotifs();
    context.read<GeneModel>().userNotifier.addListener(_fetchMotifs);
    /*
    for (final motif in Presets.analyzedMotifs) {
      debugPrint(motif.name);
      debugPrint(motif.definitions.join(','));
      debugPrint(motif.reverseDefinitions.join(','));
      debugPrint('\n');
    }
    */
  }

  @override
  void dispose() {
    context.read<GeneModel>().userNotifier.removeListener(_fetchMotifs);
    super.dispose();
  }

  void _fetchMotifs() {
    _futureMotifs = fetchMotifs();
  }

  @override
  Widget build(BuildContext context) {
    final organismAndStages =
        context.select<GeneModel, String?>((model) => '${model.name} ${model.sourceGenes?.stageKeys.join('+')}');
    final sourceGenes = context.select<GeneModel, GeneList?>((model) => model.sourceGenes);
    final motifs = context.select<GeneModel, List<Motif>>((model) => model.motifs);
    final filter = context.select<GeneModel, StageSelection?>((model) => model.stageSelection);
    final expectedResults = context.select<GeneModel, int>((model) => model.expectedSeriesCount);

    return SingleChildScrollView(
      child: Column(
        children: [
          const Loading(),
          Stepper(
            currentStep: _index,
            onStepCancel: _index > 0 ? _handleStepCancel : null,
            onStepContinue: _isStepAllowed(_index + 1) ? _handleStepContinue : null,
            onStepTapped: _handleStepTapped,
            physics: const NeverScrollableScrollPhysics(),
            steps: <Step>[
              Step(
                title: const Text('Species'),
                subtitle: const SourceSubtitle(),
                content: SourcePanel(onShouldClose: () => _handleStepTapped(1)),
                state: sourceGenes == null
                    ? StepState.indexed
                    : sourceGenes.errors.isNotEmpty
                        ? StepState.error
                        : StepState.complete,
              ),
              Step(
                title: const Text('Genomic interval'),
                subtitle: const AnalysisOptionsSubtitle(),
                content:
                    AnalysisOptionsPanel(key: ValueKey(organismAndStages), onChanged: _handleAnalysisOptionsChanged),
                state: sourceGenes == null ? StepState.indexed : StepState.complete,
              ),
              Step(
                title: const Text('Analyzed motifs'),
                subtitle: const MotifSubtitle(),
                content: FutureBuilder(future: _futureMotifs, builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return MotifPanel(key: ValueKey(organismAndStages), motifs: snapshot.data!, onChanged: _handleMotifsChanged);
                  } else if (snapshot.hasError) {
                    return Text('${snapshot.error}');
                  }
                  
                  return const CircularProgressIndicator();
                }),
                state: expectedResults > 60 && motifs.length > 5
                    ? StepState.error
                    : motifs.isEmpty
                        ? StepState.indexed
                        : StepState.complete,
              ),
              Step(
                title: const Text('Developmental stages'),
                subtitle: const StageSubtitle(),
                content: StagePanel(key: ValueKey(organismAndStages), onChanged: _handleStageSelectionChanged),
                state: filter?.selectedStages.isEmpty == true ||
                        expectedResults > 60 && (filter?.selectedStages.length ?? 0) > 5
                    ? StepState.error
                    : StepState.indexed,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => launchUrl(Uri.parse('https://elixir-europe.org/')),
            child: Image.asset('assets/logo_elixir.png', height: 64),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  bool _isStepAllowed(int nextStep) {
    final model = GeneModel.of(context);
    switch (nextStep) {
      case 0: // source data
        return true;
      case 1: // analysis options
        return model.metadata != null || model.sourceGenes != null;
      case 2: // motif
        return model.metadata != null || model.sourceGenes != null;
      case 3: // stage
        return model.metadata != null || model.sourceGenes != null;
      case 4: // analysis
        return (model.sourceGenes != null) && model.expectedSeriesCount > 0 && model.expectedSeriesCount <= 60;
      default:
        return false;
    }
  }

  void _handleStepTapped(int index) {
    if (_isStepAllowed(index)) {
      setState(() => _index = index);
    }
  }

  Future<void> _handleStepContinue() async {
    final nextStep = _index + 1;
    if (nextStep == 4) {
      await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AnalysisScreen()));
      _model.removeAnalyses();
      return;
    }
    if (_isStepAllowed(nextStep)) {
      setState(() => _index = nextStep);
    }
  }

  void _handleStepCancel() {
    if (_index > 0) {
      setState(() => _index -= 1);
    }
  }

  void _handleStageSelectionChanged(StageSelection? selection) {
    GeneModel.of(context).setStageSelection(selection);
  }

  void _handleMotifsChanged(List<Motif> motifs) {
    final model = GeneModel.of(context);
    model.setMotifs(motifs);

    if (model.isSignedIn) {
      _fetchMotifs();
    }
  }

  void _handleAnalysisOptionsChanged(AnalysisOptions options) {
    GeneModel.of(context).setOptions(options);
  }
}
