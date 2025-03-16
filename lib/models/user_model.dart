class User {
  final String id;
  final String name;
  final String email;
  final String school;
  final DateTime createdAt;
  final DateTime lastLogin;
  final Map<String, dynamic> settings;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.school,
    required this.createdAt,
    required this.lastLogin,
    this.settings = const {},
  });

  // Create a User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      school: json['school'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLogin: DateTime.parse(json['lastLogin'] as String),
      settings: json['settings'] as Map<String, dynamic>? ?? {},
    );
  }

  // Convert a User to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'school': school,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin.toIso8601String(),
      'settings': settings,
    };
  }

  // Create a copy of User with updated fields
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? school,
    DateTime? createdAt,
    DateTime? lastLogin,
    Map<String, dynamic>? settings,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      school: school ?? this.school,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      settings: settings ?? this.settings,
    );
  }
}
