import 'dart:convert';
import 'dart:io';

import 'package:pipeline/gff.dart';

/// Contains parsed TPM data
class Tpm {
  /// TPM data for each gene. Key is the transcriptId, value is a list of features (should be just one)
  final Map<String, List<TpmFeature>> genes;

  Tpm._({required this.genes});

  /// Gets the TPM data for a given gene
  List<TpmFeature> get(GffFeature gene) {
    final result = genes[gene.transcriptId] ?? genes[gene.fallbackTranscriptId] ?? [];
    return result;
  }

  /// Creates the Tpm object from a file
  static Future<Tpm> fromFile({
    required FileSystemEntity entity,
    required String Function(List<String> line) geneIdParser,
  }) async {
    final file = File(entity.path);
    List<String> lines;
    try {
      lines = await file.readAsLines(encoding: Utf8Codec(allowMalformed: true));
    } on FileSystemException catch (_) {
      lines = await file.readAsLines(encoding: ascii); //UTF-8 causes problems with some files
      // if it throws again, it's not a valid file
    }
    final Map<String, List<TpmFeature>> result = {};
    TPMFileFormat format;
    final firstLine = lines.first;
    if (firstLine == 'Sequence	Aliases	Description	Avg.Expression	Min.Expression	Max.Expression') {
      format = TPMFileFormat.long;
    } else {
      format = TPMFileFormat.short;
    }

    for (final line in lines.skip(1)) {
      final feature = TpmFeature.fromLine(line, geneIdParser: geneIdParser, format: format);
      if (result.containsKey(feature.geneId)) {
        result[feature.geneId]!.add(feature);
      } else {
        result[feature.geneId] = [feature];
      }
    }
    return Tpm._(genes: result);
  }
}

/// Single line from TPM file
class TpmFeature {
  final String geneId;
  final String? aliases;
  final String? description;
  final double avg;
  final double? min;
  final double? max;

  TpmFeature({
    required this.geneId,
    this.aliases,
    this.description,
    required this.avg,
    this.min,
    this.max,
  });

  /// Parses a single line from TPM file
  factory TpmFeature.fromLine(
    String line, {
    required String Function(List<String> line) geneIdParser,
    required TPMFileFormat format,
  }) {
    if (format == TPMFileFormat.short) {
      final parts = line.split(RegExp(r'[\s,]'));
      if (parts.length < 2) throw StateError('Expected 2+ columns, got ${parts.length}: $line');
      final geneId = geneIdParser(parts);
      return TpmFeature(
        geneId: geneId,
        avg: double.parse(parts[1]),
      );
    } else if (format == TPMFileFormat.long) {
      final parts = line.split('\t');
      if (parts.length != 6) throw StateError('Expected 6 columns, got ${parts.length}: $line');
      final geneId = geneIdParser(parts);
      return TpmFeature(
        geneId: geneId,
        aliases: parts[1],
        description: parts[2],
        avg: double.parse(parts[3]),
        min: double.parse(parts[4]),
        max: double.parse(parts[5]),
      );
    }
    throw StateError('Invalid format: $format');
  }

  @override
  String toString() {
    return '$geneId $min $avg $max';
  }
}

enum TPMFileFormat { long, short }
