import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/product.dart';
import '../models/transaction.dart';
import '../models/sales.dart';
import '../models/user.dart';
import 'package:intl/intl.dart';

class ApiService {
  // Render.com'dan alacağınız URL'yi buraya yazın
  static const String baseUrl = 'https://kantin23-server.onrender.com/api';
  final String? authToken;
  final SharedPreferences prefs;

  ApiService._(this.authToken, this.prefs);

  static Future<ApiService> create({String? authToken}) async {
    final prefs = await SharedPreferences.getInstance();
    return ApiService._(authToken, prefs);
  }

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    return headers;
  }

  // Offline cache methods
  Future<void> _cacheData(String key, dynamic data) async {
    await prefs.setString(key, jsonEncode(data));
  }

  dynamic _getCachedData(String key) {
    final data = prefs.getString(key);
    return data != null ? jsonDecode(data) : null;
  }

  Future<bool> _hasInternetConnection() async {
    return false; // Her zaman çevrimdışı mod
  }

  // Auth endpoints
  Future<User> login(String email, String password) async {
    // Get user credentials
    final credentials = _getCachedData('user_credentials_$email');
    if (credentials != null && credentials['password'] == password) {
      final userId = credentials['userId'];
      final userData = _getCachedData('student_$userId') ?? _getCachedData('user_$userId');
      
      if (userData != null) {
        return User.fromJson(userData);
      }
    }

    // If no cached user found, try default users
    const defaultUsers = {
      'admin@kantin23.com': {
        'id': 'admin1',
        'name': 'Admin',
        'email': 'admin@kantin23.com',
        'studentId': '',
        'role': 'admin',
        'balance': 0.0,
        'password': 'admin123'
      },
      'ogrenci@kantin23.com': {
        'id': 'student1',
        'name': 'Örnek Öğrenci',
        'email': 'ogrenci@kantin23.com',
        'studentId': '2024001',
        'role': 'student',
        'balance': 100.0,
        'password': 'ogrenci123'
      },
    };

    final user = defaultUsers[email];
    if (user != null && user['password'] == password) {
      await _cacheData('user_${user['id']}', user);
      return User.fromJson(user);
    }

    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final userData = jsonDecode(response.body);
      await _cacheData('user_${userData['id']}', userData);
      return User.fromJson(userData);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'E-posta veya şifre hatalı');
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? studentId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'studentId': studentId,
      }),
    );

    if (response.statusCode != 201) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Kayıt olunamadı');
    }
  }

  Future<void> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: _headers,
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Şifre sıfırlama isteği gönderilemedi');
    }
  }

  // Product endpoints
  Future<List<Product>> getProducts() async {
    // Mock products
    final mockProducts = [
      {
        'id': 'product1',
        'name': 'Su',
        'price': 5.0,
        'stock': 100,
        'qrCode': 'PRD001',
        'barcode': '8690123456789',
        'imageUrl': null,
      },
      {
        'id': 'product2',
        'name': 'Sandviç',
        'price': 25.0,
        'stock': 50,
        'qrCode': 'PRD002',
        'barcode': '8690123456790',
        'imageUrl': null,
      },
      {
        'id': 'product3',
        'name': 'Çikolata',
        'price': 12.5,
        'stock': 75,
        'qrCode': 'PRD003',
        'barcode': '8690123456791',
        'imageUrl': null,
      },
    ];

    final response = await http.get(
      Uri.parse('$baseUrl/products'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> products = jsonDecode(response.body);
      return products.map((json) => Product.fromJson(json)).toList();
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Ürünler alınamadı');
    }
  }

  Future<Product> createProduct(Product product) async {
    // Mock product creation
    final productId = 'product${DateTime.now().millisecondsSinceEpoch}';
    final newProduct = {
      'id': productId,
      'name': product.name,
      'price': product.price,
      'stock': product.stock,
      'qrCode': product.qrCode,
    };

    await _cacheData('product_$productId', newProduct);
    return Product.fromJson(newProduct);
  }

  Future<Product> updateProduct(Product product) async {
    // Mock product update
    final cachedProduct = _getCachedData('product_${product.id}');
    if (cachedProduct != null) {
      cachedProduct['name'] = product.name;
      cachedProduct['price'] = product.price;
      cachedProduct['stock'] = product.stock;
      cachedProduct['qrCode'] = product.qrCode;
      await _cacheData('product_${product.id}', cachedProduct);
      return Product.fromJson(cachedProduct);
    }

    throw Exception('Ürün bulunamadı');
  }

  Future<void> deleteProduct(String productId) async {
    // Mock product deletion
    await _cacheData('product_$productId', null);
  }

  Future<Product> getProductById(String productId) async {
    final cachedProduct = _getCachedData('product_$productId');
    if (cachedProduct != null) {
      return Product.fromJson(cachedProduct);
    }

    throw Exception('Ürün bulunamadı');
  }

  Future<Product> getProductByQrCode(String qrCode) async {
    // Mock product retrieval by QR code
    final mockProducts = [
      {
        'id': 'product1',
        'name': 'Su',
        'price': 5.0,
        'stock': 100,
        'qrCode': 'PRD001',
        'barcode': '8690123456789',
        'imageUrl': null,
      },
      {
        'id': 'product2',
        'name': 'Sandviç',
        'price': 25.0,
        'stock': 50,
        'qrCode': 'PRD002',
        'barcode': '8690123456790',
        'imageUrl': null,
      },
      {
        'id': 'product3',
        'name': 'Çikolata',
        'price': 12.5,
        'stock': 75,
        'qrCode': 'PRD003',
        'barcode': '8690123456791',
        'imageUrl': null,
      },
    ];

    final product = mockProducts.firstWhere((product) => product['qrCode'] == qrCode);
    return Product.fromJson(product);
  }

  // Transaction endpoints
  Future<List<Transaction>> getUserTransactions(String userId) async {
    // Mock transactions
    const mockTransactions = [
      {
        'id': 'transaction1',
        'userId': 'student1',
        'productId': 'product1',
        'amount': 10.0,
        'date': '2024-03-01T12:00:00.000Z',
      },
      {
        'id': 'transaction2',
        'userId': 'student1',
        'productId': 'product2',
        'amount': 20.0,
        'date': '2024-03-02T12:00:00.000Z',
      },
    ];

    final response = await http.get(
      Uri.parse('$baseUrl/transactions/student/$userId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> transactions = jsonDecode(response.body);
      return transactions.map((json) => Transaction.fromJson(json)).toList();
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'İşlemler alınamadı');
    }
  }

  Future<Transaction> createTransaction(Transaction transaction) async {
    // Mock transaction creation
    final transactionId = 'transaction${DateTime.now().millisecondsSinceEpoch}';
    final newTransaction = {
      'id': transactionId,
      'userId': transaction.userId,
      'productId': transaction.productId,
      'amount': transaction.amount,
      'date': transaction.date,
    };

    await _cacheData('transaction_$transactionId', newTransaction);
    return Transaction.fromJson(newTransaction);
  }

  // User endpoints
  Future<User> getUserProfile(String userId) async {
    final cachedUser = _getCachedData('user_$userId');
    if (cachedUser != null) {
      return User.fromJson(cachedUser);
    }

    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final userData = jsonDecode(response.body);
      await _cacheData('user_$userId', userData);
      return User.fromJson(userData);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Kullanıcı bilgileri alınamadı');
    }
  }

  Future<User> updateUserBalance(String userId, double amount) async {
    // Mock user balance update
    final cachedUser = _getCachedData('user_$userId');
    if (cachedUser != null) {
      cachedUser['balance'] = amount;
      await _cacheData('user_$userId', cachedUser);
      return User.fromJson(cachedUser);
    }

    throw Exception('Kullanıcı bulunamadı');
  }

  Future<User> getUser(String userId) async {
    final cachedUser = _getCachedData('user_$userId');
    if (cachedUser != null) {
      return User.fromJson(cachedUser);
    }

    throw Exception('Kullanıcı bulunamadı');
  }

  // Student Management endpoints
  Future<List<User>> getStudents() async {
    // Mock students
    const mockStudents = [
      {
        'id': 'student1',
        'name': 'Örnek Öğrenci',
        'email': 'ogrenci@kantin23.com',
        'studentId': '2024001',
        'role': 'student',
        'balance': 100.0,
      },
    ];

    final response = await http.get(
      Uri.parse('$baseUrl/students'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> students = jsonDecode(response.body);
      return students.map((json) => User.fromJson(json)).toList();
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Öğrenciler alınamadı');
    }
  }

  Future<User> createStudent(User student, {String? password}) async {
    // Mock student creation
    final studentId = 'student${DateTime.now().millisecondsSinceEpoch}';
    final newStudent = {
      'id': studentId,
      'name': student.name,
      'email': student.email,
      'studentId': student.studentId,
      'role': 'student',
      'balance': 0.0,
      'password': password ?? 'password123', // Varsayılan şifre
    };

    await _cacheData('student_$studentId', newStudent);
    await _cacheData('user_credentials_${student.email}', {
      'userId': studentId,
      'password': password ?? 'password123',
    });

    return User.fromJson(newStudent);
  }

  Future<User> updateStudent(User student) async {
    // Mock student update
    final cachedStudent = _getCachedData('student_${student.id}');
    if (cachedStudent != null) {
      cachedStudent['name'] = student.name;
      cachedStudent['email'] = student.email;
      cachedStudent['studentId'] = student.studentId;
      cachedStudent['role'] = student.role;
      cachedStudent['balance'] = student.balance;
      await _cacheData('student_${student.id}', cachedStudent);
      return User.fromJson(cachedStudent);
    }

    throw Exception('Öğrenci bulunamadı');
  }

  Future<void> deleteStudent(String studentId) async {
    // Mock student deletion
    await _cacheData('student_$studentId', null);
  }

  Future<User> addStudentBalance(String studentId, double amount) async {
    // Mock student balance addition
    final cachedStudent = _getCachedData('student_$studentId');
    if (cachedStudent != null) {
      cachedStudent['balance'] = (cachedStudent['balance'] as double) + amount;
      await _cacheData('student_$studentId', cachedStudent);
      return User.fromJson(cachedStudent);
    }

    throw Exception('Öğrenci bulunamadı');
  }

  // Payment endpoints
  Future<Transaction> processPayment({
    required String studentId,
    required String productId,
    required int quantity,
  }) async {
    // Mock payment processing
    final student = await getUser(studentId);
    final product = await getProductById(productId);

    if (student.balance < product.price * quantity) {
      throw Exception('Yetersiz bakiye');
    }

    if (product.stock < quantity) {
      throw Exception('Yetersiz stok');
    }

    final transactionId = 'transaction${DateTime.now().millisecondsSinceEpoch}';
    final newTransaction = {
      'id': transactionId,
      'userId': studentId,
      'productId': productId,
      'amount': product.price * quantity,
      'date': DateTime.now().toIso8601String(),
    };

    await _cacheData('transaction_$transactionId', newTransaction);
    await updateUserBalance(studentId, student.balance - product.price * quantity);
    await updateProduct(Product.fromJson({
      'id': productId,
      'name': product.name,
      'price': product.price,
      'stock': product.stock - quantity,
      'qrCode': product.qrCode,
    }));

    return Transaction.fromJson(newTransaction);
  }

  Future<List<Transaction>> getStudentTransactions(
    String studentId, {
    int page = 1,
    int limit = 20,
  }) async {
    // Mock student transactions
    const mockTransactions = [
      {
        'id': 'transaction1',
        'userId': 'student1',
        'productId': 'product1',
        'amount': 10.0,
        'date': '2024-03-01T12:00:00.000Z',
      },
      {
        'id': 'transaction2',
        'userId': 'student1',
        'productId': 'product2',
        'amount': 20.0,
        'date': '2024-03-02T12:00:00.000Z',
      },
    ];

    final response = await http.get(
      Uri.parse('$baseUrl/transactions/student/$studentId?page=$page&limit=$limit'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> transactions = jsonDecode(response.body);
      return transactions.map((json) => Transaction.fromJson(json)).toList();
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'İşlemler alınamadı');
    }
  }

  // Sales Report endpoints
  Future<Sales> getDailySales([DateTime? date]) async {
    // Mock daily sales
    const mockDailySales = {
      'date': '2024-03-01',
      'totalSales': 100.0,
      'totalProfit': 50.0,
    };

    final response = await http.get(
      Uri.parse('$baseUrl/sales/daily'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final salesData = jsonDecode(response.body);
      return Sales.fromJson(salesData);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Günlük satış raporu alınamadı');
    }
  }

  Future<Sales> getWeeklySales() async {
    // Mock weekly sales
    const mockWeeklySales = {
      'startDate': '2024-02-26',
      'endDate': '2024-03-04',
      'totalSales': 500.0,
      'totalProfit': 250.0,
    };

    final response = await http.get(
      Uri.parse('$baseUrl/sales/weekly'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final salesData = jsonDecode(response.body);
      return Sales.fromJson(salesData);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Haftalık satış raporu alınamadı');
    }
  }
}
