import 'package:flutter/material.dart';
import 'package:golem_ui/analysis/motif.dart';
import 'package:golem_ui/analysis/motif_presets.dart';
import 'package:golem_ui/genes/gene_list.dart';
import 'package:golem_ui/genes/gene_model.dart';
import 'package:provider/provider.dart';
import 'package:truncate/truncate.dart';

/// Widget shown below the Motif selection headline
class MotifSubtitle extends StatelessWidget {
  const MotifSubtitle({super.key});

  @override
  Widget build(BuildContext context) {
    final motifs = context.select<GeneModel, List<Motif>>((model) => model.motifs);
    final expectedResults = context.select<GeneModel, int>((model) => model.expectedSeriesCount);
    if (expectedResults > 60 && motifs.length > 5) {
      return Text('Analysis would result in $expectedResults series, reduce the number of selected motifs');
    }
    return motifs.isEmpty
        ? const Text('Choose motifs to analyze or enter a custom motif')
        : motifs.length == 1
            ? Text(truncate('${motifs.first.name} (${motifs.first.definitions.join(', ')})', 100))
            : Text('${motifs.length} motifs');
  }
}

/// Widget that builds the panel with motif selection
class MotifPanel extends StatefulWidget {
  final Function(List<Motif> motif) onChanged;

  const MotifPanel({super.key, required this.onChanged});

  @override
  State<MotifPanel> createState() => _MotifPanelState();
}

class _MotifPanelState extends State<MotifPanel> {
  final _formKey = GlobalKey<FormState>();
  late final _model = GeneModel.of(context);

  String? _customMotifName;
  String? _customMotifDefinition;
  String? _customMotifError;
  final _nameController = TextEditingController();
  final _definitionController = TextEditingController();
  final _reverseComplementsController = TextEditingController();
  bool _showEditor = false;

  @override
  void dispose() {
    _nameController.dispose();
    _definitionController.dispose();
    _reverseComplementsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sourceGenes = context.select<GeneModel, GeneList?>((model) => model.sourceGenes);
    if (sourceGenes == null) return const Center(child: Text('Load source data first'));
    final motifs = context.select<GeneModel, List<Motif>>((model) => model.motifs);
    final customMotifs = motifs.where((m) => m.isCustom).toList();

    final presets = List.of(MotifPresets.presets);

    return Align(
      alignment: Alignment.topLeft,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('CUSTOM MOTIFS'),
            const SizedBox(height: 16.0),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ...customMotifs.map((m) => _MotifCard(
                      motif: m,
                      onToggle: (bool value) => _handlePresetToggled(m, value),
                      isSelected: true,
                    )),
                if (!_showEditor) TextButton(onPressed: _handleOpenEditor, child: const Text('Add custom motif…'))
              ],
            ),
            if (_showEditor) ...[
              _buildMotifEditor(),
              const SizedBox(height: 16),
              Text('R = AG, Y = CT, W = AT, S = GC, M = AC, K = GT, B = CGT, D = AGT, H = ACT, V = ACG, N = ACGT',
                  style: Theme.of(context).textTheme.labelMedium!),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 16.0),
            const Text('PRESETS'),
            const SizedBox(height: 16.0),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ...presets.map((m) => _MotifCard(
                      motif: m,
                      onToggle: (bool value) => _handlePresetToggled(m, value),
                      isSelected: motifs.contains(m),
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Wrap _buildMotifEditor() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: [
        SizedBox(
          width: 200,
          child: TextFormField(
            controller: _nameController,
            onChanged: (value) {
              setState(() => _customMotifName = value);
            },
            decoration: const InputDecoration(
              labelText: "Motif name",
            ),
          ),
        ),
        SizedBox(
          width: 400,
          child: TextFormField(
            controller: _definitionController,
            validator: _validateMotifDefinition,
            onChanged: (value) {
              setState(() => _customMotifDefinition = value.toUpperCase());
              _updateReverseComplements();
            },
            textCapitalization: TextCapitalization.characters,
            autocorrect: false,
            maxLines: null,
            decoration: InputDecoration(
                labelText: "Motif definition",
                helperText: "Separate multiple motifs with new line.",
                errorText: _customMotifError),
          ),
        ),
        SizedBox(
          width: 400,
          child: TextFormField(
            controller: _reverseComplementsController,
            textCapitalization: TextCapitalization.characters,
            autocorrect: false,
            maxLines: null,
            readOnly: true,
            enabled: false,
            decoration: const InputDecoration(labelText: "Reverse complements (read only)"),
          ),
        ),
        ElevatedButton(onPressed: _handleAddMotif, child: const Text('ADD')),
      ],
    );
  }

  void _updateReverseComplements() {
    final error = _validateMotifDefinition(_customMotifDefinition);
    setState(() => _customMotifError = error);
    if (error == null) {
      final motif =
          Motif(name: _customMotifName ?? 'Unnamed motif', definitions: _getDefinitions(_customMotifDefinition!));
      _reverseComplementsController.text = motif.reverseDefinitions.join('\n');
    } else {
      _reverseComplementsController.text = '';
    }
  }

  List<String> _getDefinitions(String raw) {
    return raw.toUpperCase().split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
  }

  String? _validateMotifDefinition(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter the motif definition';
    }
    final defs = _getDefinitions(value);
    return Motif.validate(defs);
  }

  void _handlePresetToggled(Motif motif, bool value) {
    final newMotifs = List.of(_model.motifs);
    if (value) {
      newMotifs.add(motif);
    } else {
      newMotifs.remove(motif);
    }
    _model.setMotifs(newMotifs);
  }

  void _handleOpenEditor() {
    setState(() => _showEditor = true);
    _nameController.text = '';
    _definitionController.text = '';
    _reverseComplementsController.text = '';
  }

  void _handleAddMotif() {
    if (_formKey.currentState!.validate()) {
      final definitions = _customMotifDefinition!.toUpperCase().split('\n');
      final name = (_customMotifName ?? '') != '' ? _customMotifName : definitions.first;
      final motif = Motif(name: name!, definitions: definitions, isCustom: true);
      _model.setMotifs([motif, ..._model.motifs]);
    }
    setState(() => _showEditor = false);
  }
}

class _MotifCard extends StatelessWidget {
  final Motif motif;
  final Function(bool value) onToggle;
  final bool isSelected;
  const _MotifCard({required this.motif, required this.onToggle, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: 200,
      child: Card(
        color: isSelected ? colorScheme.primaryContainer : null,
        child: InkWell(
          onTap: () => onToggle(!isSelected),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Checkbox(value: isSelected, onChanged: (value) => onToggle(value!)),
                    Expanded(
                        child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(truncate(motif.name, 20), style: textTheme.titleSmall))),
                  ],
                ),
                const SizedBox(height: 8),
                FittedBox(child: Text(truncate(motif.definitions.join(', '), 25), style: textTheme.labelSmall)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
