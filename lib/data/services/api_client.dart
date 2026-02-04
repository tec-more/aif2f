import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:aif2f/core/config/api_config.dart';

/// API 客户端
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  late Dio _dio;
  bool _isInitialized = false;

  Dio get dio => _dio;

  /// 初始化
  void init({String? baseUrl, String? token}) {
    // 如果已经初始化过，只更新 token（如果提供）
    if (_isInitialized) {
      if (token != null) {
        _dio.options.headers['Authorization'] = 'Bearer $token';
      }
      return;
    }

    // 首次初始化
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl ?? ApiConfig.apiBaseUrl,
      connectTimeout: const Duration(milliseconds: ApiConfig.connectTimeout),
      receiveTimeout: const Duration(milliseconds: ApiConfig.receiveTimeout),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ));

    // 添加拦截器
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (kDebugMode) {
          print('🚀 API Request: ${options.method} ${options.uri}');
          print('📦 Headers: ${options.headers}');
          print('📝 Data: ${options.data}');
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          print('✅ API Response: ${response.statusCode} ${response.requestOptions.uri}');
          print('📦 Data: ${response.data}');
        }
        handler.next(response);
      },
      onError: (error, handler) {
        if (kDebugMode) {
          print('❌ API Error: ${error.requestOptions.uri}');
          print('📦 Error: ${error.message}');
          print('📦 Response: ${error.response}');
        }
        handler.next(error);
      },
    ));

    _isInitialized = true;
  }

  /// 设置 Token
  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// 清除 Token
  void clearToken() {
    _dio.options.headers.remove('Authorization');
  }

  /// GET 请求
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// POST 请求
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// PUT 请求
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// PATCH 请求
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// DELETE 请求
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}
