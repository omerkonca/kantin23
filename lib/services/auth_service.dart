import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  User? _currentUser;
  String? _token;
  late ApiService _apiService;
  late SharedPreferences _prefs;

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.role == 'admin';

  AuthService() {
    _initPrefs();
    _initApiService();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _token = _prefs.getString('auth_token');
    if (_token != null) {
      _apiService = await ApiService.create(authToken: _token);
      try {
        _currentUser = await _apiService.getUserProfile(_token!);
        notifyListeners();
      } catch (e) {
        // Token might be invalid, clear it
        await logout();
      }
    }
  }

  Future<void> _initApiService() async {
    if (_token != null) {
      _apiService = await ApiService.create(authToken: _token);
    } else {
      _apiService = await ApiService.create(authToken: null);
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      debugPrint('AuthService: Initializing API service...');
      _apiService = await ApiService.create(authToken: null);
      
      debugPrint('AuthService: Calling login...');
      final result = await _apiService.login(email, password);
      
      debugPrint('AuthService: Login successful, saving token...');
      _token = result['token'] as String;
      await _prefs.setString('auth_token', _token!);
      
      debugPrint('AuthService: Reinitializing API service with token...');
      _apiService = await ApiService.create(authToken: _token);
      
      debugPrint('AuthService: Setting current user...');
      _currentUser = result['user'] as User;
      
      debugPrint('AuthService: Login complete');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('AuthService Error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      _currentUser = null;
      _token = null;
      await _prefs.clear(); // Tüm önbelleği temizle
      _apiService = await ApiService.create(authToken: null);
      notifyListeners();
    } catch (e) {
      debugPrint('Çıkış yaparken hata: $e');
      rethrow;
    }
  }

  Future<void> updateUserProfile() async {
    if (_currentUser != null) {
      try {
        final updatedUser = await _apiService.getUserProfile(_currentUser!.id);
        _currentUser = updatedUser;
        notifyListeners();
      } catch (e) {
        // Handle error
      }
    }
  }
}
