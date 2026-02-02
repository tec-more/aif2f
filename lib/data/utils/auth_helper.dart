import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../user/widgets/login_dialog.dart';
import '../providers/auth_provider.dart';

/// 登录检查辅助函数
///
/// 检查用户是否已登录，如果未登录则显示登录对话框
/// 返回 true 表示已登录，false 表示未登录
Future<bool> checkLogin(BuildContext context, WidgetRef ref) async {
  final authState = ref.read(authProvider);

  // 如果已登录，直接返回
  if (authState.isAuthenticated) {
    return true;
  }

  // 未登录，显示登录对话框
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const LoginDialog(),
  );

  return result ?? false;
}

/// 显示登录提示并导航到登录页
void showLoginPrompt(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const LoginDialog(),
  );
}

/// 检查是否已登录的简单版本（用于快速判断）
bool isUserLoggedIn(WidgetRef ref) {
  final authState = ref.read(authProvider);
  return authState.isAuthenticated;
}
