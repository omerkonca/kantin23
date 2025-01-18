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
      _apiService = await ApiService.create(authToken: null);
      final user = await _apiService.login(email, password);
      _token = user.id; // Assuming the token is the user ID for now
      await _prefs.setString('auth_token', _token!);
      
      // Initialize API service with the new token
      _apiService = await ApiService.create(authToken: _token);
      
      // Fetch user profile
      _currentUser = await _apiService.getUserProfile(_token!);
      
      notifyListeners();
      return true;
    } catch (e) {
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
