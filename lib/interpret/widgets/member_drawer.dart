import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:auto_route/auto_route.dart';
import 'package:aif2f/core/models/fibonacci_membership.dart';
import 'package:aif2f/core/router/app_router.dart';
import 'package:aif2f/data/providers/auth_provider.dart';
import 'package:aif2f/data/providers/membership_provider.dart';
import 'package:aif2f/data/providers/product_provider.dart';
import 'package:aif2f/data/models/product_model.dart';
import 'package:aif2f/data/models/payment_model.dart';
import 'package:aif2f/data/services/toast_service.dart';
import 'package:aif2f/data/services/product_service.dart';
import 'package:aif2f/core/widgets/payment_dialog.dart';
import 'package:aif2f/core/widgets/payment_method_dialog.dart';
import 'package:aif2f/core/widgets/member_popup.dart';
import 'package:aif2f/data/utils/auth_helper.dart';
import 'package:aif2f/user/view/member_center_page.dart';
import 'package:aif2f/user/view/settings_page.dart';
import 'package:aif2f/core/utils/app_info_util.dart';

/// 会员侧边抽屉菜单
/// 显示会员等级、累计时长和充值入口（基于Fibonacci数列）
class MemberDrawer extends ConsumerWidget {
  const MemberDrawer({
    super.key,
    this.onRecharge,
    this.onProfile,
    this.onSettings,
    this.onHelp,
    this.onAbout,
  });

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
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取认证状态
    final authState = ref.watch(authProvider);
    final isLoggedIn = authState.isAuthenticated;

    // 从 Provider 获取会员信息
    final info = ref.watch(currentMembershipProvider);
    final level = info.level;
    final levelTitle = info.levelTitle;
    final levelColor = info.levelColor;
    final levelIcon = info.levelIcon;
    final totalHours = info.totalHours;
    final hoursToNext = info.hoursToNextLevel;
    final progress = info.progress;

    // 从用户模型获取会员类型
    final user = authState.user;
    final membershipType = user?.membershipType ?? 'free';

