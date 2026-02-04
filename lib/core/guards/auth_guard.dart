import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aif2f/data/providers/auth_provider.dart';
import 'package:aif2f/core/router/app_router.dart';

/// 认证守卫
/// 用于保护需要登录才能访问的页面
class AuthGuard extends AutoRouteGuard {
  final Ref ref;

  AuthGuard(this.ref);

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    // 获取认证状态
    final authState = ref.read(authProvider);

    // 检查用户是否已登录
    if (authState.isAuthenticated) {
      // 已登录，继续导航
      resolver.next(true);
    } else {
      // 未登录，跳转到登录页
      router.push(LoginRoute());

      // 不继续导航到目标页面
      resolver.next(false);
    }
  }
}
