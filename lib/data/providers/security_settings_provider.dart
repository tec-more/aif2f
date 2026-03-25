import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 安全设置状态
class SecuritySettingsState {
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final String? email;
  final String? phone;
  final bool isLoading;
  final String? errorMessage;

  const SecuritySettingsState({
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.email,
    this.phone,
    this.isLoading = false,
    this.errorMessage,
  });

  SecuritySettingsState copyWith({
    bool? isEmailVerified,
    bool? isPhoneVerified,
    String? email,
    String? phone,
    bool? isLoading,
    String? errorMessage,
  }) {
    return SecuritySettingsState(
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// 安全设置 Notifier
class SecuritySettingsNotifier extends Notifier<SecuritySettingsState> {
  @override
  SecuritySettingsState build() {
    return const SecuritySettingsState();
  }

  /// 加载安全设置
  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true);
    try {
      // TODO: 从后端加载用户安全设置
      // 这里是示例代码
      await Future.delayed(const Duration(seconds: 1));
      state = state.copyWith(
        isEmailVerified: false,
        isPhoneVerified: false,
        email: null,
        phone: null,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// 绑定邮箱
  Future<bool> bindEmail(String email, String code) async {
    state = state.copyWith(isLoading: true);
    try {
      // TODO: 调用后端 API 绑定邮箱
      await Future.delayed(const Duration(seconds: 1));
      
      state = state.copyWith(
        isEmailVerified: true,
        email: email,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// 解绑邮箱
  Future<bool> unbindEmail() async {
    state = state.copyWith(isLoading: true);
    try {
      // TODO: 调用后端 API 解绑邮箱
      await Future.delayed(const Duration(seconds: 1));
      
      state = state.copyWith(
        isEmailVerified: false,
        email: null,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// 绑定手机号
  Future<bool> bindPhone(String phone, String code) async {
    state = state.copyWith(isLoading: true);
    try {
      // TODO: 调用后端 API 绑定手机号
      await Future.delayed(const Duration(seconds: 1));
      
      state = state.copyWith(
        isPhoneVerified: true,
        phone: phone,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// 解绑手机号
  Future<bool> unbindPhone() async {
    state = state.copyWith(isLoading: true);
    try {
      // TODO: 调用后端 API 解绑手机号
      await Future.delayed(const Duration(seconds: 1));
      
      state = state.copyWith(
        isPhoneVerified: false,
        phone: null,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// 发送邮箱验证码
  Future<bool> sendEmailCode(String email) async {
    try {
      // TODO: 调用后端 API 发送邮箱验证码
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  /// 发送手机验证码
  Future<bool> sendPhoneCode(String phone) async {
    try {
      // TODO: 调用后端 API 发送手机验证码
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  /// 清除错误信息
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// 重置状态
  void reset() {
    state = const SecuritySettingsState();
  }
}

/// 安全设置 Provider
final securitySettingsProvider =
    NotifierProvider<SecuritySettingsNotifier, SecuritySettingsState>(
  SecuritySettingsNotifier.new,
);
