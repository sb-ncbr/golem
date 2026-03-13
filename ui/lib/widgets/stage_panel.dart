import 'package:collection/collection.dart';
import 'package:faabul_color_picker/faabul_color_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geneweb/api/auth.dart';
import 'package:geneweb/models/user.dart';
import 'package:geneweb/models/organism.dart';
import 'package:geneweb/genes/stage_selection.dart';
import 'package:geneweb/genes/gene_list.dart';
import 'package:geneweb/genes/gene_model.dart';
import 'package:geneweb/utilities/color.dart';
import 'package:geneweb/utilities/message.dart';
import 'package:geneweb/utilities/stages.dart';
import 'package:provider/provider.dart';
import 'package:truncate/truncate.dart';
import 'package:url_launcher/url_launcher.dart';

/// Widget that is shown just below the panel headline
class StageSubtitle extends StatelessWidget {
  const StageSubtitle({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedStages = context.select<GeneModel, List<String>>(
        (model) => model.stageSelection?.selectedStages ?? []);
    final expectedResults =
        context.select<GeneModel, int>((model) => model.expectedSeriesCount);
    if (expectedResults > 60 && selectedStages.length > 5) {
      return Text(
          'Analysis would result in $expectedResults series, reduce the number of selected stages');
    }
    if (selectedStages.isEmpty) {
      return const Text('No stages selected');
    }
    final isMain = selectedStages.contains(GeneModel.kAllStages);
    final realStages =
        selectedStages.where((s) => s != GeneModel.kAllStages).toList();
    List<String> texts = [];
    if (isMain) texts.add('Genome');
    if (realStages.isNotEmpty) {
      texts.add(realStages.length == 1
          ? realStages.first
          : '${realStages.length} other stages');
    }
    return Text(texts.join(' and '));
  }
}

/// Widgewt that builds the panel with stage selection
class StagePanel extends StatefulWidget {
  final Function(StageSelection? selection) onChanged;

  const StagePanel({super.key, required this.onChanged});

  @override
  State<StagePanel> createState() => _StagePanelState();
}

class _StagePanelState extends State<StagePanel> {
  final _formKey = GlobalKey<FormState>();

  late List<String> _selectedStages;
  late FilterStrategy? _strategy;
  late FilterSelection? _selection;
  late List<double>? _percentiles;
  late int? _count;

  final _percentileController = TextEditingController();
  final _countController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _updateStateFromModel();
  }

