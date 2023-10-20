import 'package:flutter/material.dart';
import 'package:golem_ui/analysis/analysis_series.dart';
import 'package:golem_ui/genes/gene_model.dart';
import 'package:provider/provider.dart';

/// Widget that builds the series and allows hide/show etc.
class ResultSeriesList extends StatefulWidget {
  const ResultSeriesList({super.key, required this.onSelected});

  final Function(String? selected) onSelected;

  @override
  State<ResultSeriesList> createState() => _ResultSeriesListState();
}

class _ResultSeriesListState extends State<ResultSeriesList> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final analyses = context.select<GeneModel, List<AnalysisSeries>>((model) => model.analyses);
    return ReorderableListView(
      onReorder: (oldIndex, newIndex) => _handleReorder(context, oldIndex, newIndex),
      children: [
        for (final analysis in analyses)
          ListTile(
            key: Key(analysis.name),
            onTap: () => _handleSelected(analysis.name),
            dense: true,
            selected: analysis.name == _selected,
            selectedTileColor: colorScheme.primaryContainer,
            selectedColor: colorScheme.onPrimaryContainer,
            leading: IconButton(
              onPressed: () => _handleSetVisibility(context, analysis),
              icon: analysis.visible
                  ? Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: colorScheme.outline),
                        borderRadius: BorderRadius.circular(4),
                        color: analysis.color,
                      ),
                      width: 24,
                      height: 24,
                    )
                  : const Icon(Icons.visibility_off),
            ),
            title: Text(analysis.name),
            subtitle: Text(
              '${analysis.distribution!.totalCount} motifs in ${analysis.distribution!.totalGenesWithMotifCount} genes (of ${analysis.distribution!.totalGenesCount} genes)',
            ),
          ),
      ],
    );
  }

  void _handleReorder(BuildContext context, int oldIndex, int newIndex) {
    final analyses = List<AnalysisSeries>.from(GeneModel.of(context).analyses);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = analyses.removeAt(oldIndex);
    analyses.insert(newIndex, item);
    GeneModel.of(context).setAnalyses(analyses);
  }

  void _handleSelected(String name) {
    setState(() => _selected = _selected == name ? null : name);
    widget.onSelected(_selected);
  }

  void _handleSetVisibility(BuildContext context, AnalysisSeries analysis) {
    final model = GeneModel.of(context);
    model.setAnalyses([
      for (final a in model.analyses)
        if (a.name == analysis.name) analysis.copyWith(visible: !analysis.visible) else a
    ]);
  }
}