    // 调试输出
    if (kDebugMode) {
      print('🔍 [MemberDrawer] 用户会员类型检查');
      print('👤 用户ID: ${user?.id}');
      print('📋 membershipType: $membershipType');
      print('📊 用户总时长: ${user?.totalHours}');
      print('🎖️ 计算等级: ${info.level}');
    }

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
                membershipType,
              ),

              const SizedBox(height: 16),

              // 充值入口卡片
              _buildRechargeSection(context, ref, info),

              const SizedBox(height: 16),

              // 菜单列表
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildMenuItem(
                      context,
                      icon: Icons.diamond_outlined,
                      title: '会员中心',
                      onTap: () {
                        Navigator.pop(context);
                        // 检查用户是否已登录
                        if (isLoggedIn) {
                          // 已登录，使用弹出窗口打开会员中心页面
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width * 0.9,
                                height:
                                    MediaQuery.of(context).size.height * 0.9,
                                child: const MemberCenterPage(),
                              ),
                            ),
                          );
                        } else {
                          // 未登录，显示登录对话框
                          checkLogin(context, ref);
                        }
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.security,
                      title: '设置',
                      onTap: () {
                        Navigator.pop(context);
                        // 使用弹出窗口打开设置页面
                        showDialog(
                          context: context,
                          builder: (context) => Dialog(
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.9,
                              height: MediaQuery.of(context).size.height * 0.9,
                              child: const SettingsPage(),
                            ),
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.help_outline,
                      title: '帮助与反馈',
                      onTap: () {
                        Navigator.pop(context);
                        // 显示帮助提示对话框
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('帮助与反馈'),
                            content: const Text('如有任何问题或建议，请联系客服。'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('确定'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.info_outline,
                      title: '关于',
                      onTap: () {
                        Navigator.pop(context);
                        // 显示关于对话框
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('关于 AI 传译'),
                            content: SingleChildScrollView(
                              child: FutureBuilder<String>(
                                future: AppInfoUtil.getVersion(),
                                builder: (context, snapshot) {
                                  final version = snapshot.data ?? 'v1.0.0';
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'AI 传译',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        '版本：v$version',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      const Text(
                                        '应用介绍',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'AI 传译是一款智能翻译应用，提供高质量的语音和文本翻译服务。',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        '主要功能',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildFeatureItem(
                                        '智能翻译',
                                        '基于先进 AI 技术的精准翻译',
                                      ),
                                      _buildFeatureItem('语音合成', '自然流畅的语音输出'),
                                      _buildFeatureItem('多语言支持', '支持全球多种主流语言'),
                                      _buildFeatureItem('离线翻译', '无网络环境也能使用'),
                                      const SizedBox(height: 16),
                                      const Text(
                                        '技术支持',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        '如有任何问题或建议，请联系我们的客服团队。',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(height: 24),
                                      Center(
                                        child: Text(
                                          '© ${DateTime.now().year} All Rights Reserved',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('关闭'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    isLoggedIn
                        ? _buildMenuItem(
                            context,
                            icon: Icons.logout,
                            title: '退出登录',
                            onTap: () async {
                              await _handleLogout(context, ref);
                            },
                          )
                        : _buildMenuItem(
                            context,
                            icon: Icons.login,
                            title: '登录',
                            onTap: () {
                              Navigator.pop(context);
                              // 显示登录对话框
                              checkLogin(context, ref);
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

  /// 构建功能项
  Widget _buildFeatureItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 20, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
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
    String membershipType,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [levelColor, levelColor.withOpacity(0.7)],
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
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
                    Icon(levelIcon, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'LV.$level',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // 累计时长和VIP徽章
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 累计时长显示（可压缩）
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: Colors.white,
                            size: 11,
                          ),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              _formatHours(totalHours),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // VIP徽章（不可压缩）
                  _buildTencentStyleVipBadge(
                    isVip: membershipType == 'vip',
                    onVipTap: () {
                      _showMembershipPurchaseDialog(context, 'VIP会员');
                    },
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

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
        ],
      ),
    );
  }

  /// 构建腾讯风格VIP徽章
  Widget _buildTencentStyleVipBadge({
    required bool isVip,
    required VoidCallback onVipTap,
  }) {
    return GestureDetector(
      onTap: onVipTap,
      child: _buildVipBadge(
        label: 'VIP',
        isActive: isVip,
        icon: Icons.diamond,
      ),
    );
  }

  /// 构建单个VIP徽章
  Widget _buildVipBadge({
    required String label,
    required bool isActive,
    required IconData icon,
  }) {
    return Container(
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        gradient: isActive
            ? const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  const Color(0xFFFF6B6B),
                  const Color(0xFFEE5A5A),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: isActive ? Colors.white.withOpacity(0.8) : Colors.white.withOpacity(0.5),
          width: 1.2,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(0.4),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ]
            : [
                BoxShadow(
                  color: const Color(0xFFFF6B6B).withOpacity(0.3),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isActive) ...[
            Icon(
              icon,
              color: const Color(0xFFFFD700),
              size: 8,
              shadows: const [
                Shadow(
                  color: Colors.black45,
                  offset: Offset(0, 0.5),
                  blurRadius: 1,
                ),
              ],
            ),
            const SizedBox(width: 1),
          ] else ...[
            Icon(
              Icons.lock,
              color: Colors.white,
              size: 7,
              shadows: const [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(0, 0.5),
                  blurRadius: 1,
                ),
              ],
            ),
            const SizedBox(width: 1),
          ],
          Text(
            label,
            style: TextStyle(
              color: isActive ? const Color(0xFFFFD700) : Colors.white,
              fontSize: 8,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
              letterSpacing: 0.2,
              height: 1.0,
              shadows: isActive
                  ? const [
                      Shadow(
                        color: Colors.black54,
                        offset: Offset(0, 0.5),
                        blurRadius: 2,
                      ),
                    ]
                  : const [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(0, 0.5),
                        blurRadius: 1,
                      ),
                    ],
            ),
          ),
        ],
      ),
    );
  }

  /// 显示会员购买对话框
  void _showMembershipPurchaseDialog(BuildContext context, String membershipType) {
    // 判断需要购买哪种会员
    final isSvip = membershipType == 'SVIP会员';

    showDialog(
      context: context,
      builder: (context) => _MembershipPurchaseDialog(
        membershipType: membershipType,
        isSvip: isSvip,
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

  /// 构建充值区域 - 从后端获取产品列表
  Widget _buildRechargeSection(
    BuildContext context,
    WidgetRef ref,
    FibonacciMembershipInfo info,
  ) {
    final products = ref.watch(productsProvider);

    if (products.isEmpty) {
      return const SizedBox.shrink();
    }

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

              // 产品列表
              ...products.map((product) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildProductOption(context, ref, product, info),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建产品充值选项
  Widget _buildProductOption(
    BuildContext context,
    WidgetRef ref,
    ProductModel product,
    FibonacciMembershipInfo currentInfo,
  ) {
    // 计算充值后的等级
    final newTotalHours = currentInfo.totalHours + product.totalHours;
    final newLevel = FibonacciMembershipSystem.getLevelFromHours(newTotalHours);
    final currentLevel = currentInfo.level;

    return InkWell(
      onTap: () {
        // 显示支付方式选择对话框
        showDialog(
          context: context,
          builder: (context) => PaymentMethodDialog(product: product),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.primaryContainer.withOpacity(0.1),
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
                        product.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      if (product.hasDiscount)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            product.discount ?? '优惠',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (newLevel > currentLevel)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
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
                  Row(
                    children: [
                      Text(
                        '${product.hours}小时',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (product.bonusHours != null &&
                          product.bonusHours! > 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          '+${product.bonusHours}小时赠送',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      if (product.hasDiscount) ...[
                        const SizedBox(width: 8),
                        Text(
                          '¥${product.originalPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '¥${product.price.toStringAsFixed(0)}',
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  /// 构建底部版本信息
  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Divider(color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: 8),
          FutureBuilder<String>(
            future: AppInfoUtil.getVersion(),
            builder: (context, snapshot) {
              final version = snapshot.data ?? '1.0.0';
              return Text(
                'AI 传译 v$version',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            '© ${DateTime.now().year} All Rights Reserved',
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// 处理退出登录
  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    // 显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('确定要退出登录吗？'),
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

    if (confirmed == true) {
      // 执行退出登录
      await ref.read(authProvider.notifier).logout();

      if (context.mounted) {
        Navigator.pop(context); // 关闭抽屉
        toastService.showSuccess('已退出登录');
      }
    }
  }
}

/// 会员购买对话框
class _MembershipPurchaseDialog extends ConsumerStatefulWidget {
  const _MembershipPurchaseDialog({
    required this.membershipType,
    required this.isSvip,
  });

  final String membershipType;
  final bool isSvip;

  @override
  ConsumerState<_MembershipPurchaseDialog> createState() =>
      _MembershipPurchaseDialogState();
}

class _MembershipPurchaseDialogState extends ConsumerState<_MembershipPurchaseDialog> {
  ProductModel? _selectedProduct;
  List<ProductModel> _allProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllProducts();
  }

  Future<void> _loadAllProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 直接从API获取所有产品（不经过productsProvider过滤）
      final service = ProductService();
      _allProducts = await service.getAllProducts();

      // 自动选择对应的产品
      final membershipProducts = _allProducts.where((p) => p.productType == 'item').toList();

      for (final product in membershipProducts) {
        final isSvipProduct = product.name.toLowerCase().contains('svip');
        if (widget.isSvip && isSvipProduct) {
          _selectedProduct = product;
          break;
        } else if (!widget.isSvip && product.name.toLowerCase().contains('vip') && !isSvipProduct) {
          _selectedProduct = product;
          break;
        }
      }
    } catch (e) {
      print('❌ [_MembershipPurchaseDialog] 加载产品失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(40),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    // 过滤出会员类型的产品（product_type == "item"）
    final membershipProducts = _allProducts.where((product) => product.productType == 'item').toList();

    // 根据会员类型进一步过滤
    final filteredProducts = membershipProducts.where((product) {
      final isSvipProduct = product.name.toLowerCase().contains('svip');
      return widget.isSvip ? isSvipProduct : product.name.toLowerCase().contains('vip') && !isSvipProduct;
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 头部
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.isSvip
                      ? [const Color(0xFFFFD700), const Color(0xFFFFA500)]
                      : [const Color(0xFF9C27B0), const Color(0xFF7B1FA2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.isSvip ? Icons.diamond : Icons.card_membership,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.membershipType,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.isSvip ? '尊享365天会员权益' : '尊享30天会员权益',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // 产品列表
            if (filteredProducts.isEmpty)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Text('暂无可用产品'),
              )
            else
              ...filteredProducts.map((product) => _buildProductCard(context, product)),

            // 底部按钮
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedProduct != null
                      ? () => _purchaseMembership(context, _selectedProduct!)
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: widget.isSvip
                        ? const Color(0xFFFFD700)
                        : const Color(0xFF9C27B0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _selectedProduct != null
                        ? '立即购买 ¥${_selectedProduct!.price.toStringAsFixed(2)}'
                        : '请选择产品',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, ProductModel product) {
    final isSelected = _selectedProduct?.id == product.id;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedProduct = product;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? (widget.isSvip
                  ? const Color(0xFFFFD700).withOpacity(0.1)
                  : const Color(0xFF9C27B0).withOpacity(0.1))
              : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (widget.isSvip
                    ? const Color(0xFFFFD700)
                    : const Color(0xFF9C27B0))
                : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              widget.isSvip ? Icons.diamond : Icons.card_membership,
              color: isSelected
                  ? (widget.isSvip
                      ? const Color(0xFFFFD700)
                      : const Color(0xFF9C27B0))
                  : Colors.grey,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? (widget.isSvip
                              ? const Color(0xFFFFD700)
                              : const Color(0xFF9C27B0))
                          : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (product.bonusHours != null && product.bonusHours! > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '+${product.bonusHours}小时赠送',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '¥${product.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: widget.isSvip
                        ? const Color(0xFFFFD700)
                        : const Color(0xFF9C27B0),
                  ),
                ),
                if (product.hasDiscount) ...[
                  const SizedBox(height: 2),
                  Text(
                    '¥${product.originalPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ],
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: widget.isSvip
                    ? const Color(0xFFFFD700)
                    : const Color(0xFF9C27B0),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _purchaseMembership(BuildContext context, ProductModel product) async {
    // 显示支付方式选择对话框
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => PaymentMethodDialog(product: product),
      );
    }
  }
}

