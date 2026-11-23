import 'package:flutter/material.dart';

import 'cavener_settings.dart';
import 'golem_colors.dart';
import 'jaspar_info_texts.dart';
import 'motif_logic.dart';
import 'widgets/cavener_settings_panel.dart';
import 'widgets/consensus_output.dart';
import 'widgets/final_logo_section.dart';
import 'widgets/jaspar_import_section.dart';
import 'widgets/pfm_table_editor.dart';
import 'widgets/section_card.dart';

/// What the dialog returns when the user presses "Use".
class JasparResult {
  const JasparResult({
    required this.definition,
    required this.name,
    required this.matrixId,
  });

  /// Trimmed IUPAC motif, e.g. "BGMCACGTG".
  final String definition;

  /// Name of the logo (e.g. "ABI5"), handy for pre-filling the motif name.
  final String name;
  final String matrixId;
}

/// Opens the JASPAR import pop-up. Returns null when it was closed with the
/// cross in the upper right corner.
Future<JasparResult?> showJasparIupacDialog(BuildContext context) {
  return showDialog<JasparResult>(
    context: context,
    // Closing is done with the cross, so a stray click doesn't throw away work.
    barrierDismissible: false,
    builder: (_) => const JasparIupacDialog(),
  );
}

class JasparIupacDialog extends StatefulWidget {
  const JasparIupacDialog({super.key});

  @override
  State<JasparIupacDialog> createState() => _JasparIupacDialogState();
}

class _JasparIupacDialogState extends State<JasparIupacDialog> {
  JasparMotif _motif = JasparMotif(
    id: 'MA0931.1',
    name: 'ABI5',
    pfm: [
      [181, 87, 608, 0, 999, 0, 0, 0, 152, 164],
      [257, 87, 314, 922, 0, 999, 0, 0, 70, 164],
      [257, 660, 0, 78, 0, 0, 999, 0, 709, 337],
      [306, 167, 78, 0, 0, 0, 0, 999, 70, 336],
    ],
  );

  final ValueNotifier<CavenerSettings> _settingsNotifier =
      ValueNotifier(const CavenerSettings());

  // Bumped only when a *new* motif is loaded, so the table is rebuilt from
  // scratch. Undo/redo/reverse-complement keep the table (and its focus).
  int _tableVersion = 0;

  // Copy of the matrix exactly as it came from JASPAR (null = nothing downloaded yet).
  JasparMotif? _downloaded;

