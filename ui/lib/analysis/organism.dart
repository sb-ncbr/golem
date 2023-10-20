import 'package:golem_ui/analysis/stage_and_color.dart';

/// Class that holds information about an organism
class Organism {
  /// The name of the organism
  final String name;

  /// The URL of the organism fasta file
  final String? filename;

  /// The description of the organism
  final String? description;

  /// Whether to take only the first transcript of each gene
  @Deprecated('Obsolete as this is now done in the pipeline')
  final bool takeFirstTranscriptOnly;

  /// Definition of how stages should be presented
  final List<StageAndColor> stages;

  Organism({
    required this.name,
    this.filename,
    this.description,
    this.takeFirstTranscriptOnly = true,
    this.stages = const [],
  });
}
