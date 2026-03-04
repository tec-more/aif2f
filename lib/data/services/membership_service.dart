import 'package:aif2f/core/models/fibonacci_membership.dart';
import 'package:aif2f/data/services/api_client.dart';
import 'package:aif2f/core/config/api_config.dart';

/// 会员服务
/// 处理会员信息相关的业务逻辑
class MembershipService {
  late ApiClient _apiClient;

  MembershipService() {
    _apiClient = ApiClient();
    _apiClient.init();
  }

  /// 获取用户会员信息
  /// [userId] 用户ID
  /// 返回 FibonacciMembershipInfo 会员信息
  Future<FibonacciMembershipInfo> getMembershipInfo(int userId) async {
    try {
      // 调用后端API获取用户信息
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConfig.userDetailEndpoint(userId),
      );

      // 从响应中提取 total_hours
      final data = response.data ?? {};
      final totalHours = data['total_hours'] as int? ?? data['totalHours'] as int? ?? 0;
      final createdAtStr = data['created_at'] as String? ?? data['createdAt'] as String?;
      final createdAt = createdAtStr != null ? DateTime.parse(createdAtStr) : null;

      return FibonacciMembershipInfo(
        totalHours: totalHours,
        startDate: createdAt,
      );
    } catch (e) {
      // 如果获取失败，返回免费用户信息
      return FibonacciMembershipInfo.free();
    }
  }

  /// 更新用户充值时长
  /// [userId] 用户ID
  /// [hours] 充值小时数
  /// 返回是否更新成功
  Future<bool> updateMembershipHours(int userId, int hours) async {
    try {
      await _apiClient.patch<Map<String, dynamic>>(
        ApiConfig.userUpdateEndpoint(userId),
        data: {
          'total_hours': hours,
        },
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 增加用户充值时长
  /// [userId] 用户ID
  /// [additionalHours] 增加的小时数
  /// 返回是否更新成功
  Future<bool> addMembershipHours(int userId, int additionalHours) async {
    try {
      await _apiClient.patch<Map<String, dynamic>>(
        ApiConfig.userUpdateEndpoint(userId),
        data: {
          'add_hours': additionalHours,
        },
      );

      return true;
    } catch (e) {
      return false;
    }
  }
}
