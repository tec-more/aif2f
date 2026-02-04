import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:aif2f/data/services/api_client.dart';
import 'package:aif2f/data/models/verification_model.dart';

/// 验证码服务
class VerificationService {
  late final ApiClient _apiClient;

  VerificationService() {
    _apiClient = ApiClient()..init();
  }

  /// 发送验证码
  Future<VerificationCodeResponse> sendVerificationCode({
    required String email,
    required VerificationCodeType type,
  }) async {
    try {
      final response = await _apiClient.post(
        '/customer/auth/send-code',
        data: {
          'email': email,
          'type': type.name,
        },
        options: Options(
          receiveTimeout: const Duration(milliseconds: 30000), // 邮件发送需要更长时间，30秒
          sendTimeout: const Duration(milliseconds: 30000),
        ),
      );

      if (kDebugMode) {
        print('✅ 验证码发送成功: ${response.data}');
      }

      // 直接从 API 响应中提取数据
      final data = response.data['data'];
      if (data != null) {
        return VerificationCodeResponse(
          success: true,
          message: response.data['msg'] ?? '验证码已发送',
          expiresIn: data['expires_in'] as int?,
        );
      }

      return VerificationCodeResponse(
        success: true,
        message: response.data['msg'] ?? '验证码已发送',
      );
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ 发送验证码失败: $e');
        print('❌ 错误响应: ${e.response?.data}');
      }
      if (e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        // 邮件发送可能成功，但响应超时
        throw Exception('邮件发送中，请稍后查收邮箱（如未收到，请等待1分钟后重试）');
      }
      if (e.response != null) {
        String msg = e.response?.data['msg'] ?? e.response?.data['message'] ?? '发送验证码失败';

        // 清理技术性前缀（如 _dio@xxxxxx）
        msg = msg.replaceAll(RegExp(r'_dio@\w+:\s*'), '');
        msg = msg.trim();

        // 改进常见错误的提示信息
        if (msg.contains('have been init') || msg.contains('already') || msg.contains('已发送')) {
          msg = '验证码已发送，请查收邮箱（有效期5分钟）';
        } else if (msg.contains('too frequently') || msg.contains('too often')) {
          msg = '发送过于频繁，请稍后再试';
        }

        throw Exception(msg);
      }
      throw Exception('网络错误，请检查网络连接');
    } catch (e) {
      if (kDebugMode) {
        print('❌ 发送验证码异常: $e');
      }
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// 验证验证码
  Future<bool> verifyCode({
    required String email,
    required String code,
    required VerificationCodeType type,
  }) async {
    try {
      final response = await _apiClient.post(
        '/auth/verify-code',
        data: {
          'email': email,
          'code': code,
          'type': type.name,
        },
      );

      if (kDebugMode) {
        print('✅ 验证码验证成功: ${response.data}');
      }

      return response.data['success'] as bool? ??
             response.data['valid'] as bool? ??
             response.data['data']?['valid'] as bool? ?? true;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ 验证码验证失败: $e');
      }
      if (e.response != null) {
        throw Exception(e.response?.data['msg'] ?? '验证码验证失败');
      }
      throw Exception('网络错误，请检查网络连接');
    } catch (e) {
      if (kDebugMode) {
        print('❌ 验证码验证异常: $e');
      }
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}
