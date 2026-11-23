import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../motif_logic.dart';
import '../nucleotide_colors.dart';
import 'sequence_logo.dart';

/// Sequence logo + editable PFM table.
///
/// Keyboard (while a cell is focused):
///  * ↑ / ↓        change the value by 1 (Shift: 10); holding the key repeats
///  * ← / →        jump to the neighbouring position
///
/// There are no undo/redo shortcuts, because tinkering for every browser
/// is a bit mental. Undo/redo are the buttons in the SectionCard header.
/// The title, "i" button and those buttons live in the surrounding
/// SectionCard; this widget only reports user intent upwards.
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
  late List<List<FocusNode>> _focusNodes;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controllers = _buildControllers(widget.pfm);
    _focusNodes =
        _buildFocusNodes(widget.pfm.isEmpty ? 0 : widget.pfm[0].length);
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
    for (final row in _focusNodes) {
      for (final n in row) {
        n.dispose();
      }
    }
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

  FocusNode _newNode(int r, int c) => FocusNode(
        debugLabel: 'pfm cell $r,$c',
        onKeyEvent: (_, event) => _onCellKey(r, c, event),
      );

  List<List<FocusNode>> _buildFocusNodes(int length) => [
        for (var r = 0; r < 4; r++)
          [for (var c = 0; c < length; c++) _newNode(r, c)],
      ];

  void _syncControllers() {
    final targetLength = widget.pfm.isEmpty ? 0 : widget.pfm[0].length;
    final currentLength = _controllers.isEmpty ? 0 : _controllers[0].length;

    if (targetLength > currentLength) {
      for (var r = 0; r < 4; r++) {
        for (var c = currentLength; c < targetLength; c++) {
          _controllers[r]
              .add(TextEditingController(text: widget.pfm[r][c].toString()));
          _focusNodes[r].add(_newNode(r, c));
        }
      }
    } else if (targetLength < currentLength) {
      for (var r = 0; r < 4; r++) {
        while (_controllers[r].length > targetLength) {
          _controllers[r].removeLast().dispose();
          _focusNodes[r].removeLast().dispose();
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

  // ---------------------------------------------------------------- keyboard

  KeyEventResult _onCellKey(int r, int c, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;
    final keyboard = HardwareKeyboard.instance;

    // Leave every Ctrl/Cmd combination to the text field / browser.
    // DO NOT EVEN TRY ANYTHING!!! (yeah, broke some things...)
    if (keyboard.isControlPressed || keyboard.isMetaPressed) {
      return KeyEventResult.ignored;
    }
    if (keyboard.isAltPressed) return KeyEventResult.ignored;

    // KeyDownEvent = single press, KeyRepeatEvent = key held down.
    if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown) {
      final step = keyboard.isShiftPressed ? 10 : 1;
      _stepCellValue(r, c, key == LogicalKeyboardKey.arrowUp ? step : -step);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      _focusCell(r, c - 1, forward: false);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      _focusCell(r, c + 1, forward: true);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _focusCell(int r, int c, {required bool forward}) {
    if (c < 0 || c >= _focusNodes[r].length) return;
    final node = _focusNodes[r][c];
    final controller = _controllers[r][c];

    node.requestFocus();
    controller.selection =
        TextSelection(baseOffset: 0, extentOffset: controller.text.length);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = node.context;
      if (ctx == null || !ctx.mounted) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 120),
        alignmentPolicy: forward
            ? ScrollPositionAlignmentPolicy.keepVisibleAtEnd
            : ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      );
    });
  }

  void _stepCellValue(int r, int c, int delta) {
    final controller = _controllers[r][c];
    final currentVal = int.tryParse(controller.text) ?? 0;
    final newVal = math.max(0, currentVal + delta);
    final textVal = newVal.toString();
    if (controller.text == textVal) return;

    controller.value = TextEditingValue(
      text: textVal,
      selection: TextSelection(baseOffset: 0, extentOffset: textVal.length),
    );
    widget.onCellChanged(r, c, textVal);
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final length = widget.pfm.isEmpty ? 0 : widget.pfm[0].length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Scrollbar wraps the whole thingy (Sequence Logo + PFM Matrix)
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
                  // Sequence Logo
                  RepaintBoundary(
                    child: SequenceLogo(motif: widget.motif),
                  ),
                  const SizedBox(height: 16),

                  // Table of PFM matrix
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
                              margin: const EdgeInsets.symmetric(vertical: 2),
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
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${c + 1}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    // A motif needs at least one position.
                                    if (length > 1) ...[
                                      const SizedBox(width: 3),
                                      InkWell(
                                        onTap: () => widget.onRemoveColumn(c),
                                        borderRadius: BorderRadius.circular(8),
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
                                  ],
                                ),
                              ),
                              for (var r = 0; r < 4; r++)
                                Container(
                                  height: 40,
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  child: _FastPfmCell(
                                    controller: _controllers[r][c],
                                    focusNode: _focusNodes[r][c],
                                    onChanged: (text) =>
                                        widget.onCellChanged(r, c, text),
                                    onStep: (delta) =>
                                        _stepCellValue(r, c, delta),
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
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton(
              onPressed: widget.onAddPosition,
              child: const Text('+ Add position'),
            ),
            OutlinedButton.icon(
              onPressed: widget.onReverseComplement,
              icon: const Icon(Icons.sync_alt, size: 18),
              label: const Text('Reverse complement'),
            ),
          ],
        ),
      ],
    );
  }
}

class _FastPfmCell extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<int> onStep;

  const _FastPfmCell({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onStep,
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
              focusNode: focusNode,
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
              _HoldRepeatIcon(
                icon: Icons.arrow_drop_up,
                onPressStart: focusNode.requestFocus,
                onStep: () => onStep(1),
              ),
              _HoldRepeatIcon(
                icon: Icons.arrow_drop_down,
                onPressStart: focusNode.requestFocus,
                onStep: () => onStep(-1),
              ),
            ],
          ),
          const SizedBox(width: 2),
        ],
      ),
    );
  }
}

/// On-screen spinner arrow: one step per click, keeps stepping while the
/// mouse/finger is held down (same behaviour as holding the keyboard arrow).
class _HoldRepeatIcon extends StatefulWidget {
  const _HoldRepeatIcon({
    required this.icon,
    required this.onStep,
    required this.onPressStart,
  });

  final IconData icon;
  final VoidCallback onStep;
  final VoidCallback onPressStart;

  @override
  State<_HoldRepeatIcon> createState() => _HoldRepeatIconState();
}

class _HoldRepeatIconState extends State<_HoldRepeatIcon> {
  Timer? _delay;
  Timer? _repeat;

  void _start() {
    widget.onPressStart();
    widget.onStep();
    _delay = Timer(const Duration(milliseconds: 400), () {
      _repeat = Timer.periodic(
        const Duration(milliseconds: 60),
        (_) => widget.onStep(),
      );
    });
  }

  void _stop() {
    _delay?.cancel();
    _repeat?.cancel();
    _delay = null;
    _repeat = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _start(),
      onTapUp: (_) => _stop(),
      onTapCancel: _stop,
      child: Icon(widget.icon, size: 16),
    );
  }
}
