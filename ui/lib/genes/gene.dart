import 'dart:convert';
import 'dart:math';

/// Holds a single gene data
class Gene {
  Gene._({
    required this.geneId,
    required this.data,
    required this.header,
    required this.notes,
    this.transcriptionRates = const {},
    this.markers = const {},
  });

  /// Loads the gene from FASTA file chunk
  factory Gene.fromFasta(List<String> lines) {
    String? header;
    String? geneId;
    List<String> notes = [];
    List<String> data = [];
    Map<String, num>? transcriptionRates;
    Map<String, int>? markers;

    for (final line in lines) {
      if (line.isEmpty) continue;
      if (line[0] == '>') {
        if (header != null) {
          throw Exception('Multiple header lines');
        }
        header = line;
        geneId = geneIdRegExp.firstMatch(line)?.namedGroup('gene');
      } else if (line[0] == ';') {
        final transcriptionRatesJson = transcriptionRatesRegExp.firstMatch(line)?.namedGroup('json');
        if (transcriptionRatesJson != null) {
          transcriptionRates = Map<String, num>.from(jsonDecode(transcriptionRatesJson));
        }
        final markersJson = markersRegExp.firstMatch(line)?.namedGroup('json');
        if (markersJson != null) {
          markers = Map<String, int>.from(jsonDecode(markersJson));
        }
        notes.add(line);
      } else {
        data.add(line.trim().toUpperCase());
      }
    }
    if (header == null || geneId == null) {
      throw Exception('Unable to parse: ${lines.join('\n')}');
    }
    final sequence = data.join();
    final atg = markers?['atg'];
    if (atg != null) {
      final codon = sequence.substring(atg - 1, atg - 1 + 3);
      if (codon != 'ATG' && codon != 'CAT') {
        throw StateError('$geneId: Expected `ATG`/`CAT` at ATG position of $atg, got `$codon` instead.');
      }
    }
    return Gene._(
      geneId: geneId,
      data: sequence,
      header: header,
      notes: notes,
      transcriptionRates: transcriptionRates ?? {},
      markers: markers ?? {},
    );
  }

  static final geneIdRegExp = RegExp(r"(?<gene>[A-Za-z0-9+_\.]+)");
  static final markersRegExp = RegExp(r";MARKERS (?<json>\{.*\})$");
  static final transcriptionRatesRegExp = RegExp(r";TRANSCRIPTION_RATES (?<json>\{.*\})$");

  /// Raw nucleotides data
  final String data;

  /// Gene name including splicing variant, e.g. `ATG0001.1`
  final String geneId;

  /// Header line (>GENE ID...)
  final String header;

  final Map<String, int> markers;

  /// Notes
  final List<String> notes;

  final Map<String, num> transcriptionRates;

  String? _geneCode;

  @override
  String toString() {
    return geneId;
  }

  Gene copyWith({
    String? geneId,
    String? data,
    String? header,
    List<String>? notes,
    Map<String, num>? transcriptionRates,
    Map<String, int>? markers,
  }) {
    return Gene._(
      geneId: geneId ?? this.geneId,
      data: data ?? this.data,
      header: header ?? this.header,
      notes: notes ?? this.notes,
      transcriptionRates: transcriptionRates ?? this.transcriptionRates,
      markers: markers ?? this.markers,
    );
  }

  /// Returns the gene name without the splicing variant
  String get geneCode {
    final items = geneId.split('.');
    _geneCode ??= items.sublist(0, max(items.length - 1, 1)).join('.');
    return _geneCode!;
  }

  /// Returns the splicing variant of the gene
  String get geneSplicingVariant => geneId.split('.').last;
}
