import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aif2f/data/providers/auth_provider.dart';

/// 设置状态类
class SettingsState {
  final bool emailVerified;
  final bool phoneVerified;
  final bool notificationsEnabled;
  final String language;
  final String theme;

  const SettingsState({
    this.emailVerified = false,
    this.phoneVerified = false,
    this.notificationsEnabled = true,
    this.language = 'zh-CN',
    this.theme = 'system',
  });

  SettingsState copyWith({
    bool? emailVerified,
    bool? phoneVerified,
    bool? notificationsEnabled,
    String? language,
    String? theme,
  }) {
    return SettingsState(
      emailVerified: emailVerified ?? this.emailVerified,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      language: language ?? this.language,
      theme: theme ?? this.theme,
    );
  }
}

/// 设置 Notifier
class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    return const SettingsState();
  }

  /// 设置邮箱验证状态
  void setEmailVerified(bool verified) {
    state = state.copyWith(emailVerified: verified);
  }

  /// 设置手机验证状态
  void setPhoneVerified(bool verified) {
    state = state.copyWith(phoneVerified: verified);
  }

  /// 设置通知开关
  void setNotificationsEnabled(bool enabled) {
    state = state.copyWith(notificationsEnabled: enabled);
  }

  /// 设置语言
  void setLanguage(String language) {
    state = state.copyWith(language: language);
  }

  /// 设置主题
  void setTheme(String theme) {
    state = state.copyWith(theme: theme);
  }

  /// 加载用户设置
  Future<void> loadSettings() async {
    // TODO: 从后端加载用户设置
    // 这里仅作为示例
  }

  /// 保存设置
  Future<void> saveSettings() async {
    // TODO: 保存设置到后端
  }
}

/// 设置 Provider
final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);
