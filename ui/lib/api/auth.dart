import 'package:geneweb/api/api_service.dart';
import 'package:geneweb/models/user.dart';

Future<ApiResponse> updatePreference(StagePreference preference) async {
  if (preference.organismId == null) {
    throw Exception('Organism not provided');
  }

  return ApiService.instance.put("/preferences", data: {
    'stageName': preference.stageName,
    'color': preference.color,
    'organismId': preference.organismId
  });
}

Future<List<StagePreference>> getDefaultPreferences() async {
  final response = await ApiService.instance.get('/preferences/default');

  if (!response.success) {
    return [];
  }

  final preferences = response.data as List<dynamic>;
  return preferences.map((pref) => StagePreference.fromJson(pref)).toList();
}
