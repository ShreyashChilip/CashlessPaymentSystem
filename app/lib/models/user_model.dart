class UserModel {
  final String id;
  final String username;
  final String role;

  UserModel({
    required this.id,
    required this.username,
    required this.role,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      username: map['username'] ?? '',
      role: map['role'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'role': role,
    };
  }
}
