import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/user_model.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Token Operations
  static Future<void> saveToken(String token) async {
    await init();
    await _prefs!.setString(AppConfig.tokenKey, token);
  }

  static String? getToken() {
    return _prefs?.getString(AppConfig.tokenKey);
  }

  static Future<void> removeToken() async {
    await init();
    await _prefs!.remove(AppConfig.tokenKey);
  }

  // User Operations
  static Future<void> saveUser(UserModel user) async {
    await init();
    final jsonStr = jsonEncode(user.toJson());
    await _prefs!.setString(AppConfig.userKey, jsonStr);
  }

  static UserModel? getUser() {
    final jsonStr = _prefs?.getString(AppConfig.userKey);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final Map<String, dynamic> jsonMap = jsonDecode(jsonStr);
      return UserModel.fromJson(jsonMap);
    } catch (_) {
      return null;
    }
  }

  static Future<void> removeUser() async {
    await init();
    await _prefs!.remove(AppConfig.userKey);
  }

  // Clear Session
  static Future<void> clearSession() async {
    await init();
    await _prefs!.remove(AppConfig.tokenKey);
    await _prefs!.remove(AppConfig.userKey);
  }
}
