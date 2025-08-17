import 'dart:async';
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geneweb/analysis/organism.dart';
import 'package:geneweb/analysis/organism_presets.dart';
import 'package:geneweb/api/api_service.dart';
import 'package:geneweb/api/organism.dart';
import 'package:geneweb/genes/gene_list.dart';
import 'package:geneweb/genes/gene_model.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

/// Widget shown just below the panel headline
class SourceSubtitle extends StatelessWidget {
  const SourceSubtitle({super.key});

  @override
  Widget build(BuildContext context) {
    final sourceGenes = context.select<GeneModel, GeneList?>((model) => model.sourceGenes);
    final name = context.select<GeneModel, String?>((model) => model.name);
    return sourceGenes == null
        ? const Text(
            'Motif positions are mapped relative to the transcription start sites (TSS) or translation start site (ATG)')
        : Wrap(
            children: [
              Text('$name', style: const TextStyle(fontStyle: FontStyle.italic)),
              Text(', ${sourceGenes.genes.length} genes, ${sourceGenes.stageKeys.length} stages'),
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
  late Future<List<NewOrganism>> futureOrganisms;

  @override
  Widget build(BuildContext context) {
    final sourceGenes = context.select<GeneModel, GeneList?>((model) => model.sourceGenes);
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
    context.read<GeneModel>().addListener(_onUserChanged);
  }

  @override
  void dispose() {
    context.read<GeneModel>().removeListener(_onUserChanged);
    super.dispose();
  }

  void _onUserChanged() {
    final geneModel = context.read<GeneModel>();
    if (!geneModel.isSignedIn) {
      setState(() {
        futureOrganisms = _fetchOrganisms();
      });
    }
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
    final publicSite = context.select<GeneModel, bool>((model) => model.publicSite);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FutureBuilder(
                future: futureOrganisms,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          ...snapshot.data!
                              .map(((organism) => Organism(
                                  name: organism.name,
                                  description: organism.description,
                                  filename: organism.sequencesFilename,
                                  public: organism.public)))
                              .map(
                                (organism) => _OrganismCard(
                                    organism: organism,
                                    onSelected: organism.filename == null
                                        ? null
                                        : () => _handleDownloadFasta(organism)),
                              )
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

  Widget _buildLoadedState(BuildContext context) {
    final publicSite = context.select<GeneModel, bool>((model) => model.publicSite);
    final sourceGenes = context.select<GeneModel, GeneList>((model) => model.sourceGenes!);
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
              TextButton(onPressed: _handlePickTPMFile, child: const Text('Add custom TPM (.csv)…')), //TODO
              TextButton(onPressed: _handlePickStagesFile, child: const Text('Add custom Stages (.csv)…')),
            ],
          ),
        const SizedBox(height: 16),
        TextButton(onPressed: _handleClear, child: const Text('Choose another species…')),
        if (sourceGenes.errors.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 16.0),
            color: Theme.of(context).colorScheme.errorContainer,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...sampleErrors
                    .map((e) => Text('$e', style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer))),
                if (sourceGenes.errors.length > sampleErrors.length)
                  Text('and ${sourceGenes.errors.length - sampleErrors.length} other errors.',
                      style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _handlePickFastaFile() async {
    try {
      setState(() => _loadingMessage = 'Picking file…');
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result == null) {
        return;
      }
      final filename = result.files.single.name;
      setState(() => _loadingMessage = 'Loading $filename…');
      await Future.delayed(const Duration(milliseconds: 100));
      final organism = OrganismPresets.organismByFileName(filename);
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
        _scaffoldMessenger.showSnackBar(SnackBar(content: Text('Imported ${_model.sourceGenes?.genes.length} genes.')));
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

      _scaffoldMessenger
          .showSnackBar(SnackBar(content: Text('Imported ${_model.sourceGenes?.stages?.length ?? 0} stages.')));
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

  Future<List<int>> _downloadAndUnarchive(Organism organism) async {
    try {
      setState(() => _loadingMessage = 'Downloading ${organism.filename}…');
      setState(() => _progress = null);
      debugPrint('Preparing download of ${organism.filename}');
      await Future.delayed(const Duration(milliseconds: 100));

      final response =
          await ApiService.instance.download('/organisms/${organism.filename}');

      if (!response.success) {
        _scaffoldMessenger.showSnackBar(SnackBar(
          content: Text(response.message),
          backgroundColor: Colors.red,
        ));
        throw Exception(response.message);
      }

      Uint8List bytes = response.data;

      debugPrint('Downloaded ${bytes.length ~/ (1024 * 1024)} MB');
      if (mounted) setState(() => _loadingMessage = 'Decompressing ${bytes.length ~/ (1024 * 1024)} MB…');
      if (mounted) setState(() => _progress = 0.7);
      await Future.delayed(const Duration(milliseconds: 100));
      final decompressedXz = XZDecoder().decodeBytes(bytes);
      debugPrint('Decompressed $decompressedXz');
      return decompressedXz;
    } catch (_) {
      rethrow;
    }
  }

  String _fileContent(ArchiveFile file) {
    return const Utf8Decoder().convert(file.content);
  }

  Future<void> _handleDownloadFasta(Organism organism) async {
    try {
      final content = await _downloadAndUnarchive(organism);
      debugPrint('Decoded ${content.length ~/ (1024 * 1024)} MB of data');
      final filename = organism.filename?.replaceAll('.xz', '');
      if (mounted) setState(() => _loadingMessage = 'Analyzing $filename (${content.length ~/ (1024 * 1024)} MB)…');
      if (mounted) setState(() => _progress = 0.8);
      await Future.delayed(const Duration(milliseconds: 100));
      await _model.loadFastaFromString(
        data: const Utf8Decoder().convert(content),
        organism: organism,
        progressCallback: (value) => setState(() => _progress = 0.8 + value * 0.2),
      );
      debugPrint('Finished loading');

      if (!mounted) return;

      if (_model.sourceGenes!.errors.isEmpty) {
        _scaffoldMessenger.showSnackBar(SnackBar(content: Text('Imported ${_model.sourceGenes?.genes.length} genes.')));
      } else {
        _scaffoldMessenger.showSnackBar(SnackBar(
            backgroundColor: Colors.red,
            content: Text(
                'Imported ${_model.sourceGenes?.genes.length} genes, ${_model.sourceGenes?.errors.length} errors.')));
      }
      widget.onShouldClose();
    } catch (error) {
      _scaffoldMessenger.showSnackBar(SnackBar(
        content: Text('Error loading data: $error'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _loadingMessage = null);
      if (mounted) setState(() => _progress = null);
    }
  }

  Future<List<int>> _downloadFile(Uri uri) async {
    debugPrint('Starting download $uri');
    final request = http.Request('GET', uri);
    debugPrint('Sending request');
    final http.StreamedResponse response = await http.Client().send(request);
    debugPrint('Got $response');
    final contentLength = response.contentLength;
    debugPrint('Will download ${(contentLength ?? 0) ~/ (1024 * 1024)} MB');
    int downloadedBytes = 0;
    List<int> bytes = [];
    await response.stream.listen(
      (List<int> newBytes) {
        bytes.addAll(newBytes);
        downloadedBytes += newBytes.length;
        if (mounted) setState(() => _progress = contentLength == null ? null : (downloadedBytes / contentLength * 0.7));
      },
      onDone: () async {
        debugPrint('Stream done');
      },
      onError: (e) {
        throw StateError('Error downloading file: $e');
      },
      cancelOnError: true,
    ).asFuture();
    return bytes;
  }

  void _handleClear() {
    _model.reset();
    _scaffoldMessenger
        .showSnackBar(const SnackBar(content: Text('Cleared all data. Please pick a new organism to analyze.')));
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

      _scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Imported TPM rates for ${_model.sourceGenes?.stages?.length ?? 0} stages.')));
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

  Future<List<NewOrganism>> _fetchOrganisms() async {
    return fetchOrganisms(
            onError: (message) => _scaffoldMessenger.showSnackBar(SnackBar(
                  content: Text(message),
                  backgroundColor: Colors.red,
                )))
        // TODO: add proper ordering
        .then((value) => value.sorted((a, b) => a.name.compareTo(b.name)));
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
                    child: Text(organism.name, style: textTheme.titleSmall!.copyWith(fontStyle: FontStyle.italic))),
                const SizedBox(height: 8),
                FittedBox(
                    child: Wrap(
                  spacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (!organism.public) const Icon(Icons.lock, size: 12),
                    Text(organism.description ?? '', style: textTheme.bodySmall),
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
