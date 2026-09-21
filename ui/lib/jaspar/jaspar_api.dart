// Uses the SAME ApiService/Dio client the rest of the UI uses to talk
// to the GOLEM backend (see api/api_service.dart) -- not package:http,
// since this is now a call to our own backend, not an external API.

import 'package:geneweb/api/api_service.dart';

import 'motif_logic.dart';

class JasparFetchException implements Exception {
  JasparFetchException(this.message);
  final String message;
  @override
  String toString() => message;
}

Future<JasparMotif> fetchJasparMotif(String motifId) async {
  final response = await ApiService.instance.get('/jaspar/$motifId');

  if (!response.success) {
    throw JasparFetchException(
      response.message.isEmpty ? 'JASPAR fetch failed.' : response.message,
    );
  }

  final data = response.data as Map<String, dynamic>;
  final pfmJson = data['pfm'] as Map<String, dynamic>?;
  if (pfmJson == null) {
    throw JasparFetchException('Response did not contain a PFM matrix.');
  }

  try {
    return JasparMotif(
      id: data['matrix_id'] as String? ?? motifId,
      name: data['name'] as String? ?? '',
      pfm: [
        List<int>.from(pfmJson['A'] as List),
        List<int>.from(pfmJson['C'] as List),
        List<int>.from(pfmJson['G'] as List),
        List<int>.from(pfmJson['T'] as List),
      ],
    );
  } on Error catch (e) {
    throw JasparFetchException('JASPAR returned an invalid matrix: ${e}');
  }
}
