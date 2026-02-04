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

  /// 用户登录（使用邮箱）
  Future<bool> login(String emailOrUsername, String password) async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      // 判断输入的是邮箱还是用户名
      final isEmail = emailOrUsername.contains('@');

      if (isEmail) {
        // 使用 customer 登录（邮箱）
        final request = CustomerLogin(email: emailOrUsername, password: password);
        final response = await _authService.customerLogin(request);

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
      } else {
        // 使用旧接口登录（用户名）
        final request = LoginRequest(username: emailOrUsername, password: password);
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
      }
    } catch (e) {
      // 清理错误信息，移除技术性前缀和符号
      String errorMsg = e.toString();
      errorMsg = errorMsg.replaceAll('Exception: ', '');
      errorMsg = errorMsg.replaceAll('Error: ', '');
      errorMsg = errorMsg.replaceAll(RegExp(r'_dio@\w+:\s*'), '');
      errorMsg = errorMsg.replaceAll(RegExp(r'DioException:\s*'), '');
      errorMsg = errorMsg.replaceAll(RegExp(r'dio:\s*'), '');
      errorMsg = errorMsg.replaceAll(RegExp(r'^Instance of\s+'), '');
      errorMsg = errorMsg.replaceAll(RegExp(r'^\s*>\s*'), '');
      errorMsg = errorMsg.replaceAll(RegExp(r'^>\s*'), '');
      errorMsg = errorMsg.replaceAll('\n', ' ');
      errorMsg = errorMsg.replaceAll(RegExp(r'\s+'), ' ');
      errorMsg = errorMsg.trim();

      state = AuthState(
        status: AuthStatus.error,
        errorMessage: errorMsg.isNotEmpty ? errorMsg : '操作失败，请稍后重试',
      );
      return false;
    }
  }

  /// 用户验证码登录
  Future<bool> loginWithCode(String email, String code) async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      final request = CustomerLoginCode(email: email, code: code);
      final response = await _authService.customerLoginCode(request);

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
      // 清理错误信息，移除技术性前缀和符号
      String errorMsg = e.toString();
      errorMsg = errorMsg.replaceAll('Exception: ', '');
      errorMsg = errorMsg.replaceAll('Error: ', '');
      errorMsg = errorMsg.replaceAll(RegExp(r'_dio@\w+:\s*'), '');
      errorMsg = errorMsg.replaceAll(RegExp(r'DioException:\s*'), '');
      errorMsg = errorMsg.replaceAll(RegExp(r'dio:\s*'), '');
      errorMsg = errorMsg.replaceAll(RegExp(r'^Instance of\s+'), '');
      errorMsg = errorMsg.replaceAll(RegExp(r'^\s*>\s*'), '');
      errorMsg = errorMsg.replaceAll(RegExp(r'^>\s*'), '');
      errorMsg = errorMsg.replaceAll('\n', ' ');
      errorMsg = errorMsg.replaceAll(RegExp(r'\s+'), ' ');
      errorMsg = errorMsg.trim();

      state = AuthState(
        status: AuthStatus.error,
        errorMessage: errorMsg.isNotEmpty ? errorMsg : '操作失败，请稍后重试',
      );
      return false;
    }
  }

  /// 用户注册
  Future<bool> register(String username, String email, String password, String code,
      {String? nickname, String? phone}) async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      if (kDebugMode) {
        print('🔄 [AuthProvider] 开始注册流程');
        print('📧 [AuthProvider] 邮箱: $email');
        print('👤 [AuthProvider] 用户名: $username');
      }

      final request = RegisterRequest(
        username: username,
        email: email,
        password: password,
        code: code,
        nickname: nickname,
        phone: phone,
      );

      if (kDebugMode) {
        print('📦 [AuthProvider] 创建注册请求完成');
      }

      final response = await _authService.register(request);

      if (kDebugMode) {
        print('✅ [AuthProvider] AuthService.register() 成功返回');
        print('🎫 [AuthProvider] Access Token: ${response.accessToken.substring(0, 20)}...');
        print('👤 [AuthProvider] User ID: ${response.user.id}, Username: ${response.user.username}');
      }

      // 保存 Token 到本地
      if (kDebugMode) {
        print('💾 [AuthProvider] 开始保存 Token...');
      }
      await _tokenStorage.saveToken(response.accessToken);
      if (kDebugMode) {
        print('✅ [AuthProvider] Token 保存完成');
      }

      // 保存用户信息
      if (kDebugMode) {
        print('💾 [AuthProvider] 开始保存用户信息...');
      }
      await _tokenStorage.saveUserInfo(response.user.id, response.user.username);
      if (kDebugMode) {
        print('✅ [AuthProvider] 用户信息保存完成');
      }

      // 设置到 API Client
      if (kDebugMode) {
        print('🔧 [AuthProvider] 设置 Token 到 API Client...');
      }
      _apiClient.setToken(response.accessToken);
      if (kDebugMode) {
        print('✅ [AuthProvider] API Client Token 设置完成');
      }

      // 更新状态
      if (kDebugMode) {
        print('🔄 [AuthProvider] 更新认证状态为 authenticated...');
      }
      state = AuthState(
        status: AuthStatus.authenticated,
        user: response.user,
      );
      if (kDebugMode) {
        print('✅ [AuthProvider] 状态更新完成');
        print('🎉 [AuthProvider] 注册流程完全成功，准备返回 true');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AuthProvider] 注册流程失败');
        print('❌ [AuthProvider] 错误类型: ${e.runtimeType}');
        print('❌ [AuthProvider] 错误信息: ${e.toString()}');
        print('❌ [AuthProvider] 错误堆栈: ${StackTrace.current}');
      }

      // 清理错误信息，移除技术性前缀和符号
      String errorMsg = e.toString();
      errorMsg = errorMsg.replaceAll('Exception: ', '');
      errorMsg = errorMsg.replaceAll('Error: ', '');
      errorMsg = errorMsg.replaceAll(RegExp(r'_dio@\w+:\s*'), '');
      errorMsg = errorMsg.replaceAll(RegExp(r'DioException:\s*'), '');
      errorMsg = errorMsg.replaceAll(RegExp(r'dio:\s*'), '');
      errorMsg = errorMsg.replaceAll(RegExp(r'^Instance of\s+'), '');
      errorMsg = errorMsg.replaceAll(RegExp(r'^\s*>\s*'), '');
      errorMsg = errorMsg.replaceAll(RegExp(r'^>\s*'), '');
      errorMsg = errorMsg.replaceAll('\n', ' ');
      errorMsg = errorMsg.replaceAll(RegExp(r'\s+'), ' ');
      errorMsg = errorMsg.trim();

      if (kDebugMode) {
        print('❌ [AuthProvider] 清理后的错误信息: $errorMsg');
      }

      state = AuthState(
        status: AuthStatus.error,
        errorMessage: errorMsg.isNotEmpty ? errorMsg : '操作失败，请稍后重试',
      );
      if (kDebugMode) {
        print('❌ [AuthProvider] 已更新状态为 error，准备返回 false');
      }
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

  /// 重置为未认证状态（用于解决卡在 loading 状态的问题）
  void resetToUnauthenticated() {
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}

/// Auth State Provider
final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
