import 'package:pipeline/fasta.dart';
import 'package:pipeline/gff.dart';
import 'package:pipeline/tpm.dart';

/// Validates individual genes
class FastaValidator {
  /// Gff data
  final Gff gff;

  /// TPM data
  ///
  /// Key: Stage
  final Map<String, Tpm> stagesTpm;

  /// Fasta source
  final Fasta fasta;

  /// Use TSS marker (must be along ATG)
  final bool useTss;

  /// Allow missing start codon
  final bool allowMissingStartCodon;

  /// Keep only one transcript per gene (the first valid), all others will be marked as redundant
  final bool oneTranscriptPerGene;
  FastaValidator({
    required this.gff,
    required this.fasta,
    required this.stagesTpm,
    this.useTss = false,
    this.allowMissingStartCodon = false,
    this.oneTranscriptPerGene = true,
  });

  /// Validates individual genes
  ///
  /// Errors from validation are save at the gene level (`gff.genes[i].errors`)
  Future<void> validate() async {
    Map<String, GffFeature> uniqueTranscripts = {};

    for (final gene in gff.genes) {
      List<ValidationError> errors = [];

      // Check that there is a corresponding sequence
      final sequence = (await fasta.sequence(gene.seqId));
      if (sequence == null) {
        errors.add(ValidationError.noSequenceFound('Sequence `${gene.seqId}` not found in fasta file.'));
      }

      // Check that the strand is defined
      if (gene.strand == null) {
        errors.add(ValidationError.invalidStrand('Strand is not defined'));
      }

      // Start codon validation
      if (sequence != null && gene.strand != null) {
        final startCodons = gene.validStartCodons(sequence, gene.strand!);
        if (!allowMissingStartCodon) {
          if (startCodons.isEmpty) {
            errors.add(ValidationError.noStartCodonFound('Start codon is missing'));
          } else if (startCodons.length > 1) {
            errors
                .add(ValidationError.multipleStartCodonsFound('Multiple start codons found (${startCodons.length}).'));
          }
        }
      }

      // Five-prime-UTR
      final fivePrimeUtr = gene.fivePrimeUtr();
      if (useTss && fivePrimeUtr == null) {
        errors.add(ValidationError.noFivePrimeUtrFound('Five prime UTR is missing'));
      }
      if (fivePrimeUtr != null && sequence != null) {
        // check that we get either ATG (forward) or CAT (reverse)
        if (fivePrimeUtr.start - 1 < 0 || fivePrimeUtr.end > sequence.sequence.length) {
          errors.add(ValidationError.invalidFivePrimeUtr(
              'Five prime UTR is out of bounds. Start: ${fivePrimeUtr.start}, end: ${fivePrimeUtr.end}, sequence ${sequence.seqId} length: ${sequence.sequence.length}'));
        } else {
          final fivePrimeUtrLength = fivePrimeUtr.end - fivePrimeUtr.start + 1;
          if (fivePrimeUtrLength < 1) {
            errors.add(ValidationError.invalidFivePrimeUtr('Suspicious five prime UTR length: $fivePrimeUtrLength'));
          }
        }
      }

      // Check that we get data in TPM
      final transcriptId = gene.transcriptId;
      if (transcriptId == null) {
        errors.add(ValidationError.noIdFound('Gene name not found'));
      } else {
        for (final tpmKey in stagesTpm.keys) {
          final tpm = stagesTpm[tpmKey]!;
          final features = tpm.get(gene);
          if (features.isEmpty) {
            errors.add(ValidationError.noTpmDataFound('TPM data missing for stage $tpmKey'));
          } else if (features.length > 1) {
            errors.add(
                ValidationError.multipleTpmDataFound('Multiple TPM data (${features.length}) found for stage $tpmKey'));
          }
        }
      }
      gene.errors = errors;

      // Save a reference to the first valid transcript of each gene
      if (gene.errors!.isEmpty) {
        final existingTranscript = uniqueTranscripts[gene.geneId!];
        if (existingTranscript == null || (existingTranscript.transcriptNumber ?? 0) > (gene.transcriptNumber ?? 0)) {
          uniqueTranscripts[gene.geneId!] = gene;
        }
      }
    }

    // iterate again and add redundant transcript error to all genes that are not in uniqueTranscripts
    if (oneTranscriptPerGene) {
      for (final gene in gff.genes) {
        if (uniqueTranscripts[gene.geneId!] != null && uniqueTranscripts[gene.geneId!] != gene) {
          gene.errors!.add(ValidationError.redundantTranscript(
              'Gene is already represented by transcript ${uniqueTranscripts[gene.geneId!]!.transcriptId}'));
        }
      }
    }
  }
}

/// Individual validation error
class ValidationError {
  /// Type of the error
  final ValidationErrorType type;

  /// Error message
  final String? message;

  ValidationError(this.type, this.message);

  factory ValidationError.noSequenceFound(String? message) {
    return ValidationError(ValidationErrorType.noSequenceFound, message);
  }

  factory ValidationError.noStartCodonFound(String? message) {
    return ValidationError(ValidationErrorType.noStartCodonFound, message);
  }

  factory ValidationError.multipleStartCodonsFound(String? message) {
    return ValidationError(ValidationErrorType.multipleStartCodonsFound, message);
  }

  factory ValidationError.noFivePrimeUtrFound(String? message) {
    return ValidationError(ValidationErrorType.noFivePrimeUtrFound, message);
  }

  factory ValidationError.invalidFivePrimeUtr(String? message) {
    return ValidationError(ValidationErrorType.invalidFivePrimeUtr, message);
  }

  factory ValidationError.noTpmDataFound(String? message) {
    return ValidationError(ValidationErrorType.noTpmDataFound, message);
  }

  factory ValidationError.multipleTpmDataFound(String? message) {
    return ValidationError(ValidationErrorType.multipleTpmDataFound, message);
  }

  factory ValidationError.redundantTranscript(String? message) {
    return ValidationError(ValidationErrorType.redundantTranscript, message);
  }

  factory ValidationError.noIdFound(String? message) {
    return ValidationError(ValidationErrorType.noIdFound, message);
  }

  factory ValidationError.invalidStrand(String? message) {
    return ValidationError(ValidationErrorType.invalidStrand, message);
  }
}

/// Type of validation error
enum ValidationErrorType {
  /// `seqid` defined in the GFF file was not found in the FASTA file.
  ///
  /// `seqid` is the contents of the first column in the GFF file.
  noSequenceFound,

  /// Name of the gene was not found in the GFF file.
  ///
  /// See also [BaseOrganism.nameTransformer] interface which is responsible for extracting the name from the GFF file.
  noIdFound,

  /// Strand defined in GFF is expected to be either `+` or `-`.
  invalidStrand,

  /// Start codon was not found in the GFF file.
  noStartCodonFound,

  /// Multiple start codons were found in the GFF file.
  multipleStartCodonsFound,

  /// This transcript is redundant
  ///
  /// This gene is already represented by another transcript with lower number
  redundantTranscript,

  /// Five prime UTR was not found in the GFF file.
  ///
  /// This is only triggered when TSS processing is requested
  noFivePrimeUtrFound,

  /// Five prime UTR is invalid.
  ///
  /// It either:
  /// - points out of the bounds of the respective sequence
  /// - has a length < 1
  invalidFivePrimeUtr,

  /// TPM data was not found for this gene.
  ///
  /// i.e. TPM data for this gene is missing in the TPM files
  noTpmDataFound,

  /// Multiple TPM data was found for this gene.
  ///
  /// i.e. TPM data for this gene is present multiple times in the TPM files
  multipleTpmDataFound,
}
