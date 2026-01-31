import 'package:flutter/material.dart';

/// 基于阿波斐契数列的无限会员等级系统
/// 等级1-无限，每充值1小时等级+1，时长增长符合阿波斐契数列

class FibonacciMembershipSystem {
  /// 阿波斐契数列缓存
  static final List<int> _fibonacciSequence = [1, 1];

  /// 获取第n个阿波斐契数（从1开始）
  /// F(1) = 1, F(2) = 1, F(3) = 2, F(4) = 3, F(5) = 5, ...
  static int getFibonacci(int n) {
    if (n < 1) return 1;

    // 扩展数列直到包含第n项
    while (_fibonacciSequence.length < n) {
      final next = _fibonacciSequence[_fibonacciSequence.length - 1] +
                  _fibonacciSequence[_fibonacciSequence.length - 2];
      _fibonacciSequence.add(next);
    }

    return _fibonacciSequence[n - 1];
  }

  /// 计算达到某个等级所需的累计时长（小时）
  /// 等级n需要 sum(F(1) to F(n)) 小时
  static int getHoursForLevel(int level) {
    if (level < 1) return 0;

    int totalHours = 0;
    for (int i = 1; i <= level; i++) {
      totalHours += getFibonacci(i);
    }
    return totalHours;
  }

  /// 根据累计充值时长计算当前等级
  static int getLevelFromHours(int totalHours) {
    if (totalHours < 1) return 0;

    int level = 0;
    int accumulatedHours = 0;

    while (true) {
      final nextHours = getFibonacci(level + 1);
      if (accumulatedHours + nextHours > totalHours) {
        break;
      }
      accumulatedHours += nextHours;
      level++;
    }

    return level;
  }

  /// 获取等级到下一等级所需的额外小时数
  static int getHoursToNextLevel(int currentLevel, int totalHours) {
    final requiredHours = getHoursForLevel(currentLevel + 1);
    return requiredHours - totalHours;
  }

  /// 计算当前等级的进度百分比
  static double getLevelProgress(int totalHours) {
    final level = getLevelFromHours(totalHours);
    final previousLevelHours = getHoursForLevel(level);
    final nextLevelHours = getHoursForLevel(level + 1);

    if (nextLevelHours == previousLevelHours) return 1.0;

    final progress = (totalHours - previousLevelHours) /
                     (nextLevelHours - previousLevelHours);
    return progress.clamp(0.0, 1.0);
  }
}

/// 会员信息
class FibonacciMembershipInfo {
  const FibonacciMembershipInfo({
    required this.totalHours,
    this.startDate,
  });

  /// 累计充值时长（小时）
  final int totalHours;

  /// 开始时间
  final DateTime? startDate;

  /// 获取当前等级
  int get level => FibonacciMembershipSystem.getLevelFromHours(totalHours);

  /// 获取等级称号
  String get levelTitle {
    final lvl = level;
    if (lvl >= 144) return '传奇会员';
    if (lvl >= 89) return '至尊会员';
    if (lvl >= 55) return '钻石会员';
    if (lvl >= 34) return '铂金会员';
    if (lvl >= 21) return '黄金会员';
    if (lvl >= 13) return '白银会员';
    if (lvl >= 8) return '青铜会员';
    if (lvl >= 5) return '高级会员';
    if (lvl >= 3) return '正式会员';
    if (lvl >= 1) return '体验会员';
    return '免费用户';
  }

  /// 获取等级颜色
  Color get levelColor {
    final lvl = level;
    if (lvl >= 144) return const Color(0xFFFFD700); // 金色
    if (lvl >= 89) return const Color(0xFF9C27B0); // 紫色
    if (lvl >= 55) return const Color(0xFF2196F3); // 蓝色
    if (lvl >= 34) return const Color(0xFF607D8B); // 铅蓝
    if (lvl >= 21) return const Color(0xFFFFC107); // 琥珀
    if (lvl >= 13) return const Color(0xFF9E9E9E); // 灰色
    if (lvl >= 8) return const Color(0xFF795548); // 棕色
    if (lvl >= 5) return const Color(0xFF4CAF50); // 绿色
    if (lvl >= 3) return const Color(0xFF03A9F4); // 浅蓝
    if (lvl >= 1) return const Color(0xFF9E9E9E); // 浅灰
    return const Color(0xFFBDBDBD); // 深灰
  }

  /// 获取等级图标
  IconData get levelIcon {
    final lvl = level;
    if (lvl >= 144) return Icons.military_tech;
    if (lvl >= 89) return Icons.stars;
    if (lvl >= 55) return Icons.diamond;
    if (lvl >= 34) return Icons.workspace_premium;
    if (lvl >= 21) return Icons.emoji_events;
    if (lvl >= 13) return Icons.card_membership;
    if (lvl >= 8) return Icons.verified;
    if (lvl >= 5) return Icons.star;
    if (lvl >= 3) return Icons.bookmark;
    if (lvl >= 1) return Icons.person;
    return Icons.person_outline;
  }

