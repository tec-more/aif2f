import 'package:flutter/material.dart';

/// 会员套餐等级系统
/// 根据充值时长确定会员等级

/// 会员等级枚举
enum MembershipLevel {
  /// 体验会员（7天）
  trial,

  /// 月度会员（30天）
  monthly,

  /// 季度会员（90天）
  quarterly,

  /// 半年会员（180天）
  halfYearly,

  /// 年度会员（365天）
  yearly,

  /// 终身会员（永久）
  lifetime;

  /// 获取显示名称
  String get displayName {
    switch (this) {
      case MembershipLevel.trial:
        return '体验会员';
      case MembershipLevel.monthly:
        return '月度会员';
      case MembershipLevel.quarterly:
        return '季度会员';
      case MembershipLevel.halfYearly:
        return '半年会员';
      case MembershipLevel.yearly:
        return '年度会员';
      case MembershipLevel.lifetime:
        return '终身会员';
    }
  }

  /// 获取会员时长
  Duration get duration {
    switch (this) {
      case MembershipLevel.trial:
        return Duration(days: 7);
      case MembershipLevel.monthly:
        return Duration(days: 30);
      case MembershipLevel.quarterly:
        return Duration(days: 90);
      case MembershipLevel.halfYearly:
        return Duration(days: 180);
      case MembershipLevel.yearly:
        return Duration(days: 365);
      case MembershipLevel.lifetime:
        return Duration(days: 365 * 100);
    }
  }

  /// 获取价格
  double get price {
    switch (this) {
      case MembershipLevel.trial:
        return 9.9;
      case MembershipLevel.monthly:
        return 29.0;
      case MembershipLevel.quarterly:
        return 79.0;
      case MembershipLevel.halfYearly:
        return 149.0;
      case MembershipLevel.yearly:
        return 299.0;
      case MembershipLevel.lifetime:
        return 999.0;
    }
  }

  /// 获取会员权益列表
  List<String> get features {
    switch (this) {
      case MembershipLevel.trial:
        return [
          '基础翻译功能',
          '每日1000字翻译额度',
          '标准客服支持',
        ];
      case MembershipLevel.monthly:
        return [
          '基础翻译功能',
          '每日5000字翻译额度',
          '优先客服支持',
          '去除广告',
        ];
      case MembershipLevel.quarterly:
        return [
          '完整翻译功能',
          '每日10000字翻译额度',
          '专属客服支持',
          '去除广告',
          '多语言互译',
        ];
      case MembershipLevel.halfYearly:
        return [
          '完整翻译功能',
          '每日20000字翻译额度',
          '专属客服支持',
          '去除广告',
          '多语言互译',
          '离线翻译',
        ];
      case MembershipLevel.yearly:
        return [
          '完整翻译功能',
          '无限翻译额度',
          '7x24小时专属客服',
          '去除广告',
          '多语言互译',
          '离线翻译',
          'API访问权限',
          '优先功能体验',
        ];
      case MembershipLevel.lifetime:
        return [
          '所有功能永久使用',
          '无限翻译额度',
          '7x24小时专属客服',
          '去除所有广告',
          '所有语言互译',
          '离线翻译',
          '完整API访问权限',
          '优先功能体验',
          '定制化服务',
          '专属会员社群',
        ];
    }
  }

  /// 获取图标
  IconData get icon {
    switch (this) {
      case MembershipLevel.trial:
        return Icons.card_membership;
      case MembershipLevel.monthly:
        return Icons.calendar_today;
      case MembershipLevel.quarterly:
        return Icons.date_range;
      case MembershipLevel.halfYearly:
        return Icons.event;
      case MembershipLevel.yearly:
        return Icons.workspace_premium;
      case MembershipLevel.lifetime:
        return Icons.verified;
    }
  }

  /// 获取主题颜色
  Color get color {
    switch (this) {
      case MembershipLevel.trial:
        return Colors.grey;
      case MembershipLevel.monthly:
        return Colors.blue;
      case MembershipLevel.quarterly:
        return Colors.purple;
      case MembershipLevel.halfYearly:
        return Colors.orange;
      case MembershipLevel.yearly:
        return Colors.amber;
      case MembershipLevel.lifetime:
        return Colors.red;
    }
  }

