import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:geneweb/analysis/motif.dart';
import 'package:geneweb/api/motif.dart';
import 'package:geneweb/api/organism.dart';
import 'package:geneweb/genes/gene_list.dart';
import 'package:geneweb/genes/gene_model.dart';
import 'package:geneweb/utilities/message.dart';
import 'package:provider/provider.dart';
import 'package:truncate/truncate.dart';

/// Widget shown below the Motif selection headline
class MotifSubtitle extends StatelessWidget {
  const MotifSubtitle({super.key});

  @override
  Widget build(BuildContext context) {
    final motifs = context.select<GeneModel, List<Motif>>((model) => model.motifs);
    final expectedResults = context.select<GeneModel, int>((model) => model.expectedSeriesCount);
    final matchWhenAll = context.select<GeneModel, bool>((model) => model.matchWhenAll);
    if (expectedResults > 60 && motifs.length > 5) {
      return Text('Analysis would result in $expectedResults series, reduce the number of selected motifs');
    }
    return motifs.isEmpty
        ? const Text('Choose motifs to analyze or enter a custom motif')
        : motifs.length == 1
            ? Text(truncate('${motifs.first.name} (${motifs.first.definitions.join(', ')})', 100))
            : Text('${motifs.length} motifs, ${matchWhenAll ? 'matching when ALL motifs are found' : 'matching separately'}');
  }
}

/// Widget that builds the panel with motif selection
class MotifPanel extends StatefulWidget {
  final Function(List<Motif> motif) onChanged;
  final List<Motif> motifs;

  const MotifPanel({super.key, required this.onChanged, required this.motifs});

  @override
  // ignore: no_logic_in_create_state
  State<MotifPanel> createState() => _MotifPanelState(motifs);
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
  
  late final List<Motif> _motifs;

  _MotifPanelState(List<Motif> motifs) {
    _motifs = motifs;
  }

  @override
  void initState() {
    super.initState();
  }

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
    final metadata = context.select<GeneModel, OrganismMetadata?>((model) => model.metadata);
    if (sourceGenes == null && metadata == null) return const Center(child: Text('Load source data first'));
    final motifs = context.select<GeneModel, List<Motif>>((model) => model.motifs);
    final matchWhenAll = context.select<GeneModel, bool>((model) => model.matchWhenAll);
    final customMotifs = motifs.where((m) => m.isCustom).toList();
    final textTheme = Theme.of(context).textTheme;
    final motifGroups = _groupMotifs(_motifs);
    
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
                if (!_showEditor)
                  TextButton(
                      onPressed: _handleOpenEditor,
                      child: const Text('Add custom motif…'))
              ],
            ),
            if (_showEditor) ...[
              _buildMotifEditor(),
              const SizedBox(height: 16),
              Text(
                  'R = AG, Y = CT, W = AT, S = GC, M = AC, K = GT, B = CGT, D = AGT, H = ACT, V = ACG, N = ACGT',
                  style: Theme.of(context).textTheme.labelMedium!),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 16.0),
            const Text('PRESETS'),
            const SizedBox(height: 16.0),
            Column(
              spacing: 8.0,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final group in motifGroups.entries)
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (motifGroups.length != 1)
                          Text(group.key, style: textTheme.titleSmall),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            ...group.value.map((m) => _MotifCard(
                                  motif: m,
                                  onToggle: (bool value) =>
                                      _handlePresetToggled(m, value),
                                  isSelected: motifs.contains(m),
                                  onDelete: () => setState(() {
                                    _motifs
                                        .removeWhere((idk) => idk.id == m.id);
                                  }),
                                )),
                          ],
                        )
                      ])
              ],
            ),
            const SizedBox(height: 16.0),
            Row(spacing: 4, children: [
              Switch(
                  value: matchWhenAll,
                  onChanged: (value) {
                    _model.matchWhenAll = value;
                  }),
              Column(
                  spacing: 2,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(spacing: 4, children: [
                      Text(
                          'Search only in genes containing all selected motifs'),
                      Text('(PREVIEW)',
                          style: TextStyle(fontWeight: FontWeight.bold))
                    ]),
                    Text(
                        '(By default, motifs are searched independently. This option restricts the analysis to genes that contain all selected motifs simultaneously.)',
                        style: textTheme.labelSmall)
                  ])
            ])
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

  SplayTreeMap<String, List<Motif>> _groupMotifs(List<Motif> motifs) {
    final motifGroups = SplayTreeMap<String, List<Motif>>();

    for (final motif in motifs) {
      if (motif.isPublic) {
        motifGroups.putIfAbsent('Public', () => []).add(motif);
      } else {
        motifGroups.putIfAbsent('Custom', () => []).add(motif);
      }
    }

    return motifGroups;
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

  Future<void> _handleAddMotif() async {
    if (_formKey.currentState!.validate()) {
      final definitions = _getDefinitions(_customMotifDefinition!);
      final name = (_customMotifName ?? '') != '' ? _customMotifName : definitions.first;
      final motif = Motif(name: name!, definitions: definitions, isCustom: true);

      if (_model.isSignedIn) {
        final newMotif = await createMotif(motif);
        _motifs.add(newMotif);
      } else {
        _model.setMotifs([motif, ..._model.motifs]);
      }
    }
    setState(() => _showEditor = false);
  }
}

class _MotifCard extends StatelessWidget {
  final Motif motif;
  final Function(bool value) onToggle;
  final bool isSelected;
  late final Function onDelete;
  _MotifCard({required this.motif, required this.onToggle, required this.isSelected, Function? onDelete}) {
    this.onDelete = onDelete ?? () {};
  }

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
                    Checkbox(
                        value: isSelected,
                        onChanged: (value) => onToggle(value!)),
                    Expanded(
                        child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(truncate(motif.name, 20),
                                style: textTheme.titleSmall))),
                    if (!motif.isPublic)
                      IconButton(
                          onPressed: () => _handleDelete(context),
                          icon: const Icon(Icons.delete_forever,
                              color: Colors.red))
                  ],
                ),
                const SizedBox(height: 8),
                FittedBox(
                    child: Text(truncate(motif.definitions.join(', '), 25),
                        style: textTheme.labelSmall)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleDelete(BuildContext context) async {
    final model = GeneModel.of(context);

    await deleteMotif(motif.id,
        onSuccess: onDelete, onError: (error) => context.showMessage(error));

    if (model.motifs.any((m) => m.id == motif.id)) {
      model.setMotifs(model.motifs.where((m) => m.id != motif.id).toList());
    }
  }
}
