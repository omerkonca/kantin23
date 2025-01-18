class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? studentId;
  final double balance;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.studentId,
    required this.balance,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? studentId,
    double? balance,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      studentId: studentId ?? this.studentId,
      balance: balance ?? this.balance,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'studentId': studentId,
      'balance': balance,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      studentId: json['studentId'] as String?,
      balance: (json['balance'] as num).toDouble(),
    );
  }

  bool get isAdmin => role == 'admin';
  bool get isStudent => role == 'student';
}
