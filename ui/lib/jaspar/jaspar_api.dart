// jaspar_api.dart
//
// Fetches a motif's PFM through GOLEM's OWN backend, which proxies the
// request to the public JASPAR API server-to-server (see
// backend/app/api/v1/routes/jaspar.py). A direct browser fetch straight
// to jaspar.elixir.no is subject to CORS and fails with a generic
// "Failed to fetch" the moment the target doesn't send back permissive
// CORS headers -- a server-to-server call isn't a browser request, so
// CORS doesn't apply to it.
//
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
    // JASPAR's own data was malformed/ragged -- surface it the same way
    // as any other fetch failure, rather than an uncaught crash.
    throw JasparFetchException('JASPAR returned an invalid matrix: ${e}');
  }
}
