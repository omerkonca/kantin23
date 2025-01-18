class Sales {
  final DateTime date;
  final double totalAmount;
  final int totalTransactions;
  final List<ProductSales> productSales;
  final List<DailySales>? dailySales;
  final DateTime? startDate;
  final DateTime? endDate;

  Sales({
    required this.date,
    required this.totalAmount,
    required this.totalTransactions,
    required this.productSales,
    this.dailySales,
    this.startDate,
    this.endDate,
  });

  factory Sales.fromJson(Map<String, dynamic> json) {
    return Sales(
      date: DateTime.parse(json['date']),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      totalTransactions: json['totalTransactions'],
      productSales: (json['productSales'] as List)
          .map((item) => ProductSales.fromJson(item))
          .toList(),
      dailySales: json['dailySales'] != null
          ? (json['dailySales'] as List)
              .map((item) => DailySales.fromJson(item))
              .toList()
          : null,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : null,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'totalAmount': totalAmount,
      'totalTransactions': totalTransactions,
      'productSales': productSales.map((item) => item.toJson()).toList(),
      if (dailySales != null)
        'dailySales': dailySales!.map((item) => item.toJson()).toList(),
      if (startDate != null) 'startDate': startDate!.toIso8601String(),
      if (endDate != null) 'endDate': endDate!.toIso8601String(),
    };
  }
}

class DailySales {
  final DateTime date;
  final double totalAmount;
  final int totalTransactions;

  DailySales({
    required this.date,
    required this.totalAmount,
    required this.totalTransactions,
  });

  factory DailySales.fromJson(Map<String, dynamic> json) {
    return DailySales(
      date: DateTime.parse(json['date']),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      totalTransactions: json['totalTransactions'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'totalAmount': totalAmount,
      'totalTransactions': totalTransactions,
    };
  }
}

class ProductSales {
  final String productId;
  final String productName;
  final int quantity;
  final double totalAmount;

  ProductSales({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.totalAmount,
  });

  factory ProductSales.fromJson(Map<String, dynamic> json) {
    return ProductSales(
      productId: json['productId'],
      productName: json['productName'],
      quantity: json['quantity'],
      totalAmount: (json['totalAmount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'totalAmount': totalAmount,
    };
  }
}
