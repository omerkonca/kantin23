class User {
  final String id;
  final String name;
  final String email;
  final String studentId;
  final String role;
  final double balance;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.studentId,
    required this.role,
    required this.balance,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      studentId: json['studentId'],
      role: json['role'],
      balance: (json['balance'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'studentId': studentId,
      'role': role,
      'balance': balance,
    };
  }
}
