import 'package:flutter/material.dart';
import 'package:geneweb/models/motif.dart';
import 'package:geneweb/genes/gene_model.dart';
import 'package:geneweb/widgets/analysis_results_panel.dart';
import 'package:provider/provider.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final name = context.select<GeneModel, String?>((model) => model.name);
    final motifs =
        context.select<GeneModel, List<Motif>>((model) => model.motifs);
    final stages = context.select<GeneModel, List<String>>(
        (model) => model.stageSelection!.selectedStages);
    final stageName =
        stages.length == 1 ? stages.first : '${stages.length} stages';
    final motifName =
        motifs.length == 1 ? motifs.first.name : '${motifs.length} motifs';
    return Scaffold(
      appBar: AppBar(
          title: Wrap(
        spacing: 8,
        children: [
          Text('$name', style: const TextStyle(fontStyle: FontStyle.italic)),
          Text('($motifName, $stageName)'),
        ],
      )),
      body: const AnalysisResultsPanel(),
    );
  }
}
