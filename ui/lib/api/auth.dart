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

  User({required this.id, required this.username, required this.groups});

  factory User.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'id': String id,
        'username': String username,
        'groups': List<dynamic> groups
      } =>
        User(
            id: id,
            username: username,
            groups: groups
                .map((group) =>
                    UserGroup.fromJson(group as Map<String, dynamic>))
                .toList()),
      _ => throw const FormatException('Failed to load user.')
    };
  }
}
