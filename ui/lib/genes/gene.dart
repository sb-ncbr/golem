import 'dart:convert';
import 'dart:math';

import 'package:geneweb/models/organism.dart';

/// Holds a single gene data
class Gene {
  Gene._({
    required this.geneId,
    required this.data,
    this.transcriptionRates = const {},
    this.markers = const {},
  });

  /// Loads the gene from FASTA (with comments) file chunk
  factory Gene.fromFastaWithComments(List<String> lines) {
    String? header;
    String? geneId;
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
        final transcriptionRatesJson =
            transcriptionRatesRegExp.firstMatch(line)?.namedGroup('json');
        if (transcriptionRatesJson != null) {
          transcriptionRates =
              Map<String, num>.from(jsonDecode(transcriptionRatesJson));
        }
        final markersJson = markersRegExp.firstMatch(line)?.namedGroup('json');
        if (markersJson != null) {
          markers = Map<String, int>.from(jsonDecode(markersJson));
        }
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
        throw StateError(
            '$geneId: Expected `ATG`/`CAT` at ATG position of $atg, got `$codon` instead.');
      }
    }
    return Gene._(
      geneId: String.fromCharCodes(
          geneId.codeUnits), // Ensure geneId not references the original string
      data: sequence,
      transcriptionRates: transcriptionRates ?? {},
      markers: markers ?? {},
    );
  }

  /// Loads the gene from FASTA file chunk
  factory Gene.fromFasta(
      List<String> lines, OrganismMetadata organismMetadata) {
    String? header;
    String? geneId;
    List<String> data = [];

    for (final line in lines) {
      if (line.isEmpty) continue;
      if (line[0] == '>') {
        if (header != null) {
          throw Exception('Multiple header lines');
        }
        header = line;
        geneId = geneIdRegExp.firstMatch(line)?.namedGroup('gene');
      } else if (line[0] == ';') {
        continue;
      } else {
        data.add(line.trim().toUpperCase());
      }
    }
    if (header == null || geneId == null) {
      throw Exception('Unable to parse: ${lines.join('\n')}');
    }

    final sequence = data.join();
    final metadata = organismMetadata.genes[geneId];
    if (metadata == null) {
      throw Exception('Metadata not found for gene: $geneId');
    }

    final atg = metadata.markers['atg'];
    if (atg != null) {
      final codon = sequence.substring(atg - 1, atg - 1 + 3);
      if (codon != 'ATG' && codon != 'CAT') {
        throw StateError(
            '$geneId: Expected `ATG`/`CAT` at ATG position of $atg, got `$codon` instead.');
      }
    }
    return Gene._(
      geneId: String.fromCharCodes(
          geneId.codeUnits), // Ensure geneId not references the original string
      data: sequence,
      transcriptionRates: metadata.transcriptionRates,
      markers: metadata.markers,
    );
  }

  static final geneIdRegExp = RegExp(r"(?<gene>[A-Za-z0-9+_\.\-]+)");
  static final markersRegExp = RegExp(r";MARKERS (?<json>\{.*\})$");
  static final transcriptionRatesRegExp =
      RegExp(r";TRANSCRIPTION_RATES (?<json>\{.*\})$");

  /// Raw nucleotides data
  final String data;

  /// Gene name including splicing variant, e.g. `ATG0001.1`
  final String geneId;

  final Map<String, int> markers;

  final Map<String, num> transcriptionRates;

  String? _geneCode;

  @override
  String toString() {
    return geneId;
  }

  Gene copyWith({
    String? geneId,
    String? data,
    Map<String, num>? transcriptionRates,
    Map<String, int>? markers,
  }) {
    return Gene._(
      geneId: geneId ?? this.geneId,
      data: data ?? this.data,
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
