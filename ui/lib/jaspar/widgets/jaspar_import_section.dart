// jaspar_import_section.dart
//
// Owns the JASPAR-ID text controller and the loading/status flags.
// Only reports outward through one callback: "here's a motif, do
// something with it." The PFM table below this (in the parent screen)
// is always visible and directly editable, so there's no separate
// "paste raw text" mode any more -- if you have a matrix in some other
// format, you'd retype it into the table anyway, so that second path
// was redundant with the table itself. (`parseManualMatrix` in
// motif_logic.dart still exists and is still fully tested/usable -- it
// just isn't wired to any UI control right now.)

import 'package:flutter/material.dart';

import '../jaspar_api.dart';
import '../motif_logic.dart';

class JasparImportSection extends StatefulWidget {
  const JasparImportSection({super.key, required this.onMotifLoaded});

  final ValueChanged<JasparMotif> onMotifLoaded;

  @override
  State<JasparImportSection> createState() => _JasparImportSectionState();
}

class _JasparImportSectionState extends State<JasparImportSection> {
  final _idController = TextEditingController(text: 'MA0004.1');
  bool _loading = false;
  String? _statusMessage;
  bool _statusIsError = false;

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  Future<void> _downloadFromJaspar() async {
    final id = _idController.text.trim();
    if (id.isEmpty) return;

    setState(() {
      _loading = true;
      _statusIsError = false;
      _statusMessage = 'Fetching $id from JASPAR…';
    });

    try {
      final motif = await fetchJasparMotif(id);
      motif.calculatePpm();
      if (!mounted) return;
      setState(() {
        _statusIsError = false;
        _statusMessage = '✔ Loaded: ${motif.name} (${motif.id})';
      });
      widget.onMotifLoaded(motif);
    } on JasparFetchException catch (e) {
      if (!mounted) return;
      setState(() {
        _statusIsError = true;
        _statusMessage = '✘ Fetch failed: $e';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. Import matrix', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _idController,
                    decoration: const InputDecoration(
                      labelText: 'JASPAR ID',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
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
              ],
            ),
            if (_statusMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _statusMessage!,
                style: TextStyle(
                  color: _statusIsError ? Colors.red : Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              'Or edit the PFM table below directly.',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}
