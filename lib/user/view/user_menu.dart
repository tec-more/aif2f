import 'package:flutter/material.dart';

class UserMenu extends StatelessWidget {
  const UserMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'profile':
            _showProfile(context);
            break;
          case 'settings':
            _showSettings(context);
            break;
          case 'about':
            _showAbout(context);
            break;
          case 'logout':
            _showLogoutConfirmation(context);
            break;
        }
      },
      itemBuilder: (context) {
        return [
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
          const PopupMenuDivider(),
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
        ];
      },
      // 使用child确保图标在悬停时仍然可见
      child: IconButton(
        icon: const Icon(Icons.person, color: Colors.white),
        onPressed: null, // PopupMenuButton会处理点击事件
        tooltip: '用户菜单',
        hoverColor: Colors.white.withOpacity(0.2), // 设置半透明的悬停背景
        splashColor: Colors.transparent, // 移除点击水波纹效果
      ),
      tooltip: '用户菜单',
    );
  }

  void _showProfile(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('个人信息'),
        content: const Text('个人信息页面'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置'),
        content: const Text('设置页面'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('关于'),
        content: const Text('AI面对面 - 智能对话应用\n版本 1.0.0'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
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
            onPressed: () {
              Navigator.pop(context);
              // 执行退出登录逻辑
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
