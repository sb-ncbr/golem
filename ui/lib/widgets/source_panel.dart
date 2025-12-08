import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geneweb/api/api_service.dart';
import 'package:geneweb/api/organism.dart';
import 'package:geneweb/genes/gene_list.dart';
import 'package:geneweb/genes/gene_model.dart';
import 'package:provider/provider.dart';

/// Widget shown just below the panel headline
class SourceSubtitle extends StatelessWidget {
  const SourceSubtitle({super.key});

  @override
  Widget build(BuildContext context) {
    final sourceGenes =
        context.select<GeneModel, GeneList?>((model) => model.sourceGenes);
    final name = context.select<GeneModel, String?>((model) => model.name);
    return sourceGenes == null
        ? const Text(
            'Motif positions are mapped relative to the transcription start sites (TSS) or translation start site (ATG)')
        : Wrap(
            children: [
              Text('$name',
                  style: const TextStyle(fontStyle: FontStyle.italic)),
              Text(
                  ', ${sourceGenes.genes.length} genes, ${sourceGenes.stageKeys.length} stages'),
            ],
          );
  }
}

/// Widget that builds the panel with organism selection
class SourcePanel extends StatefulWidget {
  const SourcePanel({super.key, required this.onShouldClose});

  final VoidCallback onShouldClose;

  @override
  State<SourcePanel> createState() => _SourcePanelState();
}

class _SourcePanelState extends State<SourcePanel> {
  String? _loadingMessage;
  double? _progress;

  late final _model = GeneModel.of(context);
  late final _scaffoldMessenger = ScaffoldMessenger.of(context);
  late Future<List<Organism>> futureOrganisms;

  @override
  Widget build(BuildContext context) {
    final sourceGenes =
        context.select<GeneModel, GeneList?>((model) => model.sourceGenes);
    return Align(
        alignment: Alignment.topLeft,
        child: _loadingMessage != null
            ? _buildLoadingState()
            : sourceGenes == null
                ? _buildLoad(context)
                : _buildLoadedState(context));
  }

  @override
  void initState() {
    super.initState();
    futureOrganisms = _fetchOrganisms();
    context.read<GeneModel>().userNotifier.addListener(_onUserChanged);
  }

  @override
  void dispose() {
    context.read<GeneModel>().userNotifier.removeListener(_onUserChanged);
    super.dispose();
  }

  void _onUserChanged() {
    setState(() {
      futureOrganisms = _fetchOrganisms();
    });
  }

