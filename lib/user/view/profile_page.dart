import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aif2f/core/widgets/auth_required.dart';
import 'package:aif2f/core/models/fibonacci_membership.dart';
import 'package:aif2f/data/providers/membership_provider.dart';
import 'package:aif2f/data/providers/auth_provider.dart';

/// 个人信息页面
@RoutePage()
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final membershipState = ref.watch(membershipProvider);
    final membershipInfo = membershipState.membershipInfo ?? FibonacciMembershipInfo.free();
    final user = authState.user;

    // 使用 AuthRequired 组件保护需要登录的页面
    return AuthRequired(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('个人信息'),
          centerTitle: true,
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
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

              // 会员等级卡片
              FibonacciLevelCard(
                membership: membershipInfo,
                showDetails: true,
              ),

              const SizedBox(height: 16),

              // 账户信息卡片
              Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        '账户信息',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text('累计时长'),
                      trailing: Text(
                        _formatHours(membershipInfo.totalHours),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.star),
                      title: const Text('当前等级'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: membershipInfo.levelColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'LV.${membershipInfo.level} ${membershipInfo.levelTitle}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.trending_up),
                      title: const Text('下一等级'),
                      trailing: Text(
                        'LV.${membershipInfo.nextLevel}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.hourglass_empty),
                      title: const Text('还需时长'),
                      trailing: Text(
                        '${membershipInfo.hoursToNextLevel} 小时',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 等级进度卡片
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '升级进度',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: membershipInfo.progress,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            membershipInfo.levelColor,
                          ),
                          minHeight: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'LV.${membershipInfo.level}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${(membershipInfo.progress * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          Text(
                            'LV.${membershipInfo.nextLevel}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 注册时间
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('注册时间'),
                  subtitle: user?.createdAt != null
                      ? Text(
                          '${user?.createdAt?.year}-${user?.createdAt?.month.toString().padLeft(2, '0')}-${user?.createdAt?.day.toString().padLeft(2, '0')}',
                        )
                      : const Text('未知'),
                ),
              ),
            ],
          ),
        ),
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
}
