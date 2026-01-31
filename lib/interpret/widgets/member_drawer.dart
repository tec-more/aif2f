import 'package:flutter/material.dart';
import 'package:aif2f/core/models/fibonacci_membership.dart';

/// 会员侧边抽屉菜单
/// 显示会员等级、累计时长和充值入口（基于Fibonacci数列）
class MemberDrawer extends StatelessWidget {
  const MemberDrawer({
    super.key,
    this.membershipInfo,
    this.onRecharge,
    this.onProfile,
    this.onSettings,
    this.onHelp,
    this.onAbout,
  });

  /// 会员信息（基于Fibonacci数列）
  final FibonacciMembershipInfo? membershipInfo;

  /// 充值回调
  final VoidCallback? onRecharge;

  /// 个人资料回调
  final VoidCallback? onProfile;

  /// 设置回调
  final VoidCallback? onSettings;

  /// 帮助回调
  final VoidCallback? onHelp;

  /// 关于回调
  final VoidCallback? onAbout;

  @override
  Widget build(BuildContext context) {
    // 使用提供的会员信息，或使用默认的免费用户
    final info = membershipInfo ?? FibonacciMembershipInfo.free();
    final level = info.level;
    final levelTitle = info.levelTitle;
    final levelColor = info.levelColor;
    final levelIcon = info.levelIcon;
    final totalHours = info.totalHours;
    final hoursToNext = info.hoursToNextLevel;
    final progress = info.progress;

    return Drawer(
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // 头部 - 会员信息卡片
              _buildMemberHeader(
                context,
                info,
                level,
                levelTitle,
                levelColor,
                levelIcon,
                totalHours,
                hoursToNext,
                progress,
              ),

              const SizedBox(height: 16),

              // 充值入口卡片
              _buildRechargeSection(context, info),

              const SizedBox(height: 16),

              // 菜单列表
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildMenuItem(
                      context,
                      icon: Icons.person_outline,
                      title: '个人资料',
                      onTap: () {
                        Navigator.pop(context);
                        onProfile?.call();
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.settings_outlined,
                      title: '设置',
                      onTap: () {
                        Navigator.pop(context);
                        onSettings?.call();
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.help_outline,
                      title: '帮助与反馈',
                      onTap: () {
                        Navigator.pop(context);
                        onHelp?.call();
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.info_outline,
                      title: '关于',
                      onTap: () {
                        Navigator.pop(context);
                        onAbout?.call();
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 底部版本信息
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建会员信息头部
  Widget _buildMemberHeader(
    BuildContext context,
    FibonacciMembershipInfo info,
    int level,
    String levelTitle,
    Color levelColor,
    IconData levelIcon,
    int totalHours,
    int hoursToNext,
    double progress,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            levelColor,
            levelColor.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: levelColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 会员等级
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      levelIcon,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'LV.$level',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      levelTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // 累计时长显示
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.access_time,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatHours(totalHours),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 进度条
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '升级进度',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '下一级: LV.${info.nextLevel}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.8),
                  ),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '还需 $hoursToNext 小时',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    '${(progress * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 详情按钮
          const SizedBox(height: 16),
          _buildPrivilegesList(context, info),
        ],
      ),
    );
  }

  /// 构建特权列表
  Widget _buildPrivilegesList(BuildContext context, FibonacciMembershipInfo info) {
    final privileges = info.privileges;
    final displayPrivileges = privileges.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '当前特权',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...displayPrivileges.map((privilege) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.white.withOpacity(0.8),
                  size: 12,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    privilege,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          )),
          if (privileges.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '等${privileges.length}项特权...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 格式化小时数
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

  /// 构建充值区域 - 按小时充值选项
  Widget _buildRechargeSection(BuildContext context, FibonacciMembershipInfo info) {
    // 充值时长选项（小时）- 根据Fibonacci数列设计
    final rechargeOptions = [
      {'hours': 1, 'bonus': 0},
      {'hours': 2, 'bonus': 0},
      {'hours': 5, 'bonus': 0},
      {'hours': 10, 'bonus': 0},
      {'hours': 20, 'bonus': 0},
      {'hours': 50, 'bonus': 0},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.diamond_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '充值时长',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 充值时长选项
              ...rechargeOptions.map((option) {
                final hours = option['hours'] as int;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildHourOption(context, hours, info),
                );
              }),

              const SizedBox(height: 12),

              // 充值按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    onRecharge?.call();
                  },
                  icon: const Icon(Icons.payment_rounded, size: 18),
                  label: const Text('立即充值'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建小时充值选项
  Widget _buildHourOption(BuildContext context, int hours, FibonacciMembershipInfo currentInfo) {
    // 根据充值时长计算赠送时长或折扣
    final bonusHours = _getBonusHours(hours);
    final totalHours = hours + bonusHours;

    // 计算充值后的等级
    final newTotalHours = currentInfo.totalHours + totalHours;
    final newLevel = FibonacciMembershipSystem.getLevelFromHours(newTotalHours);
    final currentLevel = currentInfo.level;

    return InkWell(
      onTap: () {
        final bonusText = bonusHours > 0 ? " + 赠送$bonusHours小时" : "";
        final levelUpText = newLevel > currentLevel ? " → LV.$newLevel" : "";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已选择：$hours 小时$bonusText，合计$totalHours小时$levelUpText')),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      Text(
                        '$hours 小时',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      if (bonusHours > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '+$bonusHours小时赠送',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (newLevel > currentLevel)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '升级 LV.$newLevel',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bonusHours > 0
                        ? '合计 $totalHours 小时'
                        : '快速充值',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '¥${_getHourPrice(hours)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 计算赠送时长
  int _getBonusHours(int hours) {
    if (hours >= 50) return 10; // 充值50小时赠送10小时
    if (hours >= 20) return 5;  // 充值20小时赠送5小时
    if (hours >= 10) return 2;  // 充值10小时赠送2小时
    if (hours >= 5) return 1;   // 充值5小时赠送1小时
    return 0;
  }

  /// 计算价格（每小时1元）
  double _getHourPrice(int hours) {
    return hours.toDouble();
  }

  /// 构建菜单项
  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  /// 构建底部版本信息
  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Divider(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: 8),
          Text(
            'AI传译 v1.0.0',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '© 2025 All Rights Reserved',
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
