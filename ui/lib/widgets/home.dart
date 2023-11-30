import 'package:flutter/material.dart';
import 'package:golem_ui/analysis/analysis_options.dart';
import 'package:golem_ui/analysis/motif.dart';
import 'package:golem_ui/genes/gene_list.dart';
import 'package:golem_ui/genes/stage_selection.dart';
import 'package:golem_ui/genes/gene_model.dart';
import 'package:golem_ui/screens/analysis_screen.dart';
import 'package:golem_ui/widgets/analysis_options_panel.dart';
import 'package:golem_ui/widgets/motif_panel.dart';
import 'package:golem_ui/widgets/stage_panel.dart';
import 'package:golem_ui/widgets/source_panel.dart';
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

  late int _index = 0;

  @override
  void initState() {
    super.initState();
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
                content: MotifPanel(key: ValueKey(organismAndStages), onChanged: _handleMotifsChanged),
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
        return model.sourceGenes != null;
      case 2: // motif
        return model.sourceGenes != null;
      case 3: // stage
        return model.sourceGenes != null;
      case 4: // analysis
        return model.sourceGenes != null && model.expectedSeriesCount > 0 && model.expectedSeriesCount <= 60;
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
    GeneModel.of(context).setMotifs(motifs);
  }

  void _handleAnalysisOptionsChanged(AnalysisOptions options) {
    GeneModel.of(context).setOptions(options);
  }
}
