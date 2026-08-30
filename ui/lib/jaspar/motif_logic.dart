// motif_logic.dart

import 'dart:convert';
import 'dart:math' as math;

typedef Pfm = List<List<int>>;
typedef Ppm = List<List<double>>;

const List<String> bases = ['A', 'C', 'G', 'T'];

const Map<String, String> _iupacTable = {
  'A': 'A',
  'C': 'C',
  'G': 'G',
  'T': 'T',
  'AG': 'R',
  'CT': 'Y',
  'CG': 'S',
  'AT': 'W',
  'GT': 'K',
  'AC': 'M',
  'CGT': 'B',
  'AGT': 'D',
  'ACT': 'H',
  'ACG': 'V',
  'ACGT': 'N',
};

class JasparMotif {
  JasparMotif({required this.id, required this.name, required this.pfm}) {
    _validateShape();
    calculatePpm();
  }

  String id;
  String name;
  Pfm pfm;
  Ppm ppm = [[], [], [], []];

  int get length => pfm.isEmpty ? 0 : pfm[0].length;

  void _validateShape() {
    if (pfm.length != 4) {
      throw ArgumentError(
          'A PFM must have exactly 4 rows (A, C, G, T), got ${pfm.length}.');
    }
    final expected = pfm[0].length;
    for (var row = 0; row < 4; row++) {
      if (pfm[row].length != expected) {
        throw ArgumentError(
          'PFM rows must all be the same length; row $row has '
          '${pfm[row].length} values, expected $expected.',
        );
      }
    }
  }

  void calculatePpm() {
    ppm = [[], [], [], []];
    for (var col = 0; col < length; col++) {
      final n = pfm[0][col] + pfm[1][col] + pfm[2][col] + pfm[3][col];
      for (var row = 0; row < 4; row++) {
        ppm[row].add(n > 0 ? pfm[row][col] / n : 0.0);
      }
    }
  }

  void addPosition() {
    for (final row in pfm) {
      row.add(0);
    }
    calculatePpm();
  }

  bool removePosition() {
    if (length <= 1) return false;
    for (final row in pfm) {
      row.removeLast();
    }
    calculatePpm();
    return true;
  }

  JasparMotif reverseComplement() {
    final newPfm = [
      List<int>.filled(length, 0),
      List<int>.filled(length, 0),
      List<int>.filled(length, 0),
      List<int>.filled(length, 0),
    ];
    for (var col = 0; col < length; col++) {
      final targetCol = length - 1 - col;
      newPfm[0][targetCol] = pfm[3][col]; // A <- T
      newPfm[1][targetCol] = pfm[2][col]; // C <- G
      newPfm[2][targetCol] = pfm[1][col]; // G <- C
      newPfm[3][targetCol] = pfm[0][col]; // T <- A
    }
    return JasparMotif(id: id, name: '$name (rev. comp.)', pfm: newPfm);
  }
}

String basesToIupac(List<String> letters) {
  final sorted = [...letters]..sort();
  return _iupacTable[sorted.join()] ?? 'N';
}

double calculateInformationContent(JasparMotif motif, int columnIdx) {
  final col = [for (var r = 0; r < 4; r++) motif.ppm[r][columnIdx]];

  var h = 0.0;
  for (final p in col) {
    if (p > 0) h -= p * (math.log(p) / math.ln2);
  }
  final ic = 2 - h;
  return math.max(0, ic);
}

class BaseFreq {
  const BaseFreq(this.name, this.freq);
  final String name;
  final double freq;
}

// Cavener (1987) consensus rule for a single column.
String getCavenerIupac(
  JasparMotif motif,
  int columnIdx, {
  double t1 = 0.5,
  double t2 = 0.75,
}) {
  final entries = [
    for (var row = 0; row < 4; row++)
      BaseFreq(bases[row], motif.ppm[row][columnIdx]),
  ]..sort((a, b) => b.freq.compareTo(a.freq));

  final b1 = entries[0];
  final b2 = entries[1];
  final b3 = entries[2];
  final b4 = entries[3];

  // 1 base
  if (b1.freq > t1 && b1.freq > 2 * b2.freq) {
    return b1.name;
  }

  // 2 bases
  if (b1.freq + b2.freq > t2) {
    return basesToIupac([b1.name, b2.name]);
  }

  // 3 bases
  //
  // Do not allow a 3-base code when all four bases are
  // essentially equally represented.
  if (b1.freq + b2.freq + b3.freq > t2 && b3.freq > b4.freq) {
    return basesToIupac([b1.name, b2.name, b3.name]);
  }

  return 'N';
}

typedef CoreBounds = ({int left, int right});

