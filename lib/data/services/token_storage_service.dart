import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Token 存储服务
/// 负责将认证 token 持久化到本地存储
class TokenStorageService {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _usernameKey = 'username';

  /// 保存 Token
  Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      if (kDebugMode) {
        print('✅ Token saved successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving token: $e');
      }
    }
  }

  /// 保存用户信息
  Future<void> saveUserInfo(int userId, String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_userIdKey, userId);
      await prefs.setString(_usernameKey, username);
      if (kDebugMode) {
        print('✅ User info saved: userId=$userId, username=$username');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving user info: $e');
      }
    }
  }

  /// 获取 Token
  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      if (kDebugMode) {
        print('📖 Token retrieved: ${token != null ? 'found' : 'not found'}');
      }
      return token;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting token: $e');
      }
      return null;
    }
  }

  /// 获取用户ID
  Future<int?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_userIdKey);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting user id: $e');
      }
      return null;
    }
  }

  /// 获取用户名
  Future<String?> getUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_usernameKey);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting username: $e');
      }
      return null;
    }
  }

  /// 清除所有认证信息
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userIdKey);
      await prefs.remove(_usernameKey);
      if (kDebugMode) {
        print('🗑️ All auth data cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error clearing auth data: $e');
      }
    }
  }

  /// 检查是否有已保存的 Token
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
