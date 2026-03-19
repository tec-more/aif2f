import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aif2f/core/widgets/auth_required.dart';
import 'package:aif2f/data/providers/auth_provider.dart';
import 'package:aif2f/data/providers/settings_provider.dart';

/// 设置页面
@RoutePage()
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final settingsState = ref.watch(settingsProvider);
    final user = authState.user;

    return AuthRequired(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('设置'),
          centerTitle: true,
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // 账户安全
              _buildSection(
                context,
                title: '账户安全',
                children: [
                  ListTile(
                    leading: const Icon(Icons.email),
                    title: const Text('邮箱绑定'),
                    subtitle: Text(
                      user?.email ?? '未绑定',
                      style: TextStyle(
                        color: user?.email != null
                            ? Colors.green
                            : Colors.grey,
                      ),
                    ),
                    trailing: user?.email != null
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.chevron_right),
                    onTap: () {
                      _showBindEmailDialog(context, ref);
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.phone_android),
                    title: const Text('手机绑定'),
                    subtitle: Text(
                      user?.phone ?? '未绑定',
                      style: TextStyle(
                        color: user?.phone != null
                            ? Colors.green
                            : Colors.grey,
                      ),
                    ),
                    trailing: user?.phone != null
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.chevron_right),
                    onTap: () {
                      _showBindPhoneDialog(context, ref);
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.lock),
                    title: const Text('修改密码'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _showChangePasswordDialog(context, ref);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 通知设置
              _buildSection(
                context,
                title: '通知设置',
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications),
                    title: const Text('接收通知'),
                    subtitle: const Text('接收应用推送的通知'),
                    value: settingsState.notificationsEnabled,
                    onChanged: (value) {
                      ref.read(settingsProvider.notifier)
                          .setNotificationsEnabled(value);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 语言设置
              _buildSection(
                context,
                title: '语言设置',
                children: [
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: const Text('语言'),
                    subtitle: Text(_getLanguageName(settingsState.language)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _showLanguageDialog(context, ref);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 主题设置
              _buildSection(
                context,
                title: '主题设置',
                children: [
                  ListTile(
                    leading: const Icon(Icons.palette),
                    title: const Text('主题'),
                    subtitle: Text(_getThemeName(settingsState.theme)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _showThemeDialog(context, ref);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 保存按钮
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await ref.read(settingsProvider.notifier).saveSettings();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('设置已保存')),
                        );
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text('保存设置'),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'zh-CN':
        return '简体中文';
      case 'zh-TW':
        return '繁體中文';
      case 'en':
        return 'English';
      default:
        return '简体中文';
    }
  }

  String _getThemeName(String theme) {
    switch (theme) {
      case 'light':
        return '浅色模式';
      case 'dark':
        return '深色模式';
      case 'system':
        return '跟随系统';
      default:
        return '跟随系统';
    }
  }

  void _showBindEmailDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('绑定邮箱'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: '邮箱地址',
                hintText: '请输入邮箱地址',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: 实现邮箱绑定逻辑
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('邮箱绑定功能开发中')),
              );
            },
            child: const Text('绑定'),
          ),
        ],
      ),
    );
  }

  void _showBindPhoneDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('绑定手机'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: '手机号码',
                hintText: '请输入手机号码',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: 实现手机绑定逻辑
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('手机绑定功能开发中')),
              );
            },
            child: const Text('绑定'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改密码'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '当前密码',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '新密码',
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '确认密码',
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('两次输入的密码不一致')),
                );
                return;
              }

              // TODO: 实现密码修改逻辑
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('密码修改功能开发中')),
              );
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(settingsProvider.notifier);
    final currentLanguage = ref.read(settingsProvider).language;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择语言'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('简体中文'),
              value: 'zh-CN',
              groupValue: currentLanguage,
              onChanged: (value) {
                notifier.setLanguage(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('繁體中文'),
              value: 'zh-TW',
              groupValue: currentLanguage,
              onChanged: (value) {
                notifier.setLanguage(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: currentLanguage,
              onChanged: (value) {
                notifier.setLanguage(value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(settingsProvider.notifier);
    final currentTheme = ref.read(settingsProvider).theme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择主题'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('跟随系统'),
              value: 'system',
              groupValue: currentTheme,
              onChanged: (value) {
                notifier.setTheme(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('浅色模式'),
              value: 'light',
              groupValue: currentTheme,
              onChanged: (value) {
                notifier.setTheme(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('深色模式'),
              value: 'dark',
              groupValue: currentTheme,
              onChanged: (value) {
                notifier.setTheme(value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