  /// True when the table no longer matches the downloaded matrix.
  bool get _isEdited {
    final original = _downloaded;
    if (original == null) return false;
    if (original.length != _motif.length) return true;
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < _motif.length; c++) {
        if (_motif.pfm[r][c] != original.pfm[r][c]) return true;
      }
    }
    return false;
  }

  // ---------------------------------------------------------------- history
  //
  // Snapshot-based undo/redo: before every change we push a deep copy of the
  // motif onto [_undoStack]. Undo moves the current state to [_redoStack] and
  // restores the last snapshot; a new edit clears [_redoStack].
  // Rapid edits of the same cell (typing digits, holding an arrow key) are
  // merged into ONE history entry, otherwise one key hold = 50 undo steps.
  static const int _maxHistory = 100;
  static const Duration _coalesceWindow = Duration(milliseconds: 800);

  final List<JasparMotif> _undoStack = [];
  final List<JasparMotif> _redoStack = [];
  String? _lastCoalesceKey;
  DateTime _lastEditTime = DateTime.fromMillisecondsSinceEpoch(0);

  void _recordHistory({String? coalesceKey}) {
    final now = DateTime.now();
    final merge = coalesceKey != null &&
        coalesceKey == _lastCoalesceKey &&
        now.difference(_lastEditTime) < _coalesceWindow;
    _lastCoalesceKey = coalesceKey;
    _lastEditTime = now;
    if (merge) return;

    _undoStack.add(_motif.copy());
    if (_undoStack.length > _maxHistory) _undoStack.removeAt(0);
    _redoStack.clear();
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    setState(() {
      _redoStack.add(_motif.copy());
      _motif = _undoStack.removeLast();
      _lastCoalesceKey = null;
    });
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    setState(() {
      _undoStack.add(_motif.copy());
      _motif = _redoStack.removeLast();
      _lastCoalesceKey = null;
    });
  }

  // ------------------------------------------------------------- consensus

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
    if (!settings.trim) return letters.join();
    final bounds = trimCoreByLetters(letters);
    return letters.sublist(bounds.left, bounds.right + 1).join();
  }

  // ------------------------------------------------------------- edit hooks

  void _onMotifLoaded(JasparMotif motif) {
    _recordHistory();
    setState(() {
      _motif = motif;
      _downloaded = motif.copy();
      _tableVersion++;
    });
  }

  void _onCellChanged(int row, int col, String text) {
    final value = int.tryParse(text) ?? 0;
    final newValue = value < 0 ? 0 : value;
    if (_motif.pfm[row][col] == newValue) return;

    _recordHistory(coalesceKey: 'cell:$row:$col');
    setState(() {
      _motif.pfm[row][col] = newValue;
      _motif.calculatePpm();
    });
  }

  void _onAddPosition() {
    _recordHistory();
    setState(() => _motif.addPosition());
  }

  void _onReverseComplement() {
    _recordHistory();
    setState(() => _motif = _motif.reverseComplement());
  }

  void _onRemoveColumn(int col) {
    // The table hides the cross when only one position is left.
    if (_motif.pfm.isEmpty || _motif.pfm[0].length <= 1) return;
    _recordHistory();
    setState(() {
      for (var r = 0; r < 4; r++) {
        _motif.pfm[r].removeAt(col);
      }
      _motif.calculatePpm();
    });
  }

  void _use(String definition) {
    Navigator.of(context).pop(
      JasparResult(
        definition: definition,
        name: _motif.name.isNotEmpty ? _motif.name : _motif.id,
        matrixId: _motif.id,
      ),
    );
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height - 48;

    return Dialog(
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.all(24),
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 1280, maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TitleBar(onClose: () => Navigator.of(context).pop()),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    const gap = SizedBox(height: 16);

    return LayoutBuilder(
      builder: (context, constraints) {
        final importSection = JasparImportSection(
          onMotifLoaded: _onMotifLoaded,
          metadata: _motif.metadata,
          matrixId: _motif.id,
          isEdited: _isEdited,
        );
        final logoSection = _buildSequenceLogoSection();

        if (constraints.maxWidth < 1000) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              importSection,
              gap,
              logoSection,
              gap,
              _buildRightColumn(fillHeight: false),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [importSection, gap, logoSection],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: _buildRightColumn(fillHeight: false)),
          ],
        );
      },
    );
  }

  // 2. Sequence Logo
  Widget _buildSequenceLogoSection() {
    return SectionCard(
      title: '2. Sequence Logo',
      infoTitle: infoSequenceLogoTitle,
      infoText: infoSequenceLogoText,
      actions: [
        IconButton(
          tooltip: 'Undo',
          icon: const Icon(Icons.undo),
          onPressed: _undoStack.isEmpty ? null : _undo,
        ),
        IconButton(
          tooltip: 'Redo',
          icon: const Icon(Icons.redo),
          onPressed: _redoStack.isEmpty ? null : _redo,
        ),
      ],
      child: PfmTableEditor(
        key: ValueKey(_tableVersion),
        pfm: _motif.pfm,
        motif: _motif,
        onCellChanged: _onCellChanged,
        onAddPosition: _onAddPosition,
        onRemoveColumn: _onRemoveColumn,
        onReverseComplement: _onReverseComplement,
      ),
    );
  }

  // 3. Adjust consensus generation method  +  4. Final logo
  Widget _buildRightColumn({required bool fillHeight}) {
    return ValueListenableBuilder<CavenerSettings>(
      valueListenable: _settingsNotifier,
      builder: (context, settings, _) {
        final consensus = _computeConsensusFor(settings);
        final definition = _getResultDefinition(settings);

        final finalLogo = FinalLogoSection(
          definition: definition,
          fillHeight: fillHeight,
          onUse: definition.isEmpty ? null : () => _use(definition),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionCard(
              title: '3. Adjust consensus generation method',
              infoTitle: infoConsensusTitle,
              infoText: infoConsensusText,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CavenerSettingsPanel(
                    settings: settings,
                    onChanged: (s) => _settingsNotifier.value = s,
                  ),
                  const SizedBox(height: 16),
                  ConsensusOutput(letters: consensus, trim: settings.trim),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (fillHeight) Expanded(child: finalLogo) else finalLogo,
          ],
        );
      },
    );
  }
}

/// Title bar in the GOLEM header green, with the "i" (what is this dialog)
/// next to the title and the cross (cancel) in the upper right corner.
class _TitleBar extends StatelessWidget {
  const _TitleBar({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 8, 8),
      decoration: const BoxDecoration(
        color: golemGreen,
        border: Border(bottom: BorderSide(color: golemGreenBorder)),
      ),
      child: Row(
        children: [
          Text(
            'JASPAR Import',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: golemInk,
            ),
          ),
          const InfoButton(
            title: infoDialogTitle,
            text: infoDialogText,
            color: golemInk,
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close, color: golemInk),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