CoreBounds trimCoreByLetters(List<String> letters) {
  var left = 0;
  while (left < letters.length && letters[left] == 'N') {
    left++;
  }
  var right = letters.length - 1;
  while (right > left && letters[right] == 'N') {
    right--;
  }
  return (left: left, right: right);
}

Pfm parseManualMatrix(String rawText) {
  final text = rawText.trim();
  if (text.isEmpty) {
    throw const FormatException('Please paste a PFM matrix.');
  }

  try {
    final parsed = jsonDecode(text);
    if (parsed is List && parsed.length == 4) {
      return _normalizeRows(
        List<int>.from(parsed[0] as List),
        List<int>.from(parsed[1] as List),
        List<int>.from(parsed[2] as List),
        List<int>.from(parsed[3] as List),
      );
    }
    if (parsed is Map &&
        parsed.containsKey('A') &&
        parsed.containsKey('C') &&
        parsed.containsKey('G') &&
        parsed.containsKey('T')) {
      return _normalizeRows(
        List<int>.from(parsed['A'] as List),
        List<int>.from(parsed['C'] as List),
        List<int>.from(parsed['G'] as List),
        List<int>.from(parsed['T'] as List),
      );
    }
  } catch (_) {}

  final rowMap = <String, List<int>>{};
  final lineRegex = RegExp(
    r'^\s*([ACGTacgt])\s*[:=]?\s*\[?\s*([-\d.\s]+?)\s*\]?\s*$',
    multiLine: true,
  );
  for (final m in lineRegex.allMatches(text)) {
    final letter = m.group(1)!.toUpperCase();
    final nums = m
        .group(2)!
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .map(int.parse)
        .toList();
    if (nums.isNotEmpty) rowMap[letter] = nums;
  }
  if (rowMap.containsKey('A') &&
      rowMap.containsKey('C') &&
      rowMap.containsKey('G') &&
      rowMap.containsKey('T')) {
    return _normalizeRows(
      rowMap['A']!,
      rowMap['C']!,
      rowMap['G']!,
      rowMap['T']!,
    );
  }

  final lines = text
      .split(RegExp(r'\r?\n'))
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();
  final headerIdx = lines.indexWhere(
    (l) =>
        RegExp(r'^P0\b', caseSensitive: false).hasMatch(l) ||
        RegExp(r'^PO\b', caseSensitive: false).hasMatch(l),
  );
  if (headerIdx != -1) {
    final headerTokens = lines[headerIdx].split(RegExp(r'\s+'));
    final colOrder = <String>[];
    for (var i = 1; i < headerTokens.length; i++) {
      final t = headerTokens[i].toUpperCase();
      if (['A', 'C', 'G', 'T'].contains(t)) colOrder.add(t);
    }
    if (colOrder.length == 4) {
      final dataRows = <List<int>>[];
      for (var i = headerIdx + 1; i < lines.length; i++) {
        if (RegExp(r'^(XX|//)', caseSensitive: false).hasMatch(lines[i])) {
          break;
        }
        final tokens = lines[i].split(RegExp(r'\s+'));
        if (tokens.length < 5) break;
        final nums = tokens.sublist(1, 5).map(int.tryParse).toList();
        if (nums.any((n) => n == null)) break;
        dataRows.add(nums.cast<int>());
      }
      if (dataRows.isNotEmpty) {
        final cols = {
          'A': <int>[],
          'C': <int>[],
          'G': <int>[],
          'T': <int>[],
        };
        for (final row in dataRows) {
          for (var idx = 0; idx < colOrder.length; idx++) {
            cols[colOrder[idx]]!.add(row[idx]);
          }
        }
        return _normalizeRows(cols['A']!, cols['C']!, cols['G']!, cols['T']!);
      }
    }
  }

  throw const FormatException(
    'Could not recognize the matrix format (JASPAR, JSON, TRANSFAC).',
  );
}

Pfm _normalizeRows(List<int> a, List<int> c, List<int> g, List<int> t) {
  final length = a.length;
  if (c.length != length || g.length != length || t.length != length) {
    throw const FormatException('Rows A, C, G, T must have the same length.');
  }
  if (length == 0) throw const FormatException('Matrix is empty.');
  return [a, c, g, t];
}

List<String> computeConsensus(
  JasparMotif motif, {
  double t1 = 0.5,
  double t2 = 0.75,
  bool useInfoContentCutoff = false,
  double icThreshold = 0.5,
}) {
  return [
    for (var i = 0; i < motif.length; i++)
      () {
        var letter = getCavenerIupac(motif, i, t1: t1, t2: t2);
        if (useInfoContentCutoff) {
          final ic = calculateInformationContent(motif, i);
          if (ic < icThreshold) letter = 'N';
        }
        return letter;
      }(),
  ];
}
