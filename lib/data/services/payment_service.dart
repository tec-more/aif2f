import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:aif2f/data/models/payment_model.dart';
import 'package:aif2f/data/services/api_client.dart';

/// 支付服务（统一使用七相聚合支付后端API）
class PaymentService {
  final ApiClient _apiClient = ApiClient();

  /// 创建支付订单（统一接口，支持微信和支付宝）
  Future<PaymentOrder> createPaymentOrder({
    required PaymentType type,
    required String productId,
    required int quantity,
    String? outTradeNo,
    Map<String, dynamic>? extraParams,
    int? customerId,
    String? productName,
    String? productType,
    double? unitPrice,
    String? subject,
  }) async {
    try {
      final paymentType = type == PaymentType.alipay ? 'alipay' : 'wechat';

      final requestData = {
        if (customerId != null) 'customer_id': customerId,
        'payment_method': paymentType,
        if (subject != null) 'subject': subject,
        'items': [
          {
            'product_id': productId,
            'quantity': quantity,
            'product_name': productName,
            'product_type': productType,
            'unit_price': unitPrice,
            if (outTradeNo != null) 'out_trade_no': outTradeNo,
            if (extraParams != null) ...extraParams,
          },
        ],
      };

      final response = await _apiClient.post(
        '/orders/create',
        data: requestData,
      );

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );

      if (!apiResponse.success && apiResponse.code != 0) {
        throw Exception(apiResponse.msg ?? '创建支付订单失败');
      }

      // 后端返回的数据结构: { code: 0, msg: success, data: { order_id, order_no, qr_code, ... } }
      if (apiResponse.data != null) {
        return PaymentOrder.fromJson(apiResponse.data!, type);
      }

      throw Exception('支付订单响应格式错误');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 根据订单信息生成支付信息（七相聚合支付）
  Future<PaymentOrder> createQixiangPayment(PaymentOrder order) async {
    try {
      final paymentType = order.type == PaymentType.alipay ? 'alipay' : 'wxpay';

      final requestData = {
        'order_no': order.orderId,
        'pay_type': paymentType,
        'amount': order.amount,
        'subject': order.subject ?? '支付订单',
      };

      if (kDebugMode) {
        print('📤 [PaymentService] 七相支付请求数据: $requestData');
      }

      final response = await _apiClient.post(
        '/qixiang/create',
        data: requestData,
      );

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );

      if (!apiResponse.success && apiResponse.code != 0) {
        throw Exception(apiResponse.msg ?? '生成支付信息失败');
      }

      if (kDebugMode) {
        print('📥 [PaymentService] 七相支付响应数据: ${apiResponse.data}');
      }

      // 后端返回的数据包含二维码链接
      if (apiResponse.data != null) {
        return PaymentOrder.fromJson(apiResponse.data!, order.type);
      }

      throw Exception('支付信息响应格式错误');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 查询订单状态（统一接口）
  Future<PaymentOrder> queryOrder({
    required String orderId,
    required PaymentType type,
  }) async {
    try {
      final response = await _apiClient.get('/orders/$orderId');

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );

      if (!apiResponse.success && apiResponse.code != 0) {
        throw Exception(apiResponse.msg ?? '查询订单失败');
      }

      if (apiResponse.data != null) {
        return PaymentOrder.fromJson(apiResponse.data!, type);
      }

      throw Exception('订单响应格式错误');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 创建支付宝支付订单（兼容旧接口）
  Future<PaymentOrder> createAlipayOrder(
    CreatePaymentOrderRequest request,
  ) async {
    return await createPaymentOrder(
      type: PaymentType.alipay,
      productId: request.productId ?? '',
      quantity: request.quantity ?? 1,
    );
  }

  /// 查询支付宝订单（兼容旧接口）
  Future<PaymentOrder> queryAlipayOrder(String orderId) async {
    return await queryOrder(orderId: orderId, type: PaymentType.alipay);
  }

  /// 支付宝退款
  Future<Map<String, dynamic>> refundAlipay(RefundRequest request) async {
    try {
      final response = await _apiClient.post(
        '/orders/refund',
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

  /// 创建微信支付订单（兼容旧接口）
  Future<PaymentOrder> createWechatOrder(
    CreatePaymentOrderRequest request,
  ) async {
    return await createPaymentOrder(
      type: PaymentType.wechat,
      productId: request.productId ?? '',
      quantity: request.quantity ?? 1,
    );
  }

  /// 查询微信支付订单（兼容旧接口）
  Future<PaymentOrder> queryWechatOrder(String orderId) async {
    return await queryOrder(orderId: orderId, type: PaymentType.wechat);
  }

  /// 微信支付退款
  Future<Map<String, dynamic>> refundWechat(RefundRequest request) async {
    try {
      final response = await _apiClient.post(
        '/orders/refund',
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
      final order = await queryOrder(orderId: orderId, type: type);

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
