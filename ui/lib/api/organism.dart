import 'dart:convert';

import 'package:geneweb/api/api_service.dart';
import 'package:geneweb/models/organism.dart';

Future<List<Organism>> fetchOrganisms({
  Function(String)? onError,
}) async {
  final response = await ApiService.instance.get('/organisms');

  if (!response.success) {
    onError?.call(response.message);
    return [];
  }

  return (response.data as List<dynamic>)
      .map((organism) => Organism.fromJson(organism as Map<String, dynamic>))
      .toList();
}

Future<OrganismMetadata?> fetchMetadata(
    {required Organism organism, Function(String)? onError}) async {
  final response = await ApiService.instance
      .download('/organisms/${organism.metadataFilename}');

  if (!response.success) {
    onError?.call(response.message);
    return null;
  }

  final jsonString = json.decode(String.fromCharCodes(response.data));
  return OrganismMetadata.fromJson(jsonString);
}
