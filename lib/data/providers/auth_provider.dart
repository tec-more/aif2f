import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aif2f/data/models/user_model.dart';
import 'package:aif2f/data/services/auth_service.dart';
import 'package:aif2f/data/services/api_client.dart';
import 'package:aif2f/data/services/token_storage_service.dart';

/// API Client Provider
final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient();
  client.init();
  return client;
});

/// Auth Service Provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Token Storage Service Provider
final tokenStorageServiceProvider = Provider<TokenStorageService>((ref) {
  return TokenStorageService();
});

/// 认证状态
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// 认证状态类
class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated;
}

/// 认证 Notifier
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // 不在 build() 中初始化，而是提供单独的初始化方法
    return AuthState(status: AuthStatus.initial);
  }

  AuthService get _authService => ref.read(authServiceProvider);
  ApiClient get _apiClient => ref.read(apiClientProvider);
  TokenStorageService get _tokenStorage => ref.read(tokenStorageServiceProvider);

  /// 初始化认证状态（应用启动时调用）
  Future<void> initializeAuth() async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      final token = await _tokenStorage.getToken();
      if (token != null && token.isNotEmpty) {
        // 有保存的 Token，设置到 API Client
        _apiClient.setToken(token);

        // 尝试获取用户信息
        try {
          final user = await _authService.getCurrentUser();
          state = AuthState(
            status: AuthStatus.authenticated,
            user: user,
          );
          if (kDebugMode) {
            print('✅ Auto-login successful for user: ${user.username}');
          }
        } catch (e) {
          // Token 无效，清除本地数据
          await _tokenStorage.clearAll();
          _apiClient.clearToken();
          state = AuthState(status: AuthStatus.unauthenticated);
          if (kDebugMode) {
            print('⚠️ Saved token invalid, cleared');
          }
        }
      } else {
        state = AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing auth: $e');
      }
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// 用户登录
  Future<bool> login(String username, String password) async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      final request = LoginRequest(username: username, password: password);
      final response = await _authService.login(request);

      // 保存 Token 到本地
      await _tokenStorage.saveToken(response.accessToken);
      await _tokenStorage.saveUserInfo(response.user.id, response.user.username);

      // 设置到 API Client
      _apiClient.setToken(response.accessToken);

      // 更新状态
      state = AuthState(
        status: AuthStatus.authenticated,
        user: response.user,
      );

      return true;
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// 用户注册
  Future<bool> register(String username, String email, String password,
      {String? nickname, String? phone}) async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      final request = RegisterRequest(
        username: username,
        email: email,
        password: password,
        nickname: nickname,
        phone: phone,
      );
      final response = await _authService.register(request);

      // 保存 Token 到本地
      await _tokenStorage.saveToken(response.accessToken);
      await _tokenStorage.saveUserInfo(response.user.id, response.user.username);

      // 设置到 API Client
      _apiClient.setToken(response.accessToken);

      // 更新状态
      state = AuthState(
        status: AuthStatus.authenticated,
        user: response.user,
      );

      return true;
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// 获取当前用户信息
  Future<void> fetchCurrentUser() async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      final user = await _authService.getCurrentUser();
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// 修改密码
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      final request = ChangePasswordRequest(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      await _authService.changePassword(request);
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// 用户登出
  Future<void> logout() async {
    try {
      await _authService.logout();
    } catch (e) {
      // 即使登出失败也清除本地状态
    } finally {
      // 清除 API Client 的 Token
      _apiClient.clearToken();
      // 清除本地存储的 Token 和用户信息
      await _tokenStorage.clearAll();
      // 更新状态
      state = AuthState(status: AuthStatus.unauthenticated);
      if (kDebugMode) {
        print('🚪 Logged out and cleared all auth data');
      }
    }
  }

  /// 清除错误信息
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Auth State Provider
final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