  Widget _buildLoadingState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_loadingMessage!, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 16),
        LinearProgressIndicator(value: _progress),
      ],
    );
  }

  Widget _buildLoad(BuildContext context) {
    final publicSite =
        context.select<GeneModel, bool>((model) => model.publicSite);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          spacing: 8.0,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder(
                future: futureOrganisms,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final organismGroups = _groupOrganisms(snapshot.data!);
                    return Column(
                        spacing: 8.0,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final group in organismGroups.entries)
                            _OrganismGroup(
                              organisms: group.value,
                              title: group.key,
                              showTitle: organismGroups.length != 1,
                              onPickOrganism: _handlePickOrganism,
                            ),
                        ]);
                  } else if (snapshot.hasError) {
                    return Text('${snapshot.error}');
                  }
                  return const CircularProgressIndicator();
                }),
            if (!publicSite)
              TextButton(
                  onPressed: _handlePickFastaFile,
                  child: const Text('Load custom .fasta file…')),
          ],
        ),
      ],
    );
  }

  Map<String, List<Organism>> _groupOrganisms(List<Organism> organisms) {
    final model = GeneModel.of(context);
    final publicGroups = organisms.groupListsBy((o) => o.public);
    final result = <String, List<Organism>>{'public': publicGroups[true] ?? []};

    if (model.user == null) {
      return result;
    }

    for (Organism organism in publicGroups[false] ?? []) {
      final groups = model.isAdmin
          ? organism.groups
          // intersection of user and organism groups
          : organism.groups
              .where((g) => model.user!.groups.any((ug) => ug.id == g.id));

      for (final group in groups) {
        result.putIfAbsent(group.name, () => []).add(organism);
      }
    }

    return result;
  }

  Widget _buildLoadedState(BuildContext context) {
    final publicSite =
        context.select<GeneModel, bool>((model) => model.publicSite);
    final sourceGenes =
        context.select<GeneModel, GeneList>((model) => model.sourceGenes!);
    final sampleErrors = sourceGenes.errors.take(100);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!publicSite)
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton(
                  onPressed: _handlePickTPMFile,
                  child: const Text('Add custom TPM (.csv)…')), //TODO
              TextButton(
                  onPressed: _handlePickStagesFile,
                  child: const Text('Add custom Stages (.csv)…')),
            ],
          ),
        const SizedBox(height: 16),
        TextButton(
            onPressed: _handleClear,
            child: const Text('Choose another species…')),
        if (sourceGenes.errors.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 16.0),
            color: Theme.of(context).colorScheme.errorContainer,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...sampleErrors.map((e) => Text('$e',
                    style: TextStyle(
                        color:
                            Theme.of(context).colorScheme.onErrorContainer))),
                if (sourceGenes.errors.length > sampleErrors.length)
                  Text(
                      'and ${sourceGenes.errors.length - sampleErrors.length} other errors.',
                      style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onErrorContainer)),
              ],
            ),
          ),
      ],
    );
  }


  Future<void> _handlePickOrganism(Organism organism) async {
    final model = GeneModel.of(context);
    await _handleDownloadMetadata(organism);


    final content = await _download(organism.sequencesFilename);
    final filename = organism.sequencesFilename.replaceAll('.gz', '');

    model.loading = LoadingState(
        isLoading: true,
        progress: 0.8,
        message: 'Analyzing $filename…');

    await Future.delayed(const Duration(milliseconds: 20));
    await model.loadFastaFromString(
        organism: organism,
        data: content,
        progressCallback: (value) {
          model.loading = model.loading.copyWith(progress: 0.8 + value * 0.2);
        });
    
    model.loading = LoadingState(isLoading: false);
  }

  Future<void> _handlePickFastaFile() async {
    try {
      setState(() => _loadingMessage = 'Picking file…');
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result == null) {
        return;
      }

      _model.metadata = null;

      final filename = result.files.single.name;
      setState(() => _loadingMessage = 'Loading $filename…');
      await Future.delayed(const Duration(milliseconds: 100));
      
      final organism = Organism.fromFile(filename);
      if (kIsWeb) {
        final data = const Utf8Decoder().convert(result.files.single.bytes!);
        debugPrint('Loaded ${data.length ~/ (1024 * 1024)} MB');
        await _model.loadFastaFromString(
          data: data,
          organism: organism,
          progressCallback: (value) => setState(() => _progress = value),
        );
      } else {
        final path = result.files.single.path!;
        await _model.loadFastaFromFile(
          path: path,
          organism: organism,
          filename: filename,
          progressCallback: (value) => setState(() => _progress = value),
        );
      }
      if (_model.sourceGenes!.errors.isEmpty) {
        _scaffoldMessenger.showSnackBar(SnackBar(
            content:
                Text('Imported ${_model.sourceGenes?.genes.length} genes.')));
      } else {
        _scaffoldMessenger.showSnackBar(SnackBar(
            backgroundColor: Colors.red,
            content: Text(
                'Imported ${_model.sourceGenes?.genes.length} genes, ${_model.sourceGenes?.errors.length} errors.')));
      }
      if (_model.publicSite) {
        widget.onShouldClose();
      }
    } catch (error) {
      _scaffoldMessenger.showSnackBar(SnackBar(
        content: Text('Error loading data: $error'),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() => _loadingMessage = null);
    }
  }

  Future<void> _handlePickStagesFile() async {
    try {
      setState(() => _loadingMessage = 'Picking file…');
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result == null) {
        return;
      }
      final filename = result.files.single.name;
      setState(() => _loadingMessage = 'Loading $filename…');
      await Future.delayed(const Duration(milliseconds: 100));
      bool status;
      if (kIsWeb) {
        final data = const Utf8Decoder().convert(result.files.single.bytes!);
        debugPrint('Loaded ${data.length} bytes');
        status = _model.loadStagesFromString(data);
      } else {
        final path = result.files.single.path!;
        status = await _model.loadStagesFromFile(path);
      }

      _scaffoldMessenger.showSnackBar(SnackBar(
          content: Text(
              'Imported ${_model.sourceGenes?.stages?.length ?? 0} stages.')));
      if (status) {
        widget.onShouldClose();
      }
    } catch (error) {
      _scaffoldMessenger.showSnackBar(SnackBar(
        content: Text('Error loading data: $error'),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() => _loadingMessage = null);
    }
  }

  Future<void> _handleDownloadMetadata(Organism organism) async {
    final model = GeneModel.of(context);

    setState(() => _loadingMessage = 'Loading ${organism.name} metadata…');
    setState(() => _progress = 0.3);
    final metadata = await fetchMetadata(
        organism: organism,
        onError: (message) => _scaffoldMessenger.showSnackBar(SnackBar(
              content: Text(message),
              backgroundColor: Colors.red,
            )));

    model.metadata = metadata;

    final stages = metadata?.values.firstOrNull?.transcriptionRates.keys ?? [];
    organism.stages.addAll(stages);

    widget.onShouldClose();
    setState(() => _loadingMessage = null);
    setState(() => _progress = null);
  }
  
  Future<String> _download(String filename) async {
    final model = GeneModel.of(context);
    try {
      model.loading = LoadingState(isLoading: true, message: 'Downloading $filename.', progress: 0.3);
      debugPrint('Preparing download of $filename');
      await Future.delayed(const Duration(milliseconds: 100));

      final response =
          await ApiService.instance.download('/organisms/$filename');

      if (!response.success) {
        _scaffoldMessenger.showSnackBar(SnackBar(
          content: Text(response.message),
          backgroundColor: Colors.red,
        ));
        throw Exception(response.message);
      }

      return String.fromCharCodes(response.data);
    } catch (_) {
      model.loading = LoadingState(isLoading: false);
      rethrow;
    }
  }


  void _handleClear() {
    _model.reset();
    _scaffoldMessenger.showSnackBar(const SnackBar(
        content:
            Text('Cleared all data. Please pick a new organism to analyze.')));
  }

  Future<void> _handlePickTPMFile() async {
    try {
      setState(() => _loadingMessage = 'Picking file…');
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result == null) {
        return;
      }
      final filename = result.files.single.name;
      setState(() => _loadingMessage = 'Loading $filename…');
      await Future.delayed(const Duration(milliseconds: 100));
      bool status;
      if (kIsWeb) {
        final data = const Utf8Decoder().convert(result.files.single.bytes!);
        debugPrint('Downloaded ${data.length ~/ (1024 * 1024)} MB');
        status = _model.loadTPMFromString(data);
      } else {
        final path = result.files.single.path!;
        status = await _model.loadTPMFromFile(path);
      }

      _scaffoldMessenger.showSnackBar(SnackBar(
          content: Text(
              'Imported TPM rates for ${_model.sourceGenes?.stages?.length ?? 0} stages.')));
      if (status) {
        widget.onShouldClose();
      }
    } catch (error) {
      _scaffoldMessenger.showSnackBar(SnackBar(
        content: Text('Error loading data: $error'),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() => _loadingMessage = null);
    }
  }

  Future<List<Organism>> _fetchOrganisms() async {
    return fetchOrganisms(
            onError: (message) => _scaffoldMessenger.showSnackBar(SnackBar(
                  content: Text(message),
                  backgroundColor: Colors.red,
                )))
        .then((value) => value.sorted((a, b) => a.name.compareTo(b.name)));
  }
}

class _OrganismGroup extends StatelessWidget {
  final List<Organism> organisms;
  final String title;
  final bool showTitle;
  final Function(Organism) onPickOrganism;

  const _OrganismGroup({
    required this.organisms,
    required this.onPickOrganism,
    this.title = '',
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) Text(title, style: textTheme.titleSmall),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: [
            ...organisms.map(
              (organism) => _OrganismCard(
                  organism: organism,
                  onSelected: () => onPickOrganism(organism)),
            )
          ],
        ),
      ],
    );
  }
}

class _OrganismCard extends StatelessWidget {
  final Organism organism;
  final VoidCallback? onSelected;
  const _OrganismCard({required this.organism, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: 240,
      child: Card(
        child: InkWell(
          onTap: onSelected,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                    child: Text(organism.name,
                        style: textTheme.titleSmall!
                            .copyWith(fontStyle: FontStyle.italic))),
                const SizedBox(height: 8),
                FittedBox(
                    child: Wrap(
                  spacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (!organism.public) const Icon(Icons.lock, size: 12),
                    Text(organism.description ?? '',
                        style: textTheme.bodySmall),
                  ],
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
