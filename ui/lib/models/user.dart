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

class StagePreference {
  final String? organismId;
  final String stageName;
  String color;

  StagePreference(
      {required this.stageName, required this.color, this.organismId});

  factory StagePreference.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'stageName': String stageName,
        'color': String color,
        'organismId': String organismId
      } =>
        StagePreference(
            stageName: stageName, color: color, organismId: organismId),
      {
        'stageName': String stageName,
        'color': String color,
      } =>
        StagePreference(stageName: stageName, color: color),
      _ => throw const FormatException('Failed to load stage preference')
    };
  }
}
