import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aif2f/core/widgets/auth_required.dart';
import 'package:aif2f/core/models/fibonacci_membership.dart';
import 'package:aif2f/data/models/order_model.dart';
import 'package:aif2f/data/providers/membership_provider.dart';
import 'package:aif2f/data/providers/auth_provider.dart';
import 'package:aif2f/data/providers/product_provider.dart';
import 'package:aif2f/data/providers/security_settings_provider.dart';

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
  void initState() {
    super.initState();
    // 预加载订单数据
    Future.microtask(() {
      ref.read(orderProvider.notifier).loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthRequired(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('会员中心'),
          centerTitle: true,
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: '关闭',
            ),
          ],
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
                  _buildMenuItem(index: 1, icon: Icons.person, title: '用户资料'),
                ],
              ),
            ),
            // 右侧分割线
            Container(width: 1, color: Theme.of(context).dividerColor),
            // 右侧内容
            Expanded(child: _buildContent()),
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
    final orderState = ref.watch(orderProvider);
    final orders = orderState.orders;
    final isLoading = orderState.isLoading;
    final errorMessage = orderState.errorMessage;

    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : errorMessage != null
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(errorMessage, style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.read(orderProvider.notifier).clearError();
                    ref.read(orderProvider.notifier).refresh();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('重试'),
                ),
              ],
            ),
          )
        : orders.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  size: 64,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  '暂无订单',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  '快去充值吧',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return _buildOrderCard(context, order);
            },
          );
  }

  Widget _buildProfileContent() {
    final authState = ref.watch(authProvider);
    final membershipState = ref.watch(membershipProvider);
    final membershipInfo =
        membershipState.membershipInfo ?? FibonacciMembershipInfo.free();
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
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('昵称修改功能开发中')));
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
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('音色选择功能开发中')));
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
              if (newPasswordController.text !=
                  confirmPasswordController.text) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('两次输入的密码不一致')));
                return;
              }

              // TODO: 实现密码修改逻辑
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('密码修改功能开发中')));
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showSecuritySettingsDialog(BuildContext context) {
    final securityState = ref.watch(securitySettingsProvider);
    
    // 初始化加载
    Future.microtask(() {
      ref.read(securitySettingsProvider.notifier).loadSettings();
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('安全设置'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 邮箱绑定
              ListTile(
                leading: Icon(
                  securityState.isEmailVerified
                      ? Icons.check_circle
                      : Icons.email,
                  color: securityState.isEmailVerified
                      ? Colors.green
                      : null,
                ),
                title: const Text('邮箱绑定'),
                subtitle: Text(
                  securityState.isEmailVerified
                      ? (securityState.email ?? '已绑定')
                      : '未绑定',
                  style: TextStyle(
                    color: securityState.isEmailVerified
                        ? Colors.green
                        : Colors.grey,
                  ),
                ),
                trailing: securityState.isEmailVerified
                    ? TextButton(
                        onPressed: securityState.isLoading
                            ? null
                            : () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('解绑邮箱'),
                                    content: const Text(
                                      '确定要解绑邮箱吗？解绑后可能影响部分功能的使用。',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('取消'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('确定'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirmed == true) {
                                  final success = await ref
                                      .read(securitySettingsProvider.notifier)
                                      .unbindEmail();
                                  if (context.mounted) {
                                    if (success) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text('邮箱已解绑')),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text('解绑失败')),
                                      );
                                    }
                                  }
                                }
                              },
                        child: const Text('解绑'),
                      )
                    : TextButton(
                        onPressed: securityState.isLoading
                            ? null
                            : () {
                                Navigator.pop(context);
                                _showBindEmailDialog(context, ref);
                              },
                        child: const Text('绑定'),
                      ),
              ),
              const Divider(),
              // 手机绑定
              ListTile(
                leading: Icon(
                  securityState.isPhoneVerified
                      ? Icons.check_circle
                      : Icons.phone_android,
                  color: securityState.isPhoneVerified
                      ? Colors.green
                      : null,
                ),
                title: const Text('手机绑定'),
                subtitle: Text(
                  securityState.isPhoneVerified
                      ? (securityState.phone ?? '已绑定')
                      : '未绑定',
                  style: TextStyle(
                    color: securityState.isPhoneVerified
                        ? Colors.green
                        : Colors.grey,
                  ),
                ),
                trailing: securityState.isPhoneVerified
                    ? TextButton(
                        onPressed: securityState.isLoading
                            ? null
                            : () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('解绑手机'),
                                    content: const Text(
                                      '确定要解绑手机吗？解绑后可能影响部分功能的使用。',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('取消'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('确定'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirmed == true) {
                                  final success = await ref
                                      .read(securitySettingsProvider.notifier)
                                      .unbindPhone();
                                  if (context.mounted) {
                                    if (success) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text('手机已解绑')),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text('解绑失败')),
                                      );
                                    }
                                  }
                                }
                              },
                        child: const Text('解绑'),
                      )
                    : TextButton(
                        onPressed: securityState.isLoading
                            ? null
                            : () {
                                Navigator.pop(context);
                                _showBindPhoneDialog(context, ref);
                              },
                        child: const Text('绑定'),
                      ),
              ),
              if (securityState.isLoading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (securityState.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    securityState.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(securitySettingsProvider.notifier).reset();
              Navigator.pop(context);
            },
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// 显示绑定邮箱对话框
  void _showBindEmailDialog(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();
    final codeController = TextEditingController();
    bool isCodeSent = false;
    int countdown = 60;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('绑定邮箱'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: '邮箱地址',
                    hintText: '请输入邮箱地址',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: codeController,
                        decoration: const InputDecoration(
                          labelText: '验证码',
                          hintText: '请输入验证码',
                          prefixIcon: Icon(Icons.security),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: isCodeSent
                          ? null
                          : () async {
                              if (emailController.text.isEmpty ||
                                  !emailController.text.contains('@')) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('请输入有效的邮箱地址')),
                                );
                                return;
                              }

                              final success = await ref
                                  .read(securitySettingsProvider.notifier)
                                  .sendEmailCode(emailController.text);

                              if (success && context.mounted) {
                                setDialogState(() {
                                  isCodeSent = true;
                                  countdown = 60;
                                });

                                // 开始倒计时
                                Future.delayed(const Duration(seconds: 1), () {
                                  if (context.mounted) {
                                    setDialogState(() {
                                      countdown--;
                                    });
                                    if (countdown > 0) {
                                      Future.delayed(
                                          const Duration(seconds: 1), () {
                                        if (context.mounted) {
                                          setDialogState(() {
                                            countdown--;
                                          });
                                        }
                                      });
                                    }
                                  }
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('验证码已发送，请查收邮箱')),
                                );
                              }
                            },
                      child: Text(
                        isCodeSent ? '$countdown 秒' : '获取验证码',
                      ),
                    ),
                  ],
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
                if (emailController.text.isEmpty ||
                    codeController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请填写完整信息')),
                  );
                  return;
                }

                final success = await ref
                    .read(securitySettingsProvider.notifier)
                    .bindEmail(emailController.text, codeController.text);

                if (context.mounted) {
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('邮箱绑定成功')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('邮箱绑定失败')),
                    );
                  }
                }
              },
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示绑定手机对话框
  void _showBindPhoneDialog(BuildContext context, WidgetRef ref) {
    final phoneController = TextEditingController();
    final codeController = TextEditingController();
    bool isCodeSent = false;
    int countdown = 60;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('绑定手机'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: '手机号码',
                    hintText: '请输入手机号码',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: codeController,
                        decoration: const InputDecoration(
                          labelText: '验证码',
                          hintText: '请输入验证码',
                          prefixIcon: Icon(Icons.security),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: isCodeSent
                          ? null
                          : () async {
                              if (phoneController.text.isEmpty ||
                                  phoneController.text.length != 11) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('请输入有效的手机号码')),
                                );
                                return;
                              }

                              final success = await ref
                                  .read(securitySettingsProvider.notifier)
                                  .sendPhoneCode(phoneController.text);

                              if (success && context.mounted) {
                                setDialogState(() {
                                  isCodeSent = true;
                                  countdown = 60;
                                });

                                // 开始倒计时
                                for (int i = 60; i > 0; i--) {
                                  await Future.delayed(
                                      const Duration(seconds: 1), () {
                                    if (context.mounted) {
                                      setDialogState(() {
                                        countdown = i;
                                      });
                                    }
                                  });
                                }

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('验证码已发送，请查收短信')),
                                );
                              }
                            },
                      child: Text(
                        isCodeSent ? '$countdown 秒' : '获取验证码',
                      ),
                    ),
                  ],
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
                if (phoneController.text.isEmpty ||
                    codeController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请填写完整信息')),
                  );
                  return;
                }

                final success = await ref
                    .read(securitySettingsProvider.notifier)
                    .bindPhone(phoneController.text, codeController.text);

                if (context.mounted) {
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('手机绑定成功')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('手机绑定失败')),
                    );
                  }
                }
              },
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建订单卡片
  Widget _buildOrderCard(BuildContext context, OrderModel order) {
    final statusColor = _getStatusColor(order.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 订单头部
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '订单号：${order.orderNo}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.productName ?? '订单',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                      if (order.productSummary != null && order.productSummary!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          order.productSummary!.join(', '),
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order.status.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // 订单详情
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 商品数量（如果有的话）或充值时长
                if (order.hours != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '充值时长',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${order.hours} 小时',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                else if (order.itemCount != null && order.itemCount! > 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '商品数量',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${order.itemCount} 件',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                else
                  const SizedBox.shrink(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '订单金额',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '¥${order.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 时间信息
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  _formatDateTime(order.createdAt),
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                if (order.paidAt != null) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.check_circle, size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    '支付时间：${_formatDateTime(order.paidAt)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),

            // 操作按钮
            if (order.isPending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('取消订单'),
                            content: const Text('确定要取消此订单吗？'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('取消'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('确定'),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true && mounted) {
                          final success = await ref
                              .read(orderProvider.notifier)
                              .cancelOrder(order.orderNo);
                          if (success && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('订单已取消')),
                            );
                          }
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text('取消订单'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: 继续支付
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('继续支付功能开发中...')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text('继续支付'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 获取状态颜色
  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return const Color(0xFFFF9800); // 橙色
      case OrderStatus.processing:
        return const Color(0xFF2196F3); // 蓝色
      case OrderStatus.completed:
        return const Color(0xFF4CAF50); // 绿色
      case OrderStatus.cancelled:
        return const Color(0xFF9E9E9E); // 灰色
      case OrderStatus.failed:
        return const Color(0xFFF44336); // 红色
      case OrderStatus.refunded:
        return const Color(0xFF9C27B0); // 紫色
    }
  }

  /// 格式化日期时间
  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '-';

    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