  @override
  void dispose() {
    _percentileController.dispose();
    _countController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant StagePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.key != widget.key) {
      _updateStateFromModel();
    }
  }

  void _updateStateFromModel() {
    final filter = GeneModel.of(context).stageSelection ??
        StageSelection(selectedStages: []);
    _selectedStages = filter.selectedStages;
    _strategy = filter.strategy;
    _selection = filter.selection;
    _percentiles = filter.percentiles;
    _count = filter.count;
    _percentileController.text =
        '${((_percentiles!.firstOrNull ?? 0) * 100).round()}';
    _countController.text = '$_count';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final allowFilter = context
        .select<GeneModel, bool>((model) => model.sourceGenes?.stages == null);
    final sourceGenes =
        context.select<GeneModel, GeneList?>((model) => model.sourceGenes);
    final metadata =
        context.select<GeneModel, OrganismMetadata?>((model) => model.metadata);
    if (sourceGenes == null && metadata == null)
      return const Center(child: Text('Load source data first'));
    return Align(
      alignment: Alignment.topLeft,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ALL GENES', style: textTheme.titleSmall),
            Text('Distribution of the motif across all genes.',
                style: textTheme.bodySmall),
            const SizedBox(height: 16),
            _StageCard(
              name: 'ALL GENES',
              color: null,
              isSelected:
                  _selectedStages.contains(GeneModel.kAllStages) == true,
              showPicker: false,
              onToggle: (value) => _handleToggle(GeneModel.kAllStages, value),
            ),
            const SizedBox(height: 16),
            Text('DEVELOPMENTAL STAGES', style: textTheme.titleSmall),
            Text(
                'Distribution of the motif in genes with elevated transcript levels in certain developmental stage.',
                style: textTheme.bodySmall),
            const SizedBox(height: 16),
            Consumer<GeneModel>(builder: (context, model, child) {
              final sourceGenes = model.sourceGenes;
              final stageKeys = model.stageKeys ?? sourceGenes?.stageKeys ?? [];
              final stageGroups = _groupStages(stageKeys);

              for (final stage in stageKeys) {
                sourceGenes?.colors[stage] ??= randomStageColor(stage);
              }

              final orderedKeys = stageGroups.keys.sorted((a, b) => switch ((
                    a,
                    b
                  )) {
                    ('Other', _) => 1,
                    (_, 'Other') => -1,
                    (String a, String b) => a.compareTo(b)
                  });

              return Column(
                spacing: 8,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final key in orderedKeys)
                    _StageGroup(
                      stageGroup: stageGroups[key]!,
                      onStageToggle: _handleToggle,
                      onGroupToggle: () =>
                          _handleToggleGroup(stageGroups[key]!),
                      groupTitle: key,
                      showGroupTitle: stageGroups.length != 1,
                    ),
                ],
              );
            }),
            if (allowFilter) ...[
              const SizedBox(height: 16),
              Text('Choose the transcript level based on TPM:',
                  style: textTheme.titleSmall),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  CupertinoSlidingSegmentedControl<FilterStrategy>(
                    children: const {
                      FilterStrategy.top: Text('Most transcribed'),
                      FilterStrategy.bottom: Text('Least transcribed'),
                    },
                    onValueChanged: (value) {
                      setState(() => _strategy = value!);
                      _handleChanged();
                    },
                    groupValue: _strategy,
                  ),
                  if (_selection == FilterSelection.percentile)
                    SizedBox(
                      width: 400,
                      child: TextFormField(
                        controller: _percentileController,
                        decoration: const InputDecoration(
                            labelText: 'Percentiles', suffix: Text('th')),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setState(() {
                            _percentiles =
                                _parsePercentiles(_percentileController.text);
                          });
                          _handleChanged();
                        },
                        validator: (value) {
                          final percentiles =
                              _parsePercentiles(_percentileController.text);
                          if (percentiles.any(
                                  (parsed) => parsed < 0 || parsed > 100) ||
                              percentiles.isEmpty) {
                            return 'Enter one or more numbers between 0 and 100 separated by commas.';
                          }
                          return null;
                        },
                      ),
                    ),
                  if (_selection == FilterSelection.fixed)
                    SizedBox(
                      width: 200,
                      child: TextFormField(
                        controller: _countController,
                        decoration: const InputDecoration(labelText: 'Count'),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setState(() => _count =
                              (int.tryParse(_countController.text) ?? 0).clamp(
                                  0,
                                  sourceGenes?.genes.length ??
                                      metadata!.genes.length));
                          _handleChanged();
                        },
                        validator: (value) {
                          final parsed = int.tryParse(_countController.text);
                          if (parsed == null ||
                              parsed < 0 ||
                              parsed >
                                  (sourceGenes?.genes.length ??
                                      metadata!.genes.length)) {
                            return 'Enter a number between 0 and ${sourceGenes?.genes.length ?? metadata!.genes.length}';
                          }
                          return null;
                        },
                      ),
                    ),
                  CupertinoSlidingSegmentedControl<FilterSelection>(
                    children: const {
                      FilterSelection.fixed: Text('Genes'),
                      FilterSelection.percentile: Text('Percentile'),
                    },
                    onValueChanged: (value) {
                      setState(() => _selection = value!);
                      _handleChanged();
                    },
                    groupValue: _selection,
                  ),
                ],
              ),
              if (_selection == FilterSelection.percentile) ...[
                const SizedBox(height: 16),
                Text(
                    'By default, the genes included in the analysis from each stage are those genes whose transcripts represent 90% of all transcripts transcribed from the total number of protein-coding genes in the selected stage.',
                    style: textTheme.labelMedium),
                Text(
                    'Multiple percentiles (e.g., 90%, 80%, 70%) can be visualized simultaneously by entering the values separated by commas (e.g., 90,80,70).',
                    style: textTheme.labelMedium),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _formatPercentiles(List<double> percentiles) {
    return percentiles
        .map((p) => '${((p) * 100).toStringAsFixed(2)}%')
        .join(', ');
  }

  void _handleChanged() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      widget.onChanged(StageSelection(
        selectedStages: _selectedStages,
        strategy: _strategy,
        selection: _selection,
        percentiles: _percentiles,
        count: _count,
      ));
    } else {
      assert(false);
    }
  }

  void _handleToggle(String key, bool value) {
    setState(() {
      if (value) {
        _selectedStages.add(key);
      } else {
        _selectedStages.remove(key);
      }
    });
    _handleChanged();
  }

  void _handleToggleGroup(List<String> group) {
    setState(() {
      final allSelected =
          group.every((stage) => _selectedStages.contains(stage));
      if (!allSelected) {
        final notSelected =
            group.where((stage) => !_selectedStages.contains(stage));
        _selectedStages.addAll(notSelected);
      } else {
        _selectedStages.removeWhere((stage) => group.contains(stage));
      }
      _handleChanged();
    });
  }

  Map<String, List<String>> _groupStages(List<String> stages) {
    final stageGroups = <String, List<String>>{};
    final allGroups = groupBy(stages, (String key) => key.split('_').first);

    for (final entry in allGroups.entries) {
      final groupKey = entry.key;
      final groupStages = entry.value;

      // this should not happen
      if (groupStages.isEmpty) continue;

      if (groupStages.length == 1) {
        stageGroups.putIfAbsent('Other', () => []).add(groupStages.first);
      } else {
        stageGroups[groupKey] = entry.value;
      }
    }

    return stageGroups;
  }

  List<double> _parsePercentiles(String rawText) {
    return rawText
        .trim()
        .replaceAll(RegExp(r'\s'), '')
        .split(',')
        .where((p) => p.isNotEmpty)
        .map((p) => ((double.tryParse(p) ?? 0) / 100).clamp(0, 1))
        .toList()
        .cast<double>()
        .sorted((a, b) => b.compareTo(a));
  }
}

