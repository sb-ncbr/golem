import 'dart:convert';
import 'dart:math';

import 'package:pipeline/fasta.dart';
import 'package:pipeline/gff.dart';
import 'package:pipeline/sequence_tools.dart';
import 'package:pipeline/tpm.dart';
import 'package:string_splitter/string_splitter.dart';
import 'package:collection/collection.dart';

/// Class responsible for generating the resulting fasta file
class FastaGenerator {
  /// Gff data
  final Gff gff;

  /// TPM data
  final Map<String, Tpm> tpm;

  /// Fasta source
  final Fasta fasta;

  /// Use TSS marker (must be along ATG)
  final bool useTss;

  /// Use ATG marker (will also validate that the sequence matches 'ATG')
  final bool useAtg;

  /// Will use the whole sequence instead of start codon
  final bool useSelfInsteadOfStartCodon;

  late final tools = SequenceTools();

  FastaGenerator(this.gff, this.fasta, this.tpm,
      {this.useTss = false, this.useAtg = true, this.useSelfInsteadOfStartCodon = false})
      : assert(!useTss || useAtg, 'TSS can only be used with ATG');

  Stream<List<String>> toFasta(int deltaBases) async* {
    for (final gene in gff.genes) {
      // Ignore genes with validation errors
      if (gene.errors == null) StateError('Validation must be run before generating fasta file');
      if (gene.errors!.isNotEmpty) continue;

      final geneTpm = {
        for (final tpmKey in tpm.keys) tpmKey: tpm[tpmKey]!.get(gene).first,
      };
      final geneTpmJson = {
        for (final tpmKey in geneTpm.keys) tpmKey: geneTpm[tpmKey]!.avg,
      };

      // Start and end of the sequence of interest
      final geneSequence = await fasta.sequence(gene.seqId);
      final startCodon = gene.validStartCodons(geneSequence!, gene.strand!).firstOrNull;
      final startCodonBegin = (useSelfInsteadOfStartCodon ? gene.start : startCodon!.start) - 1;
      final startCodonEnd = useSelfInsteadOfStartCodon ? gene.end : startCodon!.end;

      // Where is the TSS relative to ATG
      final tssDelta = !useTss
          ? null
          : gene.strand == Strand.forward
              ? startCodonBegin - gene.fivePrimeUtr()!.start
              : gene.fivePrimeUtr()!.end - startCodonEnd;
      assert(tssDelta == null || tssDelta >= 0);

      // Get the whole sequence for the gene
      final wholeSequence = (await fasta.sequence(gene.seqId))!.sequence; // shall not pass validation

      // bpbs to cut before and after ATG
      final basesBeforeAtg = deltaBases + (gene.strand == Strand.forward ? (tssDelta ?? 0) : 0);
      final basesAfterAtg = deltaBases + (gene.strand == Strand.reverse ? (tssDelta ?? 0) : 0);

      final before = wholeSequence.substring(max(0, startCodonBegin - basesBeforeAtg), startCodonBegin);
      final codon = wholeSequence.substring(startCodonBegin, startCodonEnd);
      final after =
          wholeSequence.substring(startCodonEnd + 1, min(wholeSequence.length, startCodonEnd + basesAfterAtg + 1));
      // (reversed) sequence with area before, codon and after the codon
      final sequence = gene.strand == Strand.forward
          ? '$before$codon$after'
          : '${tools.reverse(after)}${tools.reverse(codon)}${tools.reverse(before)}';

      /// ATG and TSS positions
      final atgPosition = !useAtg
          ? null
          : gene.strand == Strand.forward
              ? before.length + 1
              : after.length + 1;
      final tssPosition = useTss ? atgPosition! - tssDelta! : null;
      assert(!useTss || tssPosition != null, 'TSS not found for gene ${gene.transcriptId}');
      if (useAtg) {
        final validationCodon = sequence.substring(atgPosition! - 1, atgPosition - 1 + 3);
        assert(validationCodon == 'ATG', 'Unexpected codon: $codon');
      }
      final splitSequences = StringSplitter.chunk(sequence, 80);

      final markers = {
        if (useAtg) "atg": atgPosition,
        if (useTss) "tss": tssPosition,
      };

      final List<String> result = [
        '>${gene.transcriptId} ${gene.strand!.name.toUpperCase()} LENGTH=${sequence.length}',
        ';SOURCE $gene',
        ';DESCRIPTION ${geneTpm.values.firstOrNull?.description}',
        ';TRANSCRIPTION_RATES ${jsonEncode(geneTpmJson)}',
        if (markers.isNotEmpty) ';MARKERS ${jsonEncode(markers)}',
        ...splitSequences
      ];

      yield result;
    }
  }
}
