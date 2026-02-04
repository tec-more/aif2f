import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import 'package:aif2f/data/providers/auth_provider.dart';
import 'package:aif2f/core/router/app_router.dart';

/// 需要登录才能访问的页面包装组件
/// 如果用户未登录，自动跳转到登录页面
class AuthRequired extends ConsumerWidget {
  final Widget child;

  const AuthRequired({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // 检查用户是否已登录
    if (!authState.isAuthenticated) {
      // 延迟跳转，避免在 build 方法中直接导航
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // 跳转到登录页
        context.router.push(const LoginRoute());
      });

      // 显示加载指示器
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 已登录，显示子组件
    return child;
  }
}

/// 需要登录才能访问的页面包装组件（带自定义加载页面）
class AuthRequiredWithLoader extends ConsumerWidget {
  final Widget child;
  final Widget? loadingWidget;

  const AuthRequiredWithLoader({
    super.key,
    required this.child,
    this.loadingWidget,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // 检查用户是否已登录
    if (!authState.isAuthenticated) {
      // 延迟跳转，避免在 build 方法中直接导航
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // 跳转到登录页
        context.router.push(const LoginRoute());
      });

      // 显示加载页面或默认加载指示器
      return loadingWidget ??
          const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('请先登录'),
                ],
              ),
            ),
          );
    }

    // 已登录，显示子组件
    return child;
  }
}
