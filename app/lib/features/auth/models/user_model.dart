class UserModel {
  const UserModel({required this.id, required this.name, required this.email});

  final String id;
  final String name;
  final String email;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
    );
  }
}

class AuthResult {
  const AuthResult({required this.token, required this.user});

  final String token;
  final UserModel user;
}
