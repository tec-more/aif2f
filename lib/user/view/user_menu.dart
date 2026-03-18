import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aif2f/core/router/app_router.dart';
import 'package:aif2f/data/providers/auth_provider.dart';
import 'package:aif2f/data/providers/membership_provider.dart';
import 'package:aif2f/data/providers/product_provider.dart';
import 'package:aif2f/data/services/toast_service.dart';
import 'package:aif2f/user/widgets/orders_dialog.dart';

class UserMenu extends ConsumerWidget {
  const UserMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final membership = ref.watch(currentMembershipProvider);
    final user = authState.user;
    final isLoggedIn = authState.isAuthenticated;

    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'profile':
            if (isLoggedIn) {
              // 使用路由导航到个人信息页面
              context.router.push(ProfileRoute());
            } else {
              // 未登录时跳转到登录页面
              context.router.push(LoginRoute());
            }
            break;
          case 'settings':
            if (isLoggedIn) {
              // 使用路由导航到设置页面
              context.router.push(SettingsRoute());
            } else {
              // 未登录时跳转到登录页面
              context.router.push(LoginRoute());
            }
            break;
          case 'about':
            // 使用路由导航到关于页面
            context.router.push(AboutRoute());
            break;
          case 'orders':
            if (isLoggedIn) {
              // 显示订单对话框
              showDialog(
                context: context,
                builder: (context) => const OrdersDialog(),
              );
            } else {
              // 未登录时跳转到登录页面
              context.router.push(LoginRoute());
            }
            break;
          case 'logout':
            _showLogoutConfirmation(context, ref);
            break;
          case 'login':
            // 跳转到登录页面
            context.router.push(LoginRoute());
            break;
        }
      },
      itemBuilder: (context) {
        final List<PopupMenuEntry<String>> items = [];

        // 用户信息和会员等级头部
        items.add(
          PopupMenuItem(
            enabled: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 用户名
                Text(
                  isLoggedIn
                      ? (user?.nickname ?? user?.username ?? '未知用户')
                      : '未登录',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                // 会员等级标签
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: membership.levelColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(membership.levelIcon, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'LV.${membership.level} ${membership.levelTitle}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // 累计时长
                Text(
                  '累计时长: ${_formatHours(membership.totalHours)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (membership.level == 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '再充值 ${membership.hoursToNextLevel} 小时升级到 LV.1',
                    style: TextStyle(fontSize: 11, color: Colors.blue[600]),
                  ),
                ],
              ],
            ),
          ),
        );

        items.add(const PopupMenuDivider());

        items.add(
          PopupMenuItem(
            value: 'profile',
            child: Row(
              children: const [
                Icon(Icons.person_outline, color: Colors.black),
                SizedBox(width: 10),
                Text('个人信息'),
              ],
            ),
          ),
        );

        items.add(
          PopupMenuItem(
            value: 'settings',
            child: Row(
              children: const [
                Icon(Icons.settings_outlined, color: Colors.black),
                SizedBox(width: 10),
                Text('设置'),
              ],
            ),
          ),
        );

        items.add(
          PopupMenuItem(
            value: 'about',
            child: Row(
              children: const [
                Icon(Icons.info_outline, color: Colors.black),
                SizedBox(width: 10),
                Text('关于'),
              ],
            ),
          ),
        );

        items.add(
          PopupMenuItem(
            value: 'orders',
            child: Row(
              children: const [
                Icon(Icons.receipt_long, color: Colors.black),
                SizedBox(width: 10),
                Text('我的订单'),
              ],
            ),
          ),
        );

        items.add(const PopupMenuDivider());

        if (isLoggedIn) {
          // 已登录显示退出登录
          items.add(
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: const [
                  Icon(Icons.logout, color: Colors.black),
                  SizedBox(width: 10),
                  Text('退出登录'),
                ],
              ),
            ),
          );
        } else {
          // 未登录显示登录
          items.add(
            PopupMenuItem(
              value: 'login',
              child: Row(
                children: const [
                  Icon(Icons.login, color: Colors.black),
                  SizedBox(width: 10),
                  Text('登录'),
                ],
              ),
            ),
          );
        }

        return items;
      },
      tooltip: '用户菜单',
      // 使用child确保图标在悬停时仍然可见
      child: IconButton(
        icon: Stack(
          children: [
            const Icon(Icons.person_outline, color: Colors.white),
            // 等级角标
            if (membership.level > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: membership.levelColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 14,
                  ),
                  child: Text(
                    'LV.${membership.level}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        onPressed: null, // PopupMenuButton会处理点击事件
        tooltip: '用户菜单',
        hoverColor: Colors.white.withOpacity(0.2), // 设置半透明的悬停背景
        splashColor: Colors.transparent, // 移除点击水波纹效果
      ),
    );
  }

  String _formatHours(int hours) {
    if (hours >= 24) {
      final days = hours ~/ 24;
      final remainingHours = hours % 24;
      if (remainingHours > 0) {
        return '$days天$remainingHours小时';
      }
      return '$days天';
    }
    return '$hours小时';
  }

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // 执行退出登录逻辑
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                toastService.showSuccess('已退出登录');
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
