class Transaction {
  final String id;
  final String userId;
  final String productId;
  final int quantity;
  final double amount;
  final String description;
  final DateTime date;

  Transaction({
    required this.id,
    required this.userId,
    required this.productId,
    required this.quantity,
    required this.amount,
    required this.description,
    required this.date,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      userId: json['userId'],
      productId: json['productId'],
      quantity: json['quantity'],
      amount: (json['amount'] as num).toDouble(),
      description: json['description'],
      date: DateTime.parse(json['date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'productId': productId,
      'quantity': quantity,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
    };
  }
}