  /// 获取等级进度（0-1）
  double get progress => FibonacciMembershipSystem.getLevelProgress(totalHours);

  /// 获取下一等级所需小时数
  int get hoursToNextLevel =>
      FibonacciMembershipSystem.getHoursToNextLevel(level, totalHours);

  /// 获取下一等级
  int get nextLevel => level + 1;

  /// 判断是否为高级会员（等级5+）
  bool get isPremium => level >= 5;

  /// 判断是否为VIP会员（等级13+）
  bool get isVip => level >= 13;

  /// 判断是否为至尊会员（等级89+）
  bool get isSupreme => level >= 89;

  /// 获取等级特权列表
  List<String> get privileges {
    final lvl = level;
    final List<String> basePrivileges = [
      '基础翻译功能',
    ];

    if (lvl >= 1) {
      basePrivileges.addAll([
        '每日100字翻译额度',
        '标准客服支持',
      ]);
    }

    if (lvl >= 3) {
      basePrivileges.addAll([
        '每日500字翻译额度',
        '去除主界面广告',
      ]);
    }

    if (lvl >= 5) {
      basePrivileges.addAll([
        '每日2000字翻译额度',
        '优先客服支持',
        '多语言互译',
      ]);
    }

    if (lvl >= 8) {
      basePrivileges.addAll([
        '每日5000字翻译额度',
        '专属客服支持',
        '离线翻译功能',
      ]);
    }

    if (lvl >= 13) {
      basePrivileges.addAll([
        '每日10000字翻译额度',
        'API访问权限',
        '定制化主题',
      ]);
    }

    if (lvl >= 21) {
      basePrivileges.addAll([
        '每日20000字翻译额度',
        '优先功能体验',
        '批量翻译',
      ]);
    }

    if (lvl >= 34) {
      basePrivileges.addAll([
        '每日50000字翻译额度',
        '多账号管理',
        '团队协作功能',
      ]);
    }

    if (lvl >= 55) {
      basePrivileges.addAll([
        '每日100000字翻译额度',
        '专属客户经理',
        '企业级支持',
      ]);
    }

    if (lvl >= 89) {
      basePrivileges.addAll([
        '无限翻译额度',
        '7x24小时专属客服',
        '定制开发服务',
      ]);
    }

    if (lvl >= 144) {
      basePrivileges.addAll([
        '所有功能永久使用',
        '平台合作权益',
        '品牌联名机会',
      ]);
    }

    return basePrivileges;
  }

  /// 添加充值时长
  FibonacciMembershipInfo addHours(int hours) {
    return FibonacciMembershipInfo(
      totalHours: totalHours + hours,
      startDate: startDate ?? DateTime.now(),
    );
  }

  /// 从JSON创建
  factory FibonacciMembershipInfo.fromJson(Map<String, dynamic> json) {
    return FibonacciMembershipInfo(
      totalHours: json['totalHours'] as int? ?? 0,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : null,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'totalHours': totalHours,
      'startDate': startDate?.toIso8601String(),
    };
  }

  /// 创建免费用户
  factory FibonacciMembershipInfo.free() {
    return const FibonacciMembershipInfo(totalHours: 0);
  }

  @override
  String toString() {
    return 'FibonacciMembershipInfo(level: $level, title: $levelTitle, '
        'totalHours: $totalHours, progress: ${(progress * 100).toStringAsFixed(1)}%)';
  }
}

/// 会员等级显示卡片
class FibonacciLevelCard extends StatelessWidget {
  const FibonacciLevelCard({
    super.key,
    required this.membership,
    this.onRecharge,
    this.showDetails = true,
  });

  final FibonacciMembershipInfo membership;
  final VoidCallback? onRecharge;
  final bool showDetails;

  @override
  Widget build(BuildContext context) {
    final level = membership.level;
    final levelTitle = membership.levelTitle;
    final levelColor = membership.levelColor;
    final levelIcon = membership.levelIcon;
    final progress = membership.progress;
    final hoursToNext = membership.hoursToNextLevel;

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
          // 等级标签
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
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
                      _formatHours(membership.totalHours),
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
                    '下一级: LV.${membership.nextLevel}',
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
          if (showDetails) ...[
            const SizedBox(height: 16),
            _buildPrivilegesList(context),
          ],

          // 充值按钮
          if (onRecharge != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onRecharge,
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('充值时长'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: levelColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrivilegesList(BuildContext context) {
    final privileges = membership.privileges;
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