  /// 是否推荐
  bool get isRecommended {
    switch (this) {
      case MembershipLevel.yearly:
        return true;
      default:
        return false;
    }
  }

  /// 计算到期日期
  DateTime getExpiryDate({DateTime? startDate}) {
    final start = startDate ?? DateTime.now();
    return start.add(duration);
  }

  /// 获取时长描述
  String get durationDescription {
    final days = duration.inDays;
    if (days >= 365 * 100) return '永久';
    if (days >= 365) return '${days ~/ 365}年';
    if (days >= 30) return '${days ~/ 30}个月';
    return '$days天';
  }

  /// 获取节省百分比（相对于月度会员）
  double get savings {
    final monthlyPrice = MembershipLevel.monthly.price;
    final months = duration.inDays / 30;
    final originalPrice = monthlyPrice * months;
    final discount = ((originalPrice - price) / originalPrice * 100);
    return discount > 0 ? discount : 0;
  }

  /// 判断是否为高级会员（季度及以上）
  bool get isPremium => index >= MembershipLevel.quarterly.index;

  /// 判断是否为VIP会员（年度及以上）
  bool get isVip => index >= MembershipLevel.yearly.index;

  /// 根据时长获取对应的会员等级
  static MembershipLevel fromDuration(Duration duration) {
    final days = duration.inDays;

    if (days >= 365 * 100) return MembershipLevel.lifetime;
    if (days >= 365) return MembershipLevel.yearly;
    if (days >= 180) return MembershipLevel.halfYearly;
    if (days >= 90) return MembershipLevel.quarterly;
    if (days >= 30) return MembershipLevel.monthly;
    if (days >= 7) return MembershipLevel.trial;

    // 默认返回体验会员
    return MembershipLevel.trial;
  }

  /// 获取所有可购买的套餐
  static List<MembershipLevel> get purchasablePackages => [
    MembershipLevel.trial,
    MembershipLevel.monthly,
    MembershipLevel.quarterly,
    MembershipLevel.halfYearly,
    MembershipLevel.yearly,
    MembershipLevel.lifetime,
  ];

  /// 获取推荐套餐
  static MembershipLevel get recommendedPackage => MembershipLevel.yearly;
}

/// 会员信息数据类
class MembershipInfo {
  const MembershipInfo({
    required this.level,
    required this.expiryDate,
    this.startDate,
  });

  /// 会员等级
  final MembershipLevel level;

  /// 到期日期
  final DateTime expiryDate;

  /// 开始日期（可选，默认为当前时间）
  final DateTime? startDate;

  /// 计算剩余天数
  int get remainingDays {
    final now = DateTime.now();
    if (now.isAfter(expiryDate)) return 0;
    return expiryDate.difference(now).inDays;
  }

  /// 判断是否已过期
  bool get isExpired {
    return DateTime.now().isAfter(expiryDate);
  }

  /// 判断是否为高级会员
  bool get isPremium => level.isPremium;

  /// 判断是否为VIP会员
  bool get isVip => level.isVip;

  /// 创建默认的免费体验会员
  factory MembershipInfo.freeTrial() {
    return MembershipInfo(
      level: MembershipLevel.trial,
      expiryDate: MembershipLevel.trial.getExpiryDate(),
      startDate: DateTime.now(),
    );
  }

  /// 从JSON解析
  factory MembershipInfo.fromJson(Map<String, dynamic> json) {
    return MembershipInfo(
      level: MembershipLevel.values.firstWhere(
        (level) => level.name == json['level'],
        orElse: () => MembershipLevel.trial,
      ),
      expiryDate: DateTime.parse(json['expiryDate']),
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : null,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'level': level.name,
      'expiryDate': expiryDate.toIso8601String(),
      'startDate': startDate?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'MembershipInfo(level: ${level.displayName}, '
        'expiry: ${expiryDate.toIso8601String()}, '
        'remainingDays: $remainingDays)';
  }
}
