import 'package:flutter/material.dart';
import 'package:golem_ui/analysis/analysis_options.dart';
import 'package:golem_ui/genes/gene_model.dart';
import 'package:provider/provider.dart';

/// Widget shown below the panel header
class AnalysisOptionsSubtitle extends StatelessWidget {
  const AnalysisOptionsSubtitle({super.key});

  @override
  Widget build(BuildContext context) {
    final analysisOptions = context.select<GeneModel, AnalysisOptions>((model) => model.analysisOptions);
    return Text(
        'Analyzing interval <${analysisOptions.min}; ${analysisOptions.max}> bp relative to ${(analysisOptions.alignMarker?.toUpperCase() ?? 'sequence start')}, bucket size ${analysisOptions.bucketSize} bp');
  }
}

/// Widget that builds the analysis options panel
class AnalysisOptionsPanel extends StatefulWidget {
  final Function(AnalysisOptions options) onChanged;

  const AnalysisOptionsPanel({super.key, required this.onChanged});

  @override
  State<AnalysisOptionsPanel> createState() => _AnalysisOptionsPanelState();
}

class _AnalysisOptionsPanelState extends State<AnalysisOptionsPanel> {
  final _formKey = GlobalKey<FormState>();

  late int _min;
  late int _max;
  late int _interval;
  String? _alignMarker;

  final _minController = TextEditingController();
  final _maxController = TextEditingController();
  final _intervalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _updateStateFromWidget();
  }

  @override
  void dispose() {
    super.dispose();
    _minController.dispose();
    _maxController.dispose();
    _intervalController.dispose();
  }

  @override
  void didUpdateWidget(covariant AnalysisOptionsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.key != widget.key) {
      _updateStateFromWidget();
    }
  }

  void _updateStateFromWidget() {
    final options = GeneModel.of(context).analysisOptions;
    _min = options.min;
    _max = options.max;
    _interval = options.bucketSize;
    _alignMarker = options.alignMarker;
    _minController.text = '$_min';
    _maxController.text = '$_max';
    _intervalController.text = '$_interval';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final markers =
        context.select<GeneModel, List<String>>((model) => model.sourceGenes?.genes.first.markers.keys.toList() ?? []);
    markers.sort();
    return Align(
      alignment: Alignment.topLeft,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                SizedBox(
                  width: 300,
                  child: DropdownButtonFormField<String?>(
                    items: [
                      for (final marker in markers) DropdownMenuItem(value: marker, child: Text(marker.toUpperCase())),
                    ],
                    onChanged: (value) {
                      setState(() => _alignMarker = value);
                      _handleChanged();
                    },
                    value: _alignMarker,
                    decoration: const InputDecoration(
                        labelText: 'Motif mapping', helperText: 'Motifs are mapped relative to TSS or ATG'),
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: TextFormField(
                    controller: _minController,
                    decoration: InputDecoration(
                        labelText: 'Genomic interval Min [bp]',
                        helperText: 'Relative to ${_alignMarker?.toUpperCase() ?? 'sequence start'}'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() => _min = (int.tryParse(_minController.text) ?? 0));
                      _handleChanged();
                    },
                    validator: (value) {
                      final parsed = int.tryParse(_minController.text);
                      if (parsed == null || parsed >= _max) return 'Enter a number lower than $_max';
                      return null;
                    },
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: TextFormField(
                    controller: _maxController,
                    decoration: InputDecoration(
                        labelText: 'Genomic interval Max [bp]',
                        helperText: 'Relative to ${_alignMarker?.toUpperCase() ?? 'sequence start'}'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() => _max = (int.tryParse(_maxController.text) ?? 0));
                      _handleChanged();
                    },
                    validator: (value) {
                      final parsed = int.tryParse(_maxController.text);
                      if (parsed == null || parsed <= _min) return 'Enter a number greater than $_min';
                      return null;
                    },
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: TextFormField(
                    controller: _intervalController,
                    decoration: const InputDecoration(
                      labelText: 'Bucket size [bp]',
                      helperText: 'Interval used to group the results',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() => _interval = (int.tryParse(_intervalController.text) ?? 1).clamp(1, 10000));
                      _handleChanged();
                    },
                    validator: (value) {
                      final parsed = int.tryParse(_intervalController.text);
                      if (parsed == null || parsed < 1 || parsed > 10000) return 'Enter a number between 1 and 10000';
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleChanged() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      widget.onChanged(AnalysisOptions(min: _min, max: _max, bucketSize: _interval, alignMarker: _alignMarker));
    }
  }
}
