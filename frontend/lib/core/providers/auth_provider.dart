import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/storage_service.dart';
import '../services/api_client.dart';

enum AuthStatus { uninitialized, authenticated, unauthenticated, loading }

class AuthProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  AuthStatus _status = AuthStatus.uninitialized;
  UserModel? _user;
  String? _token;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get token => _token;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated && _token != null;

  // Role Detection Helpers
  bool get isHR => _user?.role == 'HR';
  bool get isManager => _user?.role == 'MANAGER';
  bool get isEmployee => _user?.role == 'EMPLOYEE';

  AuthProvider() {
    restoreSession();
  }

  /// Restore user session from SharedPreferences on app initialization
  Future<void> restoreSession() async {
    _status = AuthStatus.loading;
    notifyListeners();

    await StorageService.init();
    _token = StorageService.getToken();
    _user = StorageService.getUser();

    if (_token != null && _token!.isNotEmpty && _user != null) {
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  /// User Login Flow (Email and Password only; Company context resolved automatically)
  Future<bool> login(String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        final payload = response.data['data'];
        _token = payload['token'];
        _user = UserModel.fromJson(payload['user']);

        // Persist session to disk
        await StorageService.saveToken(_token!);
        await StorageService.saveUser(_user!);

        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.data['message'] ?? 'Login failed.';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  /// User Logout Flow
  Future<void> logout() async {
    try {
      await _apiClient.post('/auth/logout');
    } catch (_) {
      // Ignore API network failure on logout
    } finally {
      await StorageService.clearSession();
      _token = null;
      _user = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }
}
