import 'package:geneweb/api/api_service.dart';

class NewOrganism {
  final String id;
  final String name;
  final String? description;
  final String filename;
  final bool public;

  const NewOrganism(
      {required this.id,
      required this.name,
      this.description,
      required this.filename,
      required this.public});

  factory NewOrganism.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'id': String id,
        'name': String name,
        'description': String description,
        'filename': String filename,
        'public': bool public
      } =>
        NewOrganism(
            id: id,
            name: name,
            description: description,
            filename: filename,
            public: public),
      _ => throw const FormatException('Failed to load organism.')
    };
  }
}

Future<List<NewOrganism>> fetchOrganisms({
  Function(String)? onError,
}) async {
  final response = await ApiService().get('/organisms');

  if (!response.success) {
    onError?.call(response.message);
    return [];
  }

  return (response.data as List<dynamic>)
      .map((organism) => NewOrganism.fromJson(organism as Map<String, dynamic>))
      .toList();
}
