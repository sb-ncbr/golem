import 'package:geneweb/api/api_service.dart';

class UserGroup {
  final String id;
  final String name;

  UserGroup({required this.id, required this.name});

  factory UserGroup.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'id': String id,
        'name': String name,
      } =>
        UserGroup(id: id, name: name),
      _ => throw const FormatException('Failed to load user group')
    };
  }
}

class StagePreference {
  final String stageName;
  String color;

  StagePreference({required this.stageName, required this.color});

  factory StagePreference.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'stageName': String stageName,
        'color': String color,
      } =>
        StagePreference(stageName: stageName, color: color),
      _ => throw const FormatException('Failed to load stage preference')
    };
  }

  static Future<ApiResponse> updatePreference(
      StagePreference preference) async {
    return ApiService.instance.put("/preferences",
        data: {'stageName': preference.stageName, 'color': preference.color});
  }

  static Future<List<StagePreference>> getDefaults() async {
    final response = await ApiService.instance.get('/preferences/default');

    if (!response.success) {
      return [];
    }

    final preferences = response.data as List<dynamic>;
    return preferences.map((pref) => StagePreference.fromJson(pref)).toList();
  }
}

class User {
  final String id;
  final String username;
  final List<UserGroup> groups;
  final List<StagePreference> preferences;

  User(
      {required this.id,
      required this.username,
      required this.groups,
      required this.preferences});

  factory User.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'id': String id,
        'username': String username,
        'groups': List<dynamic> groups,
        'stagePreferences': List<dynamic> preferences,
      } =>
        User(
          id: id,
          username: username,
          groups: groups
              .map((group) => UserGroup.fromJson(group as Map<String, dynamic>))
              .toList(),
          preferences: preferences
              .map((preference) =>
                  StagePreference.fromJson(preference as Map<String, dynamic>))
              .toList(),
        ),
      _ => throw const FormatException('Failed to load user.')
    };
  }
}
