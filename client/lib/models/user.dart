class UserRole {
  const UserRole._(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static const requester = UserRole._('requester', 'Requester');
  static const runner = UserRole._('runner', 'Runner');

  static UserRole fromWire(String value) =>
      value == runner.wireValue ? runner : requester;
}

class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final DateTime createdAt;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: UserRole.fromWire(json['role'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
