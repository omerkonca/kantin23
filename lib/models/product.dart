class Product {
  final String id;
  final String name;
  final double price;
  final int stock;
  final String? barcode;
  final String? imageUrl;
  final String qrCode;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.barcode,
    this.imageUrl,
    required this.qrCode,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      stock: json['stock'] as int,
      barcode: json['barcode'],
      imageUrl: json['imageUrl'],
      qrCode: json['qrCode'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'stock': stock,
      'barcode': barcode,
      'imageUrl': imageUrl,
      'qrCode': qrCode,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    double? price,
    int? stock,
    String? barcode,
    String? imageUrl,
    String? qrCode,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      barcode: barcode ?? this.barcode,
      imageUrl: imageUrl ?? this.imageUrl,
      qrCode: qrCode ?? this.qrCode,
    );
  }
}
