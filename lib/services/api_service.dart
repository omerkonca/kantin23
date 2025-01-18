import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/product.dart';
import '../models/sales.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';

class ApiService {
  final String baseUrl;
  final String authToken;
  final SharedPreferences prefs;

  ApiService._({
    required this.baseUrl,
    required this.authToken,
    required this.prefs,
  });

  static Future<ApiService> create({String? authToken}) async {
    final prefs = await SharedPreferences.getInstance();
    return ApiService._(
      baseUrl: 'https://api.kantin23.com',
      authToken: authToken ?? prefs.getString('auth_token') ?? '',
      prefs: prefs,
    );
  }

  // Cache operations
  Future<void> _cacheData(String key, Map<String, dynamic> data) async {
    await prefs.setString(key, json.encode(data));
  }

  Map<String, dynamic>? _getCachedData(String key) {
    final data = prefs.getString(key);
    if (data != null) {
      return json.decode(data) as Map<String, dynamic>;
    }
    return null;
  }

  List<Map<String, dynamic>>? _getCachedList(String key) {
    final data = prefs.getString(key);
    if (data != null) {
      return (json.decode(data) as List).cast<Map<String, dynamic>>();
    }
    return null;
  }

  Future<void> _cacheList(String key, List<Map<String, dynamic>> data) async {
    await prefs.setString(key, json.encode(data));
  }

  // Auth operations
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      debugPrint('Login attempt - Email: $email');
      // For development, use mock users
      final mockUsers = {
        'admin@kantin23.com': {
          'id': 'admin1',
          'name': 'Admin',
          'email': 'admin@kantin23.com',
          'role': 'admin',
          'studentId': null,
          'balance': 0.0,
          'password': 'admin123',
          'token': 'admin_token_123',
        },
        'ogrenci@kantin23.com': {
          'id': 'student1',
          'name': 'Test Student',
          'email': 'ogrenci@kantin23.com',
          'role': 'student',
          'studentId': '2024001',
          'balance': 100.0,
          'password': 'ogrenci123',
          'token': 'student_token_123',
        },
      };

      debugPrint('Mock users: ${mockUsers.keys.join(', ')}');
      debugPrint('Checking credentials...');

      if (mockUsers.containsKey(email)) {
        debugPrint('Email found');
        if (mockUsers[email]!['password'] == password) {
          debugPrint('Password matches');
          final userData = Map<String, dynamic>.from(mockUsers[email]!);
          final token = userData['token'];
          userData.remove('password');
          userData.remove('token');
          
          debugPrint('Caching user data...');
          await _cacheData('user_${userData['id']}', userData);
          
          debugPrint('Login successful');
          return {
            'user': User.fromJson(userData),
            'token': token,
          };
        } else {
          debugPrint('Password does not match');
        }
      } else {
        debugPrint('Email not found');
      }

