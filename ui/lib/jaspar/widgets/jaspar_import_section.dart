import 'package:flutter/material.dart';

import '../jaspar_api.dart';
import '../jaspar_info_texts.dart';
import '../jaspar_metadata.dart';
import '../motif_logic.dart';
import 'jaspar_metadata_view.dart';
import 'section_card.dart';

enum _ImportStatus { none, success, error }

class JasparImportSection extends StatefulWidget {
  const JasparImportSection({
    super.key,
    required this.onMotifLoaded,
    required this.metadata,
    required this.matrixId,
    required this.isEdited,
  });

  final ValueChanged<JasparMotif> onMotifLoaded;

  /// Metadata of the logo currently shown (null until something was downloaded).
  final JasparMetadata? metadata;

  /// ID of the logo currently shown.
  final String matrixId;

  /// True when the table was changed after the download
  final bool isEdited;

  @override
  State<JasparImportSection> createState() => _JasparImportSectionState();
}

class _JasparImportSectionState extends State<JasparImportSection> {
  final _idController = TextEditingController(text: 'MA0931.1');
  bool _loading = false;
  _ImportStatus _status = _ImportStatus.none;
  String? _errorDetail;

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  Future<void> _downloadFromJaspar() async {
    final id = _idController.text.trim();
    if (id.isEmpty || _loading) return;

    setState(() {
      _loading = true;
      _status = _ImportStatus.none;
      _errorDetail = null;
    });

    try {
      final motif = await fetchJasparMotif(id);
      motif.calculatePpm();
      if (!mounted) return;
      setState(() => _status = _ImportStatus.success);
      widget.onMotifLoaded(motif);
    } on JasparFetchException catch (e) {
      if (!mounted) return;
      setState(() {
        _status = _ImportStatus.error;
        _errorDetail = e.message;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SectionCard(
      title: '1. Import logo',
      infoTitle: infoImportTitle,
      infoText: infoImportText,
      actions: [
        JasparOpenButton(
          metadata: widget.metadata,
          fallbackId: widget.matrixId,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 240,
                child: TextField(
                  controller: _idController,
                  onSubmitted: (_) => _downloadFromJaspar(),
                  decoration: const InputDecoration(
                    labelText: 'JASPAR matrix ID',
                    hintText: 'MA0001.1',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              FilledButton(
                onPressed: _loading ? null : _downloadFromJaspar,
                child: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Download'),
              ),
              if (_status != _ImportStatus.none) _buildStatus(),
            ],
          ),
          if (widget.metadata != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: JasparMetadataView(
                metadata: widget.metadata,
                fallbackId: widget.matrixId,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatus() {
    final ok = _status == _ImportStatus.success;
    final edited = ok && widget.isEdited;
    final color = edited
        ? Colors.orange.shade800
        : ok
            ? Colors.green.shade700
            : Colors.red;

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          edited ? Icons.edit : (ok ? Icons.check_circle : Icons.error),
          size: 18,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(
          edited
              ? "You've changed the matrix"
              : (ok ? 'Success' : 'Error occurred'),
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );

    // Details are available on hover, the visible message stays short.
    if (!ok && _errorDetail != null && _errorDetail!.isNotEmpty) {
      return Tooltip(message: _errorDetail!, child: row);
    }
    return row;
  }
}
