/// Defines behavior for preset organisms.
abstract class BaseOrganism {
  /// Default number of bp to take from ATG/TSS when producing the resulting file.
  static const kDefaultDeltaBases = 1000;

  /// Organism name
  final String name;

  /// Features to ignore when parsing GFF file
  final List<String> ignoredFeatures;

  /// Features that trigger a new gene / transcript when parsing GFF file
  final List<String> triggerFeatures;

  /// Whether to allow genes without start codon
  final bool allowMissingStartCodon;

  /// Whether to use the gene itself instead of the start codon
  final bool useSelfInsteadOfStartCodon;

  /// Whether to use ATG marker (will also validate that the sequence matches 'ATG')
  final bool useAtg;

  /// This will only take the first valid transcript for each gene.
  ///
  /// Required that the transcripts are represented by the dot notation (geneId.1, geneId.2, etc.)
  final bool oneTranscriptPerGene;

  /// Number of bp to take from ATG/TSS when producing the resulting file.
  final int deltaBases;

  BaseOrganism({
    required this.name,
    this.ignoredFeatures = const ['chromosome', 'gene', 'transcript'],
    this.triggerFeatures = const ['mRNA'],
    this.allowMissingStartCodon = false,
    this.useSelfInsteadOfStartCodon = false,
    this.useAtg = true,
    this.oneTranscriptPerGene = true,
    this.deltaBases = kDefaultDeltaBases,
  }) : assert(triggerFeatures.isNotEmpty);

  /// Converts the file name of the TPM file to the stage name.
  String? stageNameFromTpmFilePath(String path);

  /// Transforms the sequence identifier from GFF to the one from the fasta file.
  String seqIdTransformer(String seqId) => seqId;

  /// Finds the transcript id from the attributes.
  String? transcriptParser(Map<String, String> attributes) => attributes['Name'];

  /// Finds the fallback transcript ID
  ///
  /// Used for the purpose of associating TPM of the main transcript where TPM for this transcript is not available.
  String? fallbackTranscriptParser(Map<String, String> attributes) {
    final transcriptId = transcriptParser(attributes);
    if (transcriptId?.contains('.') != true) return null;
    final parts = transcriptId?.split('.');
    final candidate = '${parts?.take(parts.length - 1).join('.')}.1';

    if (candidate == transcriptId) {
      return null;
    } else {
      return candidate;
    }
  }

  /// Finds the sequence identifier from the GFF line (normally the first column)
  String sequenceIdentifier(List<String> line) => line[0];
}
