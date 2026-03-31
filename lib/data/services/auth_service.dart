import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:aif2f/data/models/user_model.dart';
import 'package:aif2f/data/models/payment_model.dart';
import 'package:aif2f/data/services/api_client.dart';

/// 认证服务
class AuthService {
  final ApiClient _apiClient = ApiClient();

  /// 用户注册
  Future<TokenResponse> register(RegisterRequest request) async {
    try {
      if (kDebugMode) {
        print('📝 开始注册请求');
        print('请求数据: ${request.toJson()}');
      }

      final response = await _apiClient.post(
        '/customer/auth/register',
        data: request.toJson(),
      );

      if (kDebugMode) {
        print('✅ 注册响应状态码: ${response.statusCode}');
        print('📦 响应数据: ${response.data}');
      }

      if (kDebugMode) {
        print('📋 [AuthService] 原始响应数据类型: ${response.data.runtimeType}');
        print('📋 [AuthService] 原始响应数据: ${response.data}');
      }

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );

      if (kDebugMode) {
        print('📊 API响应解析 - success: ${apiResponse.success}, code: ${apiResponse.code}, msg: ${apiResponse.msg}');
        print('📦 API响应数据类型: ${apiResponse.data.runtimeType}');
        print('📦 API响应数据内容: ${apiResponse.data}');
      }

      if (!apiResponse.success && apiResponse.code != 0) {
        if (kDebugMode) print('❌ 注册失败: ${apiResponse.msg}');
        throw Exception(apiResponse.msg ?? '注册失败');
      }

      // 从 data 中提取 token 和 user
      if (apiResponse.data != null) {
        if (kDebugMode) {
          print('✅ 注册成功，提取token和用户信息');
          print('🔍 data 字段包含的键: ${(apiResponse.data! as Map<String, dynamic>).keys.toList()}');
        }
        return TokenResponse.fromJson(apiResponse.data!);
      }

      // 如果 data 为 null，说明可能直接返回了 user
      if (kDebugMode) print('❌ 注册响应格式错误: data为null');
      throw Exception('注册响应格式错误');
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ DioException异常: ${e.message}');
        print('❌ 错误类型: ${e.type}');
        print('❌ 错误响应: ${e.response?.data}');
      }
      throw _handleDioError(e);
    }
  }

  /// 客户登录（使用邮箱）
  Future<TokenResponse> customerLogin(CustomerLogin request) async {
    try {
      if (kDebugMode) {
        print('🔐 [AuthService] 开始客户登录请求');
        print('📧 邮箱: ${request.email}');
        print('🔑 密码: ${request.password.isNotEmpty ? "***" : ""}');
      }

      final response = await _apiClient.post(
        '/customer/auth/login',
        data: request.toJson(),
      );

      if (kDebugMode) {
        print('✅ [AuthService] 登录响应状态码: ${response.statusCode}');
        print('📦 [AuthService] 响应数据: ${response.data}');
      }

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );

      if (!apiResponse.success && apiResponse.code != 0) {
        throw Exception(apiResponse.msg ?? '登录失败');
      }

      if (apiResponse.data != null) {
        return TokenResponse.fromJson(apiResponse.data!);
      }

      throw Exception('登录响应格式错误');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 客户验证码登录
  Future<TokenResponse> customerLoginCode(CustomerLoginCode request) async {
    try {
      final response = await _apiClient.post(
        '/customer/auth/login-code',
        data: request.toJson(),
      );

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );

      if (!apiResponse.success && apiResponse.code != 0) {
        throw Exception(apiResponse.msg ?? '登录失败');
      }

      if (apiResponse.data != null) {
        return TokenResponse.fromJson(apiResponse.data!);
      }

      throw Exception('登录响应格式错误');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 用户登录（旧接口，保留兼容）
  Future<TokenResponse> login(LoginRequest request) async {
    try {
      final response = await _apiClient.post(
        '/auth/login',
        data: request.toJson(),
      );

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );

      if (!apiResponse.success && apiResponse.code != 0) {
        throw Exception(apiResponse.msg ?? '登录失败');
      }

      if (apiResponse.data != null) {
        return TokenResponse.fromJson(apiResponse.data!);
      }

      throw Exception('登录响应格式错误');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 获取当前用户信息
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _apiClient.get('/customer/auth/me');

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );

      if (!apiResponse.success && apiResponse.code != 0) {
        throw Exception(apiResponse.msg ?? '获取用户信息失败');
      }

      if (apiResponse.data != null) {
        return UserModel.fromJson(apiResponse.data!);
      }

      throw Exception('用户信息响应格式错误');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 修改密码
  Future<String> changePassword(ChangePasswordRequest request) async {
    try {
      final response = await _apiClient.post(
        '/customer/auth/change-password',
        data: request.toJson(),
      );

      final apiResponse = ApiResponse<dynamic>.fromJson(
        response.data,
        null,
      );

      if (!apiResponse.success && apiResponse.code != 0) {
        throw Exception(apiResponse.msg ?? '修改密码失败');
      }

      return apiResponse.msg ?? '修改密码成功';
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 用户登出
  Future<String> logout() async {
    try {
      final response = await _apiClient.post('/customer/auth/logout');

      final apiResponse = ApiResponse<dynamic>.fromJson(
        response.data,
        null,
      );

      return apiResponse.msg ?? '登出成功';
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException error) {
    String message;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = '网络连接超时，请检查网络设置';
        break;
      case DioExceptionType.badResponse:
        // 尝试从响应体中提取 API 返回的错误消息
        final responseData = error.response?.data;
        if (responseData is Map<String, dynamic>) {
          // 优先使用 API 返回的 msg 字段
          if (responseData['msg'] is String && (responseData['msg'] as String).isNotEmpty) {
            message = responseData['msg'] as String;
            if (kDebugMode) {
              print('📋 使用API返回的msg: $message');
            }
            return Exception(message);
          }
        }

        // 如果没有找到 msg 字段，使用状态码默认消息
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) {
          message = '未授权，请重新登录';
        } else if (statusCode == 403) {
          message = '没有权限访问';
        } else if (statusCode == 404) {
          message = '请求的资源不存在';
        } else if (statusCode == 500) {
          message = '服务器错误，请稍后重试';
        } else {
          message = '网络请求错误: $statusCode';
        }
        break;
      case DioExceptionType.cancel:
        message = '请求已取消';
        break;
      case DioExceptionType.connectionError:
        message = '网络连接失败，请检查网络设置';
        break;
      default:
        message = '未知错误: ${error.message}';
    }

    return Exception(message);
  }
}
