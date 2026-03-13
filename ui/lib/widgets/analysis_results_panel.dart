import 'dart:js_interop' as js;

import 'package:archive/archive_io.dart';
import 'package:faabul_color_picker/faabul_color_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geneweb/analysis/analysis_series.dart';
import 'package:geneweb/models/motif.dart';
import 'package:geneweb/models/organism.dart';
import 'package:geneweb/api/api_service.dart';
import 'package:geneweb/genes/gene_list.dart';
import 'package:geneweb/genes/gene_model.dart';
import 'package:geneweb/genes/stage_selection.dart';
import 'package:geneweb/output/distributions_export.dart';
import 'package:geneweb/output/analysis_series_export.dart';
import 'package:geneweb/utilities/download.dart';
import 'package:geneweb/widgets/distribution_view.dart';
import 'package:geneweb/widgets/drill_down_view.dart';
import 'package:geneweb/widgets/result_series_list.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'package:sanitize_filename/sanitize_filename.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web/web.dart' as web;

/// Widget that builds the results panel
class AnalysisResultsPanel extends StatefulWidget {
  const AnalysisResultsPanel({super.key});

  @override
  State<AnalysisResultsPanel> createState() => _AnalysisResultsPanelState();
}

class _AnalysisResultsPanelState extends State<AnalysisResultsPanel> {
  late final _scaffoldMessenger = ScaffoldMessenger.of(context);
  late final _model = GeneModel.of(context);

  bool _usePercentages = true;
  bool _groupByGenes = true;
  bool _customAxis = false;
  double? _verticalAxisMin;
  double? _verticalAxisMax;
  double? _horizontalAxisMin;
  double? _horizontalAxisMax;

  String? _selectedAnalysisName;

  double? _exportProgress;
  double? _inputExportProgress;

  late final _verticalAxisMinController = TextEditingController()
    ..addListener(_axisListener);
  late final _verticalAxisMaxController = TextEditingController()
    ..addListener(_axisListener);
  late final _horizontalAxisMinController = TextEditingController()
    ..addListener(_axisListener);
  late final _horizontalAxisMaxController = TextEditingController()
    ..addListener(_axisListener);

