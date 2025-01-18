class Product {
  final String id;
  final String name;
  final double price;
  final int stock;
  final String? barcode;
  final String? qrCode;
  final String? description;
  final String? imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.barcode,
    this.qrCode,
    this.description,
    this.imageUrl,
  });

  Product copyWith({
    String? id,
    String? name,
    double? price,
    int? stock,
    String? barcode,
    String? qrCode,
    String? description,
    String? imageUrl,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      barcode: barcode ?? this.barcode,
      qrCode: qrCode ?? this.qrCode,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'stock': stock,
      'barcode': barcode,
      'qrCode': qrCode,
      'description': description,
      'imageUrl': imageUrl,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      stock: json['stock'] as int,
      barcode: json['barcode'] as String?,
      qrCode: json['qrCode'] as String?,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }
}
