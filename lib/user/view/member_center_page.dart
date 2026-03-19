import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aif2f/core/widgets/auth_required.dart';
import 'package:aif2f/core/models/fibonacci_membership.dart';
import 'package:aif2f/data/providers/membership_provider.dart';
import 'package:aif2f/data/providers/auth_provider.dart';
import 'package:aif2f/user/widgets/orders_dialog.dart';

/// 会员中心页面
/// 左侧是菜单（用户订单、用户资料），右侧显示内容
@RoutePage()
class MemberCenterPage extends ConsumerStatefulWidget {
  const MemberCenterPage({super.key});

  @override
  ConsumerState<MemberCenterPage> createState() => _MemberCenterPageState();
}

class _MemberCenterPageState extends ConsumerState<MemberCenterPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AuthRequired(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('会员中心'),
          centerTitle: true,
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Row(
          children: [
            // 左侧菜单
            Container(
              width: 200,
              color: Theme.of(context).colorScheme.surface,
              child: Column(
                children: [
                  _buildMenuItem(
                    index: 0,
                    icon: Icons.receipt_long,
                    title: '用户订单',
                  ),
                  _buildMenuItem(
                    index: 1,
                    icon: Icons.person,
                    title: '用户资料',
                  ),
                ],
              ),
            ),
            // 右侧分割线
            Container(
              width: 1,
              color: Theme.of(context).dividerColor,
            ),
            // 右侧内容
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required int index,
    required IconData icon,
    required String title,
  }) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? Theme.of(context).primaryColor
            : Theme.of(context).iconTheme.color,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? Theme.of(context).primaryColor
              : Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildOrdersContent();
      case 1:
        return _buildProfileContent();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildOrdersContent() {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const OrdersDialog(),
          );
        },
        icon: const Icon(Icons.receipt_long),
        label: const Text('查看订单'),
      ),
    );
  }

  Widget _buildProfileContent() {
    final authState = ref.watch(authProvider);
    final membershipState = ref.watch(membershipProvider);
    final membershipInfo = membershipState.membershipInfo ?? FibonacciMembershipInfo.free();
    final user = authState.user;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 用户基本信息卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Text(
                          user?.username.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.nickname ?? user?.username ?? '未知用户',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 用户资料编辑列表
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '用户资料',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('昵称'),
                  subtitle: Text(user?.nickname ?? user?.username ?? '未设置'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showEditNicknameDialog(context, ref);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.volume_up),
                  title: const Text('音色'),
                  subtitle: const Text('默认音色'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showVoiceToneDialog(context);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('密码'),
                  subtitle: const Text('修改密码'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showChangePasswordDialog(context, ref);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.security),
                  title: const Text('安全设置'),
                  subtitle: const Text('邮箱、手机绑定等'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showSecuritySettingsDialog(context);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 会员等级卡片
          FibonacciLevelCard(
            membership: membershipInfo,
            showDetails: false,
          ),
        ],
      ),
    );
  }

  void _showEditNicknameDialog(BuildContext context, WidgetRef ref) {
    final authState = ref.read(authProvider);
    final controller = TextEditingController(
      text: authState.user?.nickname ?? authState.user?.username ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改昵称'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '昵称',
            hintText: '请输入新昵称',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: 实现昵称修改逻辑
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('昵称修改功能开发中')),
              );
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showVoiceToneDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择音色'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('默认音色'),
              leading: Radio<int>(
                value: 0,
                groupValue: 0,
                onChanged: (value) {},
              ),
            ),
            ListTile(
              title: const Text('成熟男声'),
              leading: Radio<int>(
                value: 1,
                groupValue: 0,
                onChanged: (value) {},
              ),
            ),
            ListTile(
              title: const Text('温柔女声'),
              leading: Radio<int>(
                value: 2,
                groupValue: 0,
                onChanged: (value) {},
              ),
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
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('音色选择功能开发中')),
              );
            },
            child: const Text('保存'),
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '当前密码',
                hintText: '请输入当前密码',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '新密码',
                hintText: '请输入新密码',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '确认密码',
                hintText: '请再次输入新密码',
              ),
            ),
          ],
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

  void _showSecuritySettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('安全设置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('邮箱绑定'),
              subtitle: const Text('未绑定'),
              trailing: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('邮箱绑定功能开发中')),
                  );
                },
                child: const Text('绑定'),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.phone_android),
              title: const Text('手机绑定'),
              subtitle: const Text('未绑定'),
              trailing: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('手机绑定功能开发中')),
                  );
                },
                child: const Text('绑定'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}
