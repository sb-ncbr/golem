import 'package:geneweb/models/user.dart';

class Organism {
  /// The unique id of the organism
  final String id;

  /// The name of the organism
  final String name;

  /// The description of the organism
  final String? description;

  /// File (name) where the sequences are stored (fasta)
  final String sequencesFilename;

  /// File (name) where the metadata are stored (json)
  final String metadataFilename;

  /// Whether to take only the first transcript of each gene
  final bool takeFirstTranscriptOnly;

  /// Whether the organism is visible to everyone (every group)
  final bool public;

  /// Groups for which the ogranism is visible
  final List<UserGroup> groups;

  /// List of stages of the organism
  List<String> stages = [];

  Organism(
      {required this.id,
      required this.name,
      this.description,
      required this.sequencesFilename,
      required this.metadataFilename,
      required this.takeFirstTranscriptOnly,
      required this.public,
      required this.groups});

  factory Organism.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'id': String id,
        'name': String name,
        'description': String description,
        'sequencesFilename': String sequencesFilename,
        'metadataFilename': String metadataFilename,
        'takeFirstTranscriptOnly': bool takeFirstTranscriptOnly,
        'public': bool public,
        'groups': List<dynamic> groups,
      } =>
        Organism(
            id: id,
            name: name,
            description: description,
            sequencesFilename: sequencesFilename,
            metadataFilename: metadataFilename,
            takeFirstTranscriptOnly: takeFirstTranscriptOnly,
            public: public,
            groups: groups.map((group) => UserGroup.fromJson(group)).toList()),
      _ => throw const FormatException('Failed to load organism.')
    };
  }

  factory Organism.fromFile(String filename) {
    final name = RegExp(r'([A-Za-z0-9_]+).*')
            .firstMatch(filename)
            ?.group(1)
            ?.replaceAll('_', ' ') ??
        'Unknown organism';

    return Organism(
        id: '<id>',
        name: name,
        sequencesFilename: filename,
        metadataFilename: '',
        takeFirstTranscriptOnly: true,
        public: false,
        groups: []);
  }
}

class OrganismMetadata {
  final Map<String, StageMetadata> stages;
  final Map<String, SequenceMetadata> genes;

  const OrganismMetadata({required this.stages, required this.genes});

  factory OrganismMetadata.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      // new format which includes metadata for stages (srr and urls)
      {
        'stages': Map s,
        'genes': Map g,
      } =>
        OrganismMetadata(
            stages: Map.fromEntries(s.entries.map((stage) =>
                MapEntry(stage.key, StageMetadata.fromJson(stage.value)))),
            genes: Map.fromEntries(g.entries.map((gene) =>
                MapEntry(gene.key, SequenceMetadata.fromJson(gene.value))))),
      // old format which only includes genes
      Map<String, dynamic> data => OrganismMetadata(
          stages: {},
          genes: Map.fromEntries(data.entries.map((gene) =>
              MapEntry(gene.key, SequenceMetadata.fromJson(gene.value))))),
    };
  }
}

class StageMetadata {
  final String srr;
  final String url;

  const StageMetadata({required this.srr, required this.url});

  Map<String, dynamic> toJson() => {'srr': srr, 'url': url};

  factory StageMetadata.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {'srr': String srr, 'url': String url} =>
        StageMetadata(srr: srr, url: url),
      _ => throw const FormatException('Failed to load stage metadata.')
    };
  }
}

class SequenceMetadata {
  final Map<String, int> markers;
  final Map<String, double> transcriptionRates;

  const SequenceMetadata(
      {required this.markers, required this.transcriptionRates});

  factory SequenceMetadata.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'markers': Map markers,
        'transcriptionRates': Map transcriptionRates,
      } =>
        SequenceMetadata(
            markers: Map.from(markers),
            transcriptionRates: Map.from(transcriptionRates)),
      _ => throw const FormatException('Failed to load sequence metadata.')
    };
  }
}
