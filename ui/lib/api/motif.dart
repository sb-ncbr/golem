import 'package:geneweb/models/motif.dart';
import 'package:geneweb/api/api_service.dart';

Future<List<Motif>> fetchMotifs({Function(String)? onError}) async {
  final response = await ApiService.instance.get('/motifs');

  if (!response.success) {
    onError?.call(response.message);
    return [];
  }

  return (response.data as List<dynamic>)
      .map((motif) => Motif.fromJson(motif as Map<String, dynamic>))
      .toList();
}

Future<Motif> createMotif(Motif motif, {Function(String)? onError}) async {
  final response = await ApiService.instance.post('/motifs',
      data: {'name': motif.name, 'definitions': motif.definitions});

  if (!response.success) {
    onError?.call(response.message);
  }

  return Motif.fromJson(response.data);
}

Future<void> deleteMotif(String id,
    {Function? onSuccess, Function(String)? onError}) async {
  final response = await ApiService.instance.delete('/motifs/$id');

  if (!response.success) {
    onError?.call(response.message);
  }

  onSuccess?.call();
}
