import 'package:pipeline/gff.dart';
import 'package:pipeline/tpm.dart';

/// Generates a file with the summary of all (valid) genes and their TPM values
class TPMSummaryGenerator {
  /// Gff data
  final Gff gff;

  /// TPM data
  final Map<String, Tpm> tpm;

  TPMSummaryGenerator(this.gff, this.tpm);

  /// Generates a CSV file contents with the summary of all (valid) genes and their TPM values
  List<List<String>> toCsv() {
    List<List<String>> result = [];

    // Header
    result.add(['Gene', ...tpm.keys]);

    // Content
    for (final gene in gff.genes) {
      // Ignore genes with validation errors
      if (gene.errors == null) StateError('Validation must be run before generating fasta file');
      if (gene.errors!.isNotEmpty) continue;

      final geneTpm = [
        for (final tpmKey in tpm.keys) tpm[tpmKey]!.get(gene).first.avg.toString(),
      ];

      result.add([gene.transcriptId!, ...geneTpm]);
    }
    return result;
  }
}