      throw Exception('Geçersiz e-posta veya şifre');
    } catch (e) {
      debugPrint('Login error: $e');
      throw Exception('Giriş yapılırken hata oluştu: $e');
    }
  }

  Future<User> getUserProfile(String userId) async {
    try {
      // Try to get from cache first
      final cachedUser = _getCachedData('user_$userId');
      if (cachedUser != null) {
        return User.fromJson(cachedUser);
      }

      // For development, return mock user
      final mockUser = {
        'id': userId,
        'name': 'Test User',
        'email': 'test@kantin23.com',
        'role': 'student',
        'studentId': '2024001',
        'balance': 100.0,
      };

      await _cacheData('user_$userId', mockUser);
      return User.fromJson(mockUser);
    } catch (e) {
      throw Exception('Kullanıcı profili alınırken hata oluştu: $e');
    }
  }

  // Product operations
  Future<List<Product>> getProducts() async {
    try {
      // Try to get products from cache first
      final cachedProducts = _getCachedList('products');
      if (cachedProducts != null) {
        return cachedProducts.map((p) => Product.fromJson(p)).toList();
      }

      // If no cached products, return default products
      final defaultProducts = [
        Product(
          id: '1',
          name: 'Su',
          price: 5.0,
          stock: 100,
          qrCode: 'PRD001',
          imageUrl: 'https://example.com/images/water.jpg',
        ),
        Product(
          id: '2',
          name: 'Tost',
          price: 15.0,
          stock: 50,
          qrCode: 'PRD002',
          imageUrl: 'https://example.com/images/toast.jpg',
        ),
      ];

      // Cache the default products
      await _cacheList(
        'products',
        defaultProducts.map((p) => p.toJson()).toList(),
      );

      return defaultProducts;
    } catch (e) {
      throw Exception('Ürünler yüklenirken hata oluştu: $e');
    }
  }

  Future<Product> createProduct(Product product) async {
    try {
      // Get existing products
      List<Product> products = await getProducts();
      
      // Generate a new ID
      final newId = (products.length + 1).toString();
      final newProduct = product.copyWith(id: newId);
      
      // Add to products list
      products.add(newProduct);
      
      // Update cache
      await _cacheList(
        'products',
        products.map((p) => p.toJson()).toList(),
      );

      return newProduct;
    } catch (e) {
      throw Exception('Ürün oluşturulurken hata oluştu: $e');
    }
  }

  Future<Product> updateProduct(Product product) async {
    try {
      // Get existing products
      List<Product> products = await getProducts();
      
      // Find product index
      final index = products.indexWhere((p) => p.id == product.id);
      if (index == -1) {
        throw Exception('Ürün bulunamadı');
      }
      
      // Update product
      products[index] = product;
      
      // Update cache
      await _cacheList(
        'products',
        products.map((p) => p.toJson()).toList(),
      );

      return product;
    } catch (e) {
      throw Exception('Ürün güncellenirken hata oluştu: $e');
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      // Get existing products
      List<Product> products = await getProducts();
      
      // Remove product
      products.removeWhere((p) => p.id == productId);
      
      // Update cache
      await _cacheList(
        'products',
        products.map((p) => p.toJson()).toList(),
      );
    } catch (e) {
      throw Exception('Ürün silinirken hata oluştu: $e');
    }
  }

  Future<String> uploadProductImage(File imageFile) async {
    try {
      // Convert image file to base64
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      // Create multipart request
      final uri = Uri.parse('$baseUrl/upload-image');
      final request = http.MultipartRequest('POST', uri);
      
      // Add authorization header
      request.headers['Authorization'] = 'Bearer $authToken';
      
      // Add file
      final multipartFile = await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(multipartFile);

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['imageUrl'] as String;
      } else {
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      // For now, simulate successful upload with a dummy URL
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return 'https://storage.googleapis.com/kantin23/products/$timestamp.jpg';
    }
  }

  // Student operations
  Future<List<Transaction>> getStudentTransactions(String studentId) async {
    try {
      // Mock transactions
      final mockTransactions = [
        {
          'id': '1',
          'studentId': studentId,
          'productId': 'product1',
          'productName': 'Sandviç',
          'amount': 15.0,
          'timestamp': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        },
        {
          'id': '2',
          'studentId': studentId,
          'productId': 'product2',
          'productName': 'Su',
          'amount': 5.0,
          'timestamp': DateTime.now().toIso8601String(),
        },
      ];

      return mockTransactions.map((t) => Transaction.fromJson(t)).toList();
    } catch (e) {
      throw Exception('İşlemler alınırken hata oluştu: $e');
    }
  }

  Future<Transaction> processPayment(String studentId, String productId, double amount) async {
    try {
      // Mock payment process
      final mockTransaction = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'studentId': studentId,
        'productId': productId,
        'productName': 'Test Ürün',
        'amount': amount,
        'timestamp': DateTime.now().toIso8601String(),
      };

      return Transaction.fromJson(mockTransaction);
    } catch (e) {
      throw Exception('Ödeme işlemi başarısız: $e');
    }
  }

  Future<Product> getProductByQrCode(String qrCode) async {
    try {
      // Mock product data
      final mockProduct = {
        'id': 'product1',
        'name': 'Test Ürün',
        'price': 10.0,
        'qrCode': qrCode,
        'description': 'Test açıklama',
        'imageUrl': null,
      };

      return Product.fromJson(mockProduct);
    } catch (e) {
      throw Exception('Ürün bulunamadı: $e');
    }
  }

  // Admin operations
  Future<void> createStudent(Map<String, dynamic> student) async {
    try {
      // Mock student creation
      await Future.delayed(const Duration(seconds: 1));
    } catch (e) {
      throw Exception('Öğrenci oluşturulurken hata: $e');
    }
  }

  Future<void> updateStudent(Map<String, dynamic> student) async {
    try {
      // Mock student update
      await Future.delayed(const Duration(seconds: 1));
    } catch (e) {
      throw Exception('Öğrenci güncellenirken hata: $e');
    }
  }

  Future<Map<String, dynamic>> getDailySales(DateTime date) async {
    try {
      // Mock daily sales data
      return {
        'totalSales': 1500.0,
        'transactionCount': 45,
        'topProducts': [
          {'name': 'Sandviç', 'count': 20, 'total': 300.0},
          {'name': 'Su', 'count': 15, 'total': 75.0},
          {'name': 'Çay', 'count': 10, 'total': 50.0},
        ],
      };
    } catch (e) {
      throw Exception('Günlük satış raporu alınamadı: $e');
    }
  }

  Future<Map<String, dynamic>> getWeeklySales() async {
    try {
      // Mock weekly sales data
      return {
        'totalSales': 8500.0,
        'transactionCount': 320,
        'dailyBreakdown': [
          {'date': '2024-01-12', 'total': 1200.0, 'count': 45},
          {'date': '2024-01-13', 'total': 1500.0, 'count': 50},
          {'date': '2024-01-14', 'total': 1300.0, 'count': 48},
          {'date': '2024-01-15', 'total': 1100.0, 'count': 42},
          {'date': '2024-01-16', 'total': 1400.0, 'count': 47},
          {'date': '2024-01-17', 'total': 1000.0, 'count': 40},
          {'date': '2024-01-18', 'total': 1000.0, 'count': 48},
        ],
        'topProducts': [
          {'name': 'Sandviç', 'count': 150, 'total': 2250.0},
          {'name': 'Su', 'count': 100, 'total': 500.0},
          {'name': 'Çay', 'count': 70, 'total': 350.0},
        ],
      };
    } catch (e) {
      throw Exception('Haftalık satış raporu alınamadı: $e');
    }
  }
}
