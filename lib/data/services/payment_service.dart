import 'package:dio/dio.dart';
import 'package:aif2f/data/models/payment_model.dart';
import 'package:aif2f/data/services/api_client.dart';

/// 支付服务
class PaymentService {
  final ApiClient _apiClient = ApiClient();

  /// 创建支付宝支付订单
  Future<PaymentOrder> createAlipayOrder(CreatePaymentOrderRequest request) async {
    try {
      final response = await _apiClient.post(
        '/pay/alipay/orders',
        data: request.toJson(),
      );

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );

      if (!apiResponse.success && apiResponse.code != 0) {
        throw Exception(apiResponse.msg ?? '创建支付订单失败');
      }

      // 后端返回的数据结构: { code: 0, msg: success, data: { order_id, qr_code, ... } }
      if (apiResponse.data != null) {
        return PaymentOrder.fromJson(apiResponse.data!, PaymentType.alipay);
      }

      throw Exception('支付订单响应格式错误');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 查询支付宝订单
  Future<PaymentOrder> queryAlipayOrder(String orderId) async {
    try {
      final response = await _apiClient.get('/pay/alipay/orders/$orderId');

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );

      if (!apiResponse.success && apiResponse.code != 0) {
        throw Exception(apiResponse.msg ?? '查询订单失败');
      }

      if (apiResponse.data != null) {
        return PaymentOrder.fromJson(apiResponse.data!, PaymentType.alipay);
      }

      throw Exception('订单响应格式错误');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 支付宝退款
  Future<Map<String, dynamic>> refundAlipay(RefundRequest request) async {
    try {
      final response = await _apiClient.post(
        '/pay/alipay/refunds',
        data: request.toJson(),
      );

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );

      if (!apiResponse.success && apiResponse.code != 0) {
        throw Exception(apiResponse.msg ?? '退款失败');
      }

      return apiResponse.data ?? {};
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 创建微信支付订单
  Future<PaymentOrder> createWechatOrder(CreatePaymentOrderRequest request) async {
    try {
      final response = await _apiClient.post(
        '/pay/wechat/orders',
        data: request.toJson(),
      );

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );

      if (!apiResponse.success && apiResponse.code != 0) {
        throw Exception(apiResponse.msg ?? '创建支付订单失败');
      }

      if (apiResponse.data != null) {
        return PaymentOrder.fromJson(apiResponse.data!, PaymentType.wechat);
      }

      throw Exception('支付订单响应格式错误');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 查询微信支付订单
  Future<PaymentOrder> queryWechatOrder(String orderId) async {
    try {
      final response = await _apiClient.get('/pay/wechat/orders/$orderId');

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );

      if (!apiResponse.success && apiResponse.code != 0) {
        throw Exception(apiResponse.msg ?? '查询订单失败');
      }

      if (apiResponse.data != null) {
        return PaymentOrder.fromJson(apiResponse.data!, PaymentType.wechat);
      }

      throw Exception('订单响应格式错误');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 微信支付退款
  Future<Map<String, dynamic>> refundWechat(RefundRequest request) async {
    try {
      final response = await _apiClient.post(
        '/pay/wechat/refunds',
        data: request.toJson(),
      );

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );

      if (!apiResponse.success && apiResponse.code != 0) {
        throw Exception(apiResponse.msg ?? '退款失败');
      }

      return apiResponse.data ?? {};
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 轮询查询订单状态
  Future<PaymentOrder> pollOrderStatus(
    String orderId,
    PaymentType type, {
    int maxAttempts = 30,
    int intervalSeconds = 2,
  }) async {
    for (int i = 0; i < maxAttempts; i++) {
      final order = type == PaymentType.alipay
          ? await queryAlipayOrder(orderId)
          : await queryWechatOrder(orderId);

      if (order.status == PaymentStatus.success) {
        return order;
      }

      if (order.status == PaymentStatus.failed ||
          order.status == PaymentStatus.cancelled) {
        throw Exception('支付失败或已取消');
      }

      // 等待一段时间后再次查询
      await Future.delayed(Duration(seconds: intervalSeconds));
    }

    throw Exception('支付超时');
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
