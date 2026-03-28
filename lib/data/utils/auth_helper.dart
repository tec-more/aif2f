import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aif2f/user/widgets/login_dialog.dart';
import 'package:aif2f/data/providers/auth_provider.dart';
import 'package:aif2f/data/providers/membership_provider.dart';
import 'package:aif2f/core/models/fibonacci_membership.dart';

/// 登录检查辅助函数
///
/// 检查用户是否已登录，如果未登录则显示登录对话框
/// 返回 true 表示已登录，false 表示未登录
Future<bool> checkLogin(BuildContext context, WidgetRef ref) async {
  final authState = ref.read(authProvider);

  if (kDebugMode) {
    print('🔍 [checkLogin] 检查登录状态');
    print('📊 [checkLogin] isAuthenticated: ${authState.isAuthenticated}');
    print('📊 [checkLogin] status: ${authState.status}');
  }

  // 如果已登录，直接返回
  if (authState.isAuthenticated) {
    if (kDebugMode) print('✅ [checkLogin] 用户已登录，返回 true');
    return true;
  }

  if (kDebugMode) print('❌ [checkLogin] 用户未登录，显示登录对话框');

  // 未登录，显示登录对话框
  try {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        if (kDebugMode) print('🔐 [checkLogin] 构建 LoginDialog');
        return const LoginDialog();
      },
    );

    // 如果登录成功，初始化会员信息
    if (result == true) {
      if (kDebugMode) print('🎉 [checkLogin] 登录成功，初始化会员信息');
      // 检查 context 是否仍然 mounted，避免在 widget unmount 后使用 ref
      if (context.mounted) {
        final newAuthState = ref.read(authProvider);
        final user = newAuthState.user;
        if (user != null) {
          final membershipInfo = FibonacciMembershipInfo(
            totalHours: user.totalHours,
            startDate: user.createdAt,
          );
          ref.read(membershipProvider.notifier).state = 
            ref.read(membershipProvider).copyWith(membershipInfo: membershipInfo);
          if (kDebugMode) print('✅ [checkLogin] 会员信息初始化完成：$membershipInfo');
        }
      }
    }

    if (kDebugMode) print('📤 [checkLogin] 登录对话框结果：$result');
    return result ?? false;
  } catch (e) {
    if (kDebugMode) {
      print('❌ [checkLogin] 显示登录对话框失败: $e');
      print('❌ [checkLogin] 错误堆栈: ${StackTrace.current}');
    }
    return false;
  }
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
