import 'dart:async';
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:golem_ui/analysis/organism.dart';
import 'package:golem_ui/analysis/organism_presets.dart';
import 'package:golem_ui/genes/gene_list.dart';
import 'package:golem_ui/genes/gene_model.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ...OrganismPresets.kOrganisms.map((organism) => _OrganismCard(
                organism: organism,
                onSelected: organism.filename == null ? null : () => _handleDownloadFasta(organism))),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadedState(BuildContext context) {
    final sourceGenes = context.select<GeneModel, GeneList>((model) => model.sourceGenes!);
    final sampleErrors = sourceGenes.errors.take(100);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                    .map((e) => Text('$e', style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)))
                    .toList(),
                if (sourceGenes.errors.length > sampleErrors.length)
                  Text('and ${sourceGenes.errors.length - sampleErrors.length} other errors.',
                      style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
              ],
            ),
          ),
      ],
    );
  }

  Future<Archive> _downloadAndUnarchive(String filename) async {
    try {
      setState(() => _loadingMessage = 'Downloading $filename…');
      setState(() => _progress = null);
      debugPrint('Preparing download of $filename');
      await Future.delayed(const Duration(milliseconds: 100));

      final bytes =
          await _downloadFile(Uri.https(kIsWeb ? Uri.base.authority : 'golem-dev.ncbr.muni.cz', 'datasets/$filename'));
      debugPrint('Downloaded ${bytes.length ~/ (1024 * 1024)} MB');
      if (mounted) setState(() => _loadingMessage = 'Decompressing ${bytes.length ~/ (1024 * 1024)} MB…');
      if (mounted) setState(() => _progress = 0.7);
      await Future.delayed(const Duration(milliseconds: 100));
      final archive = ZipDecoder().decodeBytes(bytes);
      debugPrint('Decoded $archive');
      return archive;
    } catch (_) {
      rethrow;
    }
  }

  String _fileContent(ArchiveFile file) {
    return const Utf8Decoder().convert(file.content);
  }

  Future<void> _handleDownloadFasta(Organism organism) async {
    try {
      Archive? archive = await _downloadAndUnarchive(organism.filename!);
      final file = archive.firstWhere((f) => f.isFile); //StateError if not found
      final name = file.name.split('/').last;
      if (!name.endsWith('.fasta') && !name.endsWith('.fa')) {
        throw StateError('Expected .fasta file, got $name');
      }
      debugPrint('Found $file');
      final content = _fileContent(file);
      debugPrint('Decoded ${content.length ~/ (1024 * 1024)} MB of data');
      archive = null; // unload from memory
      if (mounted) setState(() => _loadingMessage = 'Analyzing $name (${content.length ~/ (1024 * 1024)} MB)…');
      if (mounted) setState(() => _progress = 0.8);
      await Future.delayed(const Duration(milliseconds: 100));
      await _model.loadFastaFromString(
        data: content,
        organism: organism,
        progressCallback: (value) => setState(() => _progress = 0.8 + value * 0.2),
      );
      debugPrint('Finished loading');
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
