import 'dart:convert';

import 'package:geneweb/api/api_service.dart';
import 'package:geneweb/api/auth.dart';
import 'package:geneweb/utilities/gzip_service.dart';

class NewOrganism {
  final String id;
  final String name;
  final String? description;
  final String sequencesFilename;
  final String metadataFilename;
  final bool takeFirstTranscriptOnly;
  final bool public;
  final List<UserGroup> groups;

  const NewOrganism(
      {required this.id,
      required this.name,
      this.description,
      required this.sequencesFilename,
      required this.metadataFilename,
      required this.takeFirstTranscriptOnly,
      required this.public,
      required this.groups});

  factory NewOrganism.fromJson(Map<String, dynamic> json) {
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
        NewOrganism(
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
}

Future<List<NewOrganism>> fetchOrganisms({
  Function(String)? onError,
}) async {
  final response = await ApiService.instance.get('/organisms');

  if (!response.success) {
    onError?.call(response.message);
    return [];
  }

  return (response.data as List<dynamic>)
      .map((organism) => NewOrganism.fromJson(organism as Map<String, dynamic>))
      .toList();
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

typedef OrganismMetadata = Map<String, SequenceMetadata>;

Future<OrganismMetadata?> fetchMetadata(
    {required NewOrganism organism, Function(String)? onError}) async {
  final response = await ApiService.instance
      .download('/organisms/${organism.metadataFilename}');

  if (!response.success) {
    onError?.call(response.message);
    return null;
  }

  final metadata = const Utf8Decoder()
      .convert(await GZipService.instance.decompress(response.data));

  return (json.decode(metadata) as Map<String, dynamic>)
      .map((key, value) => MapEntry(key, SequenceMetadata.fromJson(value)));
}
