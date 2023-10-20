import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:golem_ui/analysis/analysis_series.dart';
import 'package:golem_ui/genes/gene_model.dart';
import 'package:collection/collection.dart';

/// Widget that builds the drill down view
class DrillDownView extends StatefulWidget {
  const DrillDownView({super.key, required this.name});

  final String? name;

  @override
  State<DrillDownView> createState() => _DrillDownViewState();
}

class _DrillDownViewState extends State<DrillDownView> {
  List<String> patterns = [];
  List<DrillDownResult>? _results;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _update();
  }

  @override
  void didUpdateWidget(covariant DrillDownView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name) {
      patterns = [];
      _results = null;
      _update();
    }
  }

  Future<void> _update([String? pattern]) async {
    setState(() => _running = true);
    final analysis = GeneModel.of(context).analyses.firstWhereOrNull((a) => a.name == widget.name);
    final results = await compute(runDrillDown, {
      'analysis': analysis,
      'pattern': pattern,
    });
    setState(() {
      _results = results;
      _running = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_results == null) return const Center(child: CircularProgressIndicator());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TextButton(
              onPressed: _running || patterns.isEmpty ? null : () => _handleBreadCrumb(null),
              child: const Text('Motif drill down'),
            ),
            for (final pattern in patterns) ...[
              const Text('>'),
              TextButton(
                onPressed: _running ? null : () => _handleBreadCrumb(pattern),
                child: Text(pattern),
              ),
            ]
          ],
        ),
        Expanded(
            child: _running
                ? const Center(child: CircularProgressIndicator())
                : (_results?.length ?? 0) > 0
                    ? ListView.builder(
                        itemBuilder: _itemBuilder,
                        itemCount: _results?.length ?? 0,
                      )
                    : const Text('Selected pattern cannot be drilled down any further')),
      ],
    );
  }

  Widget _itemBuilder(BuildContext context, int index) {
    return ListTile(
      dense: true,
      title: Text(_results![index].pattern),
      subtitle: Text(
          'matches ${(_results![index].share * 100).round()}% of selection, (${(_results![index].shareOfAll * 100).round()}% of all results)'),
      trailing: Text(_results![index].count.toString()),
      onTap: _running ? null : () => _handleDrillDownDeeper(_results![index].pattern),
    );
  }

  void _handleDrillDownDeeper(String pattern) {
    setState(() {
      patterns.add(pattern);
      _update(pattern);
    });
  }

  void _handleBreadCrumb(String? pattern) {
    if (pattern == null) {
      setState(() {
        patterns = [];
        _update();
      });
    } else {
      setState(() {
        patterns = [...patterns.takeWhile((e) => e != pattern).toList(), pattern];
        _update(pattern);
      });
    }
  }
}

List<DrillDownResult> runDrillDown(Map<String, dynamic> params) {
  final analysis = params['analysis'] as AnalysisSeries;
  final pattern = params['pattern'] as String?;
  final result = analysis.drillDown(pattern);
  return result;
}