  @override
  void dispose() {
    _verticalAxisMinController.dispose();
    _verticalAxisMaxController.dispose();
    _horizontalAxisMinController.dispose();
    _horizontalAxisMaxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sourceGenes =
        context.select<GeneModel, GeneList?>((model) => model.sourceGenes);
    final metadata =
        context.select<GeneModel, OrganismMetadata?>((model) => model.metadata);
    final motifs =
        context.select<GeneModel, List<Motif>>((model) => model.motifs);
    final filter = context
        .select<GeneModel, StageSelection?>((model) => model.stageSelection);
    final analyses = context
        .select<GeneModel, List<AnalysisSeries>>((model) => model.analyses);
    final visibleAnalyses = context.select<GeneModel, List<AnalysisSeries>>(
        (model) => model.analyses.where((a) => a.visible).toList());
    final analysisProgress =
        context.select<GeneModel, double?>((model) => model.analysisProgress);
    final analysisCancelled =
        context.select<GeneModel, bool>((model) => model.analysisCancelled);
    final expectedResults =
        context.select<GeneModel, int>((model) => model.expectedSeriesCount);
    final analysis = context.select<GeneModel, AnalysisSeries?>((model) => model
        .analyses
        .firstWhereOrNull((a) => a.name == _selectedAnalysisName));
    final canAnalyzeErrors = [
      if (sourceGenes == null) 'no source genes selected',
      if (motifs.isEmpty) 'no motifs selected',
      if (filter?.selectedStages.isEmpty == true) 'no stages selected',
      if (expectedResults > 60) 'too many results (max 60)',
    ];
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (canAnalyzeErrors.isNotEmpty) ...[
            Text('Analysis cannot be run: ${canAnalyzeErrors.join(', ')}',
                style: TextStyle(color: colorScheme.error)),
            const SizedBox(height: 16),
          ],
          if (analysisProgress != null) ...[
            const SizedBox(height: 16),
            Column(
              children: [
                Text(
                    'Analysis in progress… (${(analysisProgress * 100).round()}% complete)',
                    style: textTheme.bodySmall),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                        child:
                            LinearProgressIndicator(value: analysisProgress)),
                    IconButton(
                      onPressed: analysisCancelled ? null : _handleStopAnalysis,
                      tooltip: 'Stop analysis',
                      icon: Icon(Icons.cancel, color: colorScheme.primary),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          if (analyses.isEmpty && analysisProgress == null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: _handleAnalyze, child: const Text('Run Analysis')),
            const SizedBox(height: 16),
            if (expectedResults > 20) ...[
              Text(
                  'Warning: This analysis will produce $expectedResults series. Analysis may take a long time and consume a lot of system memory. Consider reducing the amount of motifs and/or stages.',
                  style: TextStyle(color: colorScheme.error)),
              const SizedBox(height: 16),
            ],
          ] else if (analysisProgress != null)
            const SizedBox.shrink()
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (analysis != null)
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      Icon(Icons.check_box, color: colorScheme.outline),
                      Text(analysis.name, style: textTheme.titleMedium),
                      if (_exportProgress != null)
                        _ExportIndicator(exportProgress: _exportProgress)
                      else
                        TextButton(
                            onPressed: () =>
                                _handleExportSingleSeries(analysis),
                            child: const Text('Export this series')),
                      TextButton(
                          onPressed: () => _handleAnalysisSelected(null),
                          child: const Text('Deselect')),
                    ],
                  )
                else
                  Wrap(
                    spacing: 8,
                    children: [
                      if (visibleAnalyses.isNotEmpty)
                        if (_exportProgress != null)
                          _ExportIndicator(exportProgress: _exportProgress)
                        else
                          TextButton(
                              onPressed: analysisProgress == null
                                  ? () => _handleExportAllSeries(context)
                                  : null,
                              child: Text(
                                  'Export ${visibleAnalyses.length} series')),
                      TextButton(
                        onPressed: () {
                          // TODO: move url somewhere else
                          launchUrl(Uri.parse(
                              'https://docs.google.com/spreadsheets/d/1bLh3luBKC20eGzZnWfFclEVoLI1yUXnE/edit?pli=1&gid=1975064856#gid=1975064856'));
                        },
                        child: const Text('Source data'),
                      ),
                      if (_inputExportProgress != null)
                        _ExportIndicator(exportProgress: _inputExportProgress)
                      else if (sourceGenes != null && metadata != null)
                        TextButton(
                          statesController:
                              WidgetStatesController({WidgetState.disabled}),
                          onPressed: () async {
                            setState(() {
                              _inputExportProgress = .2;
                            });

                            final organism = sourceGenes.organism!;
                            final exportResponse = await ApiService.instance
                                .download('/organisms/export/${organism.id}');

                            if (!exportResponse.success) {
                              _scaffoldMessenger.showSnackBar(const SnackBar(
                                  content:
                                      Text('Unable to download source data.'),
                                  backgroundColor: Colors.red));
                              return;
                            }

                            setState(() {
                              _inputExportProgress = .6;
                            });

                            downloadFile(exportResponse.data, 'application/zip',
                                'source_data.zip');
                            setState(() {
                              _inputExportProgress = null;
                            });
                          },
                          child: const Text('Download input data'),
                        )
                    ],
                  ),
                TextButton(
                    onPressed: _handleResetAnalyses,
                    child: const Text('Close analysis')),
              ],
            ),
          if (analyses.isNotEmpty) ...[
            const Divider(height: 16),
            Expanded(child: _buildResults(context)),
          ],
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    final analyses = context
        .select<GeneModel, List<AnalysisSeries>>((model) => model.analyses);
    assert(analyses.isNotEmpty);
    final analysis = context.select<GeneModel, AnalysisSeries?>((model) => model
        .analyses
        .firstWhereOrNull((a) => a.name == _selectedAnalysisName));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
            width: 400,
            child: ResultSeriesList(onSelected: _handleAnalysisSelected)),
        const VerticalDivider(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGraphSettings(),
              _buildCustomGraphAxisSettings(),
              const SizedBox(height: 16),
              Expanded(flex: 2, child: _buildGraph()),
              const SizedBox(height: 16),
              if (analysis != null) ...[
                const Divider(),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _buildAnalysisRowSettings(analysis)),
                      Expanded(
                          child: DrillDownView(name: _selectedAnalysisName)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  SizedBox _buildGraph() {
    return SizedBox(
        height: 400,
        child: DistributionView(
          focus: _selectedAnalysisName,
          usePercentages: _usePercentages,
          groupByGenes: _groupByGenes,
          verticalAxisMin: _customAxis ? _verticalAxisMin : null,
          verticalAxisMax: _customAxis ? _verticalAxisMax : null,
          horizontalAxisMin: _customAxis ? _horizontalAxisMin : null,
          horizontalAxisMax: _customAxis ? _horizontalAxisMax : null,
        ));
  }

  AnimatedSize _buildCustomGraphAxisSettings() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: _customAxis
          ? Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      decoration:
                          const InputDecoration(labelText: 'Vertical axis min'),
                      controller: _verticalAxisMinController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      decoration:
                          const InputDecoration(labelText: 'Vertical axis max'),
                      controller: _verticalAxisMaxController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      decoration: const InputDecoration(
                          labelText: 'Horizontal axis min'),
                      controller: _horizontalAxisMinController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      decoration: const InputDecoration(
                          labelText: 'Horizontal axis max'),
                      controller: _horizontalAxisMaxController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }

  Row _buildGraphSettings() {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Show '),
        CupertinoSlidingSegmentedControl<bool>(
          children: const {
            false: Text('Motifs'),
            true: Text('Genes'),
          },
          onValueChanged: (value) => setState(() => _groupByGenes = value!),
          groupValue: _groupByGenes,
        ),
        const SizedBox(width: 16),
        const Text('as '),
        CupertinoSlidingSegmentedControl<bool>(
          children: const {
            false: Text('Counts'),
            true: Text('Percentages'),
          },
          onValueChanged: (value) => setState(() => _usePercentages = value!),
          groupValue: _usePercentages,
        ),
        const SizedBox(width: 16),
        const Text('Axis: '),
        CupertinoSlidingSegmentedControl<bool>(
          children: const {
            false: Text('Auto'),
            true: Text('Custom'),
          },
          onValueChanged: _setAxis,
          groupValue: _customAxis,
        ),
      ],
    );
  }

  void _handleAnalyze() async {
    final result = await _model.analyze();
    if (result) {
      _scaffoldMessenger
          .showSnackBar(const SnackBar(content: Text('Analysis complete')));
    } else {
      _scaffoldMessenger.showSnackBar(const SnackBar(
          backgroundColor: Colors.red, content: Text('Analysis cancelled')));
    }
  }

  void _setAxis(bool? value) {
    setState(() => _customAxis = value!);
  }

  void _axisListener() {
    setState(() {
      _verticalAxisMin = _verticalAxisMinController.text.isEmpty
          ? null
          : double.tryParse(_verticalAxisMinController.text);
      _verticalAxisMax = _verticalAxisMaxController.text.isEmpty
          ? null
          : double.tryParse(_verticalAxisMaxController.text);
      _horizontalAxisMin = _horizontalAxisMinController.text.isEmpty
          ? null
          : double.tryParse(_horizontalAxisMinController.text);
      _horizontalAxisMax = _horizontalAxisMaxController.text.isEmpty
          ? null
          : double.tryParse(_horizontalAxisMaxController.text);
    });
  }

  void _handleResetAnalyses() {
    Navigator.of(context).pop();
  }

  void _handleAnalysisSelected(String? selected) {
    setState(() => _selectedAnalysisName = selected);
  }

  Widget _buildAnalysisRowSettings(AnalysisSeries analysis) {
    return ListView(
      children: [
        CheckboxListTile(
            title: const Text('Enabled'),
            value: analysis.visible,
            onChanged: (value) => _handleSetVisibility(analysis, value)),
        ListTile(
            title: const Text('Color'),
            trailing: FaabulColorSample(color: analysis.color),
            onTap: () => _handleSetColor(analysis)),
        ListTile(
            title: const Text('Stroke'),
            trailing: CupertinoSlidingSegmentedControl<int>(
              children: const {
                2: Text('Thin'),
                4: Text('Normal'),
                8: Text('Thick'),
              },
              onValueChanged: (value) => _handleSetStroke(analysis, value),
              groupValue: analysis.stroke,
            )),
      ],
    );
  }

  void _updateAnalysis(GeneModel model, AnalysisSeries analysis) {
    model.setAnalyses([
      for (final a in model.analyses)
        if (a.name == analysis.name) analysis else a
    ]);
  }

  Future<void> _handleSetColor(AnalysisSeries analysis) async {
    final model = GeneModel.of(context);
    final color =
        await showColorPickerDialog(context: context, selected: analysis.color);
    _updateAnalysis(model, analysis.copyWith(color: color));
  }

  void _handleSetStroke(AnalysisSeries analysis, int? value) {
    final model = GeneModel.of(context);
    _updateAnalysis(model, analysis.copyWith(stroke: value ?? 4));
  }

  void _handleSetVisibility(AnalysisSeries analysis, bool? value) {
    final model = GeneModel.of(context);
    _updateAnalysis(model, analysis.copyWith(visible: value ?? true));
  }

  Future<void> _handleExportSingleSeries(AnalysisSeries analysis) async {
    setState(() => _exportProgress = 0);
    final output = AnalysisSeriesExport(analysis);
    final filename = sanitizeFilename('${analysis.name}.xlsx');

    final data = await output.toExcelAndSave(filename,
        progressCallback: (progress) =>
            setState(() => _exportProgress = progress));
    if (data == null) return;
    debugPrint('Saving $filename (${data.length} bytes)');
    setState(() => _exportProgress = null);
  }

  Future<void> _handleExportAllSeries(BuildContext context) async {
    setState(() => _exportProgress = 0);

    final analyses =
        _model.analyses.where((analysis) => analysis.visible).toList();
    final totalTasks = analyses.length + 1; // all series + distribution
    final zipEncoder = ZipEncoder();
    final archive = Archive();

    for (var i = 0; i < analyses.length; i++) {
      final analysis = analyses[i];
      final export = AnalysisSeriesExport(analysis);
      final filename = sanitizeFilename('${analysis.name}.xlsx');
      final data = await export.toExcel(filename);

      setState(() => _exportProgress = (i + 1) / totalTasks);

      final encodedData = data.encode();
      if (encodedData != null) {
        archive.addFile(ArchiveFile(filename, encodedData.length, encodedData));
      }
    }

    final distributionOutput =
        DistributionsExport(analyses.map((e) => e.distribution!).toList());
    final stageName = _model.stageSelection!.selectedStages.length == 1
        ? _model.stageSelection!.selectedStages.first
        : '${_model.stageSelection!.selectedStages.length} stages';
    final motifName = _model.motifs.length == 1
        ? _model.motifs.first
        : '${_model.motifs.length} motifs';
    final filename =
        'distributions_${_model.name}_${motifName}_$stageName.xlsx';
    final distributionExcel = await distributionOutput.toExcel(filename);

    final encodedDistribution = distributionExcel.encode();
    if (encodedDistribution != null) {
      archive.addFile(ArchiveFile(
          filename, encodedDistribution.length, encodedDistribution));
    }

    downloadFile(zipEncoder.encode(archive), 'application/zip', 'series.zip');

    setState(() => _exportProgress = null);
  }

  void _handleStopAnalysis() {
    _model.cancelAnalysis();
  }
}

class _ExportIndicator extends StatelessWidget {
  const _ExportIndicator({
    required double? exportProgress,
  }) : _exportProgress = exportProgress;

  final double? _exportProgress;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: CircularProgressIndicator(value: _exportProgress!),
      label: const Text('Preparing export…'),
    );
  }
}
