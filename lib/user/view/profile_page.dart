import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aif2f/core/widgets/auth_required.dart';

/// 个人信息页面
@RoutePage()
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 使用 AuthRequired 组件保护需要登录的页面
    return AuthRequired(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('个人信息'),
          centerTitle: true,
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('个人信息页面'),
        ),
      ),
    );
  }
}
