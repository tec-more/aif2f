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
    // 初始化时从用户信息中加载会员数据
    _initFromUser();
    return MembershipState(
      membershipInfo: null,
      isLoading: false,
    );
  }

  MembershipService get _service => ref.read(membershipServiceProvider);
  AuthState get _authState => ref.read(authProvider);

  /// 从用户信息初始化会员数据
  void _initFromUser() {
    final user = _authState.user;
    if (user != null) {
      final membershipInfo = FibonacciMembershipInfo(
        totalHours: user.totalHours,
        startDate: user.createdAt,
      );
      state = state.copyWith(membershipInfo: membershipInfo);
    } else {
      // 未登录状态，使用免费用户
      state = state.copyWith(membershipInfo: FibonacciMembershipInfo.free());
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
  void refresh() {
    _initFromUser();
  }
}

/// 会员信息 State Provider
final membershipProvider = NotifierProvider<MembershipNotifier, MembershipState>(MembershipNotifier.new);

/// 便捷访问：当前会员信息
final currentMembershipProvider = Provider<FibonacciMembershipInfo>((ref) {
  final state = ref.watch(membershipProvider);
  return state.membershipInfo ?? FibonacciMembershipInfo.free();
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
