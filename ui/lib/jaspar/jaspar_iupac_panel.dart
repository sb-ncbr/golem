// jaspar_iupac_panel.dart

import 'package:flutter/material.dart';

import 'cavener_settings.dart';
import 'motif_logic.dart';
import 'widgets/cavener_settings_panel.dart';
import 'widgets/consensus_output.dart';
import 'widgets/jaspar_import_section.dart';
import 'widgets/pfm_table_editor.dart';

class JasparIupacPanel extends StatefulWidget {
  final ValueChanged<String> onConfirm;
  final VoidCallback onCancel;

  const JasparIupacPanel({
    super.key,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<JasparIupacPanel> createState() => _JasparIupacPanelState();
}

class _JasparIupacPanelState extends State<JasparIupacPanel> {
  JasparMotif _motif = JasparMotif(
    id: 'MA0004.1',
    name: 'Arnt',
    pfm: [
      [4, 19, 0, 0, 0, 0],
      [16, 1, 20, 0, 0, 0],
      [0, 0, 0, 20, 0, 20],
      [0, 0, 0, 0, 20, 0],
    ],
  );

  final ValueNotifier<CavenerSettings> _settingsNotifier =
      ValueNotifier(const CavenerSettings());

  int _tableVersion = 0;

  @override
  void dispose() {
    _settingsNotifier.dispose();
    super.dispose();
  }

  List<String> _computeConsensusFor(CavenerSettings settings) {
    return computeConsensus(
      _motif,
      t1: settings.t1,
      t2: settings.t2,
      useInfoContentCutoff: settings.icEnabled,
      icThreshold: settings.icThreshold,
    );
  }

  String _getResultDefinition(CavenerSettings settings) {
    final letters = _computeConsensusFor(settings);
    if (letters.isEmpty) return '';
    final bounds = trimCoreByLetters(letters);
    return letters.sublist(bounds.left, bounds.right + 1).join();
  }

  void _onMotifLoaded(JasparMotif motif) => setState(() {
        _motif = motif;
        _tableVersion++;
      });

  void _onCellChanged(int row, int col, String text) {
    final value = int.tryParse(text) ?? 0;
    setState(() {
      _motif.pfm[row][col] = value < 0 ? 0 : value;
      _motif.calculatePpm();
    });
  }

  void _onAddPosition() => setState(() {
        _motif.addPosition();
        // removed: _tableVersion++;
      });

  void _onReverseComplement() => setState(() {
        _motif = _motif.reverseComplement();
        _tableVersion++;
      });

  void _onRemoveColumn(int col) {
    if (_motif.pfm.isEmpty || _motif.pfm[0].length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A motif needs at least 1 position.')),
      );
      return;
    }
    setState(() {
      for (var r = 0; r < 4; r++) {
        _motif.pfm[r].removeAt(col);
      }
      _motif.calculatePpm();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'JASPAR Import',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LEVÝ SLOUPEC: 3/5 šířky strány (60 %)
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child:
                            JasparImportSection(onMotifLoaded: _onMotifLoaded),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: PfmTableEditor(
                          key: ValueKey(_tableVersion),
                          pfm: _motif.pfm,
                          motif: _motif,
                          onCellChanged: _onCellChanged,
                          onAddPosition: _onAddPosition,
                          onRemoveColumn: _onRemoveColumn,
                          onReverseComplement: _onReverseComplement,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // PRAVÝ SLOUPEC: 2/5 šířky stránky (40 %)
                Expanded(
                  flex: 2,
                  child: ValueListenableBuilder<CavenerSettings>(
                    valueListenable: _settingsNotifier,
                    builder: (context, settings, _) {
                      final consensus = _computeConsensusFor(settings);
                      final definition = _getResultDefinition(settings);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CavenerSettingsPanel(
                            settings: settings,
                            onChanged: (s) => _settingsNotifier.value = s,
                          ),
                          const SizedBox(height: 12),
                          ConsensusOutput(
                            letters: consensus,
                            trim: settings.trim,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                ),
                                onPressed: widget.onCancel,
                                child: const Text('Cancel',
                                    style: TextStyle(fontSize: 14)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                    foregroundColor:
                                        Theme.of(context).colorScheme.onPrimary,
                                  ),
                                  onPressed: definition.isEmpty
                                      ? null
                                      : () => widget.onConfirm(definition),
                                  icon: const Icon(Icons.check, size: 18),
                                  label: Text(
                                    'Use "$definition"',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
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
}
