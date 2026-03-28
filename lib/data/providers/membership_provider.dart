import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aif2f/core/models/fibonacci_membership.dart';
import 'package:aif2f/data/providers/auth_provider.dart';
import 'package:aif2f/data/services/membership_service.dart';

/// 会员服务 Provider
final membershipServiceProvider = Provider<MembershipService>((ref) {
  return MembershipService();
});

/// 会员信息状态类
class MembershipState {
  final FibonacciMembershipInfo? membershipInfo;
  final bool isLoading;
  final String? errorMessage;

  MembershipState({
    this.membershipInfo,
    this.isLoading = false,
    this.errorMessage,
  });

  MembershipState copyWith({
    FibonacciMembershipInfo? membershipInfo,
    bool? isLoading,
    String? errorMessage,
  }) {
    return MembershipState(
      membershipInfo: membershipInfo ?? this.membershipInfo,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// 会员信息 Notifier
class MembershipNotifier extends Notifier<MembershipState> {
  @override
  MembershipState build() {
    // 延迟初始化，避免在 build() 中读取 authProvider 造成循环依赖
    Future.microtask(() {
      _initFromUser();
    });
    return MembershipState(
      membershipInfo: FibonacciMembershipInfo.free(),
      isLoading: false,
    );
  }

  MembershipService get _service => ref.read(membershipServiceProvider);
  AuthState get _authState => ref.read(authProvider);

  /// 从用户信息初始化会员数据
  void _initFromUser() {
    final user = _authState.user;
    if (kDebugMode) {
      print('🔄 [MembershipProvider] _initFromUser - User: ${user?.username}, totalHours: ${user?.totalHours}');
    }
    if (user != null) {
      final membershipInfo = FibonacciMembershipInfo(
        totalHours: user.totalHours,
        startDate: user.createdAt,
      );
      state = state.copyWith(membershipInfo: membershipInfo);
      if (kDebugMode) {
        print('✅ [MembershipProvider] 会员等级: LV.${membershipInfo.level} - ${membershipInfo.levelTitle}');
      }
    } else {
      // 未登录状态，使用免费用户
      state = state.copyWith(membershipInfo: FibonacciMembershipInfo.free());
      if (kDebugMode) {
        print('⚠️ [MembershipProvider] 未登录，使用免费用户信息');
      }
    }
  }

  /// 获取会员信息
  Future<void> fetchMembershipInfo() async {
    final user = _authState.user;
    if (user == null) {
      state = state.copyWith(membershipInfo: FibonacciMembershipInfo.free());
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final info = await _service.getMembershipInfo(user.id);
      state = state.copyWith(
        membershipInfo: info,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// 添加充值时长（小时）
  void addHours(int hours) {
    final currentInfo = state.membershipInfo ?? FibonacciMembershipInfo.free();
    final newInfo = currentInfo.addHours(hours);
    state = state.copyWith(membershipInfo: newInfo);
  }

  /// 清除会员信息（用于登出）
  void clear() {
    state = state.copyWith(membershipInfo: FibonacciMembershipInfo.free());
  }

  /// 刷新会员信息（从用户信息重新加载）
  Future<void> refresh() async {
    final user = _authState.user;
    if (kDebugMode) {
      print('════════════════════════════════════════');
      print('🔄 [MembershipProvider] 开始刷新会员信息');
      print('👤 [MembershipProvider] 用户ID: ${user?.id}, 用户名: ${user?.username}');
      print('📊 [MembershipProvider] 用户totalHours: ${user?.totalHours}');
      print('════════════════════════════════════════');
    }

    if (user == null) {
      state = state.copyWith(membershipInfo: FibonacciMembershipInfo.free());
      if (kDebugMode) {
        print('⚠️ [MembershipProvider] 用户为null，使用免费用户信息');
      }
      return;
    }

    // 直接使用用户信息中的 totalHours（已经从 membership.total_hours 解析）
    _initFromUser();

    if (kDebugMode) {
      final membershipInfo = state.membershipInfo ?? FibonacciMembershipInfo.free();
      print('✅ [MembershipProvider] 会员信息刷新完成');
      print('📊 [MembershipProvider] 累计时长: ${membershipInfo.totalHours} 小时');
      print('📊 [MembershipProvider] 会员等级: LV.${membershipInfo.level} - ${membershipInfo.levelTitle}');
      print('════════════════════════════════════════');
    }
  }
}

/// 会员信息 State Provider
final membershipProvider = NotifierProvider<MembershipNotifier, MembershipState>(MembershipNotifier.new);

/// 便捷访问：当前会员信息
final currentMembershipProvider = Provider<FibonacciMembershipInfo>((ref) {
  final state = ref.watch(membershipProvider);
  final info = state.membershipInfo ?? FibonacciMembershipInfo.free();
  if (kDebugMode) {
    print('🔄 [currentMembershipProvider] Provider 被访问，返回: LV.${info.level}, ${info.totalHours}小时');
  }
  return info;
});

/// 便捷访问：是否为免费用户（LV.0）
final isFreeUserProvider = Provider<bool>((ref) {
  final membership = ref.watch(currentMembershipProvider);
  return membership.level == 0;
});

/// 便捷访问：用户等级
final userLevelProvider = Provider<int>((ref) {
  final membership = ref.watch(currentMembershipProvider);
  return membership.level;
});

/// 便捷访问：等级称号
final userLevelTitleProvider = Provider<String>((ref) {
  final membership = ref.watch(currentMembershipProvider);
  return membership.levelTitle;
});
