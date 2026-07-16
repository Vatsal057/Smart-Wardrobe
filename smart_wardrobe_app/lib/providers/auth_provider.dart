import 'package:flutter/material.dart';
import '../services/api.dart';

/// Auth state management using ChangeNotifier.
class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get user => _user;
  bool get isLoggedIn => ApiService.isLoggedIn && _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get userName => _user?['name'] ?? 'User';
  String get userCity => _user?['city'] ?? 'Mumbai';

  Future<void> init() async {
    await ApiService.init();
    if (ApiService.isLoggedIn) {
      await fetchUser();
    }
  }

  Future<bool> login(String username, {String? name}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiService.login(username, name: name);
      _user = data['user'];
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchUser() async {
    try {
      _user = await ApiService.getMe();
      notifyListeners();
    } catch (e) {
      _user = null;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateUser(Map<String, dynamic> fields) async {
    try {
      _user = await ApiService.updateMe(fields);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await ApiService.logout();
    _user = null;
    notifyListeners();
  }
}
