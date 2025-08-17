import 'package:geneweb/api/api_service.dart';

class NewOrganism {
  final String id;
  final String name;
  final String? description;
  final String sequencesFilename;
  final String metadataFilename;
  final bool public;

  const NewOrganism(
      {required this.id,
      required this.name,
      this.description,
      required this.sequencesFilename,
      required this.metadataFilename,
      required this.public});

  factory NewOrganism.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'id': String id,
        'name': String name,
        'description': String description,
        'sequencesFilename': String sequencesFilename,
        'metadataFilename': String metadataFilename,
        'public': bool public
      } =>
        NewOrganism(
            id: id,
            name: name,
            description: description,
            sequencesFilename: sequencesFilename,
            metadataFilename: metadataFilename,
            public: public),
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