class _StageCard extends StatelessWidget {
  final String name;
  final StageMetadata? metadata;
  final Color? color;
  final bool isSelected;
  final bool showPicker;
  final Function(bool value) onToggle;
  const _StageCard(
      {required this.name,
      required this.color,
      required this.isSelected,
      required this.onToggle,
      this.showPicker = true,
      this.metadata});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final backgroundColor = isSelected
        ? (color ?? Colors.grey)
        : (color ?? Colors.grey).withValues(alpha: 0.4);
    final textColor =
        backgroundColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    return SizedBox(
      width: 160,
      height: 120,
      child: Card(
        color: backgroundColor,
        child: InkWell(
          onTap: () => onToggle(!isSelected),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      truncate(name.replaceAll('_', ' '), 60),
                      overflow: TextOverflow.fade,
                      style: textTheme.titleSmall?.copyWith(color: textColor),
                      maxLines: 3,
                    ),
                    if (metadata != null && metadata!.srr.isNotEmpty)
                      TextButton(
                          style: const ButtonStyle(
                              padding: WidgetStatePropertyAll(
                                  EdgeInsetsGeometry.all(0))),
                          onPressed: () => metadata!.url.isNotEmpty
                              ? launchUrl(Uri.parse(metadata!.url))
                              : null,
                          child: Text(
                            truncate(metadata!.srr, 60),
                            overflow: TextOverflow.fade,
                            style: textTheme.bodySmall?.copyWith(
                                color: textColor.withValues(alpha: .8)),
                            textAlign: TextAlign.start,
                            maxLines: 3,
                          )),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Checkbox(
                        value: isSelected,
                        onChanged: (value) => onToggle(value!)),
                    if (GeneModel.of(context).isSignedIn && showPicker)
                      InkWell(
                          onTap: () => _showColorPickerDialog(context, name),
                          child: const Padding(
                              padding: EdgeInsetsGeometry.only(right: 4),
                              child: Icon(Icons.colorize_rounded))),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showColorPickerDialog(BuildContext context, String stage) {
    showColorPickerDialog(context: context, selected: color ?? Colors.grey)
        .then((newColor) async {
      if (newColor != null && context.mounted) {
        final organism = GeneModel.of(context).sourceGenes?.organism;
        final response = await updatePreference(StagePreference(
            stageName: name,
            color: newColor.toHex(),
            organismId: organism?.id));
        if (!response.success && context.mounted) {
          context.showMessage(response.message);
        } else if (context.mounted) {
          GeneModel.of(context)
              .setStagePreferenceColor(stage, newColor.toHex());
        }
      }
    });
  }
}

class _StageGroup extends StatelessWidget {
  final List<String> stageGroup;
  final String? groupTitle;
  final bool showGroupTitle;
  final Function(String, bool) onStageToggle;
  final VoidCallback onGroupToggle;

  const _StageGroup(
      {required this.stageGroup,
      required this.onStageToggle,
      required this.onGroupToggle,
      this.groupTitle = '',
      this.showGroupTitle = true});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final sourceGenes =
        context.select<GeneModel, GeneList?>((model) => model.sourceGenes);
    final filter = context.select<GeneModel, StageSelection>(
        (model) => model.stageSelection ?? StageSelection(selectedStages: []));
    final metadata =
        context.select<GeneModel, Map<String, StageMetadata>>(((model) {
      final metadata = model.metadata?.stages ?? {};
      final stageKeys = metadata.keys.where((k) => stageGroup.contains(k));
      return {for (var sKey in stageKeys) sKey: metadata[sKey]!};
    }));
    return Column(
      spacing: 4,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          if (showGroupTitle)
            Text(groupTitle ?? '', style: textTheme.titleSmall),
          TextButton(
              onPressed: onGroupToggle, child: const Text('Toggle group')),
        ]),
        Wrap(
          children: [
            for (final stage in stageGroup)
              _StageCard(
                name: stage,
                color: sourceGenes?.colors[stage],
                isSelected: filter.selectedStages.contains(stage),
                metadata: metadata[stage],
                onToggle: (value) => onStageToggle(stage, value),
              ),
          ],
        )
      ],
    );
  }
}
