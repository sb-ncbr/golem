// widgets/pfm_table_editor.dart

import 'package:flutter/material.dart';

import '../motif_logic.dart';
import '../nucleotide_colors.dart';
import 'sequence_logo.dart';

class PfmTableEditor extends StatefulWidget {
  const PfmTableEditor({
    super.key,
    required this.pfm,
    required this.motif,
    required this.onCellChanged,
    required this.onAddPosition,
    required this.onRemoveColumn,
    required this.onReverseComplement,
  });

  final Pfm pfm;
  final JasparMotif motif;
  final void Function(int row, int col, String text) onCellChanged;
  final VoidCallback onAddPosition;
  final ValueChanged<int> onRemoveColumn;
  final VoidCallback onReverseComplement;

  @override
  State<PfmTableEditor> createState() => _PfmTableEditorState();
}

class _PfmTableEditorState extends State<PfmTableEditor> {
  late List<List<TextEditingController>> _controllers;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controllers = _buildControllers(widget.pfm);
  }

  @override
  void didUpdateWidget(PfmTableEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncControllers();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _disposeControllers();
    super.dispose();
  }

  List<List<TextEditingController>> _buildControllers(Pfm pfm) {
    final length = pfm.isEmpty ? 0 : pfm[0].length;
    return [
      for (var r = 0; r < 4; r++)
        [
          for (var c = 0; c < length; c++)
            TextEditingController(text: pfm[r][c].toString()),
        ],
    ];
  }

  void _syncControllers() {
    final targetLength = widget.pfm.isEmpty ? 0 : widget.pfm[0].length;
    final currentLength = _controllers.isEmpty ? 0 : _controllers[0].length;

    if (targetLength > currentLength) {
      for (var r = 0; r < 4; r++) {
        for (var c = currentLength; c < targetLength; c++) {
          _controllers[r]
              .add(TextEditingController(text: widget.pfm[r][c].toString()));
        }
      }
    } else if (targetLength < currentLength) {
      for (var r = 0; r < 4; r++) {
        while (_controllers[r].length > targetLength) {
          _controllers[r].removeLast().dispose();
        }
      }
    }

    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < targetLength; c++) {
        final fieldVal = int.tryParse(_controllers[r][c].text) ?? 0;
        final matrixVal = widget.pfm[r][c];

        if (fieldVal != matrixVal) {
          _controllers[r][c].text = matrixVal.toString();
        }
      }
    }
  }

  void _disposeControllers() {
    for (final row in _controllers) {
      for (final c in row) {
        c.dispose();
      }
    }
  }

  void _stepCellValue(int r, int c, int delta) {
    final currentVal = int.tryParse(_controllers[r][c].text) ?? 0;
    final newVal = (currentVal + delta) < 0 ? 0 : (currentVal + delta);
    final textVal = newVal.toString();

    _controllers[r][c].text = textVal;
    widget.onCellChanged(r, c, textVal);
  }

  @override
  Widget build(BuildContext context) {
    final length = widget.pfm.isEmpty ? 0 : widget.pfm[0].length;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('PFM Matrix & Sequence Logo',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),

            // Scrollbar obaluje celý obsah (Sequence Logo + PFM Matice)
            Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              trackVisibility: true,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sequence Logo bez dodatečného posunutí
                      RepaintBoundary(
                        child: SequenceLogo(motif: widget.motif),
                      ),
                      const SizedBox(height: 16),

                      // Tabulka PFM matice
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              const SizedBox(height: 28),
                              for (var r = 0; r < 4; r++)
                                Container(
                                  height: 40,
                                  width: 32,
                                  alignment: Alignment.center,
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  child: Text(
                                    bases[r],
                                    style: TextStyle(
                                      color: baseColor(bases[r]),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          for (var c = 0; c < length; c++)
                            Container(
                              width: 72,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              child: Column(
                                children: [
                                  Container(
                                    height: 22,
                                    margin: const EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '${c + 1}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(width: 3),
                                        InkWell(
                                          onTap: () => widget.onRemoveColumn(c),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Padding(
                                            padding: const EdgeInsets.all(2),
                                            child: Icon(
                                              Icons.close,
                                              size: 14,
                                              color: Colors.red.shade400,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  for (var r = 0; r < 4; r++)
                                    Container(
                                      height: 40,
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 2),
                                      child: _FastPfmCell(
                                        controller: _controllers[r][c],
                                        onChanged: (text) =>
                                            widget.onCellChanged(r, c, text),
                                        onIncrement: () =>
                                            _stepCellValue(r, c, 1),
                                        onDecrement: () =>
                                            _stepCellValue(r, c, -1),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: widget.onAddPosition,
                  child: const Text('+ Add position'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: widget.onReverseComplement,
                  icon: const Icon(Icons.sync_alt, size: 18),
                  label: const Text('Reverse complement'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FastPfmCell extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _FastPfmCell({
    required this.controller,
    required this.onChanged,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
                border: InputBorder.none,
              ),
              onChanged: onChanged,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: onIncrement,
                child: const Icon(Icons.arrow_drop_up, size: 16),
              ),
              InkWell(
                onTap: onDecrement,
                child: const Icon(Icons.arrow_drop_down, size: 16),
              ),
            ],
          ),
          const SizedBox(width: 2),
        ],
      ),
    );
  }
}
