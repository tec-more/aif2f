import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aif2f/data/models/payment_model.dart';
import 'package:aif2f/data/services/payment_service.dart';

/// Payment Service Provider
final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService();
});

/// 支付状态
enum PaymentProcessStatus {
  initial,
  creating,
  waiting,
  polling,
  success,
  failed,
  refunded,
}

/// 支付状态类
class PaymentState {
  final PaymentProcessStatus status;
  final PaymentOrder? currentOrder;
  final String? errorMessage;

  PaymentState({required this.status, this.currentOrder, this.errorMessage});

  PaymentState copyWith({
    PaymentProcessStatus? status,
    PaymentOrder? currentOrder,
    String? errorMessage,
  }) {
    return PaymentState(
      status: status ?? this.status,
      currentOrder: currentOrder ?? this.currentOrder,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// 支付 Notifier
class PaymentNotifier extends Notifier<PaymentState> {
  @override
  PaymentState build() {
    return PaymentState(status: PaymentProcessStatus.initial);
  }

  PaymentService get _paymentService => ref.read(paymentServiceProvider);

  /// 创建支付订单
  Future<PaymentOrder?> createPaymentOrder({
    required String outTradeNo,
    required double amount,
    required String subject,
    String? body,
    required PaymentType type,
    String? productId,
    int? customerId,
    String? productName,
    String? productType,
    double? unitPrice,
  }) async {
    state = state.copyWith(status: PaymentProcessStatus.creating);

    try {
      final order = await _paymentService.createPaymentOrder(
        type: type,
        productId: productId ?? '',
        quantity: 1,
        outTradeNo: outTradeNo,
        customerId: customerId,
        productName: productName,
        productType: productType,
        unitPrice: unitPrice,
        subject: subject,
      );

      state = PaymentState(
        status: PaymentProcessStatus.waiting,
        currentOrder: order,
      );

      if (kDebugMode) {
        print('✅ [PaymentProvider] 订单创建成功: ${order.orderId}');
        print('✅ [PaymentProvider] 二维码: ${order.qrCode}');
      }

      return order;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [PaymentProvider] 订单创建失败: $e');
        print('❌ [PaymentProvider] 错误类型: ${e.runtimeType}');
      }
      state = PaymentState(
        status: PaymentProcessStatus.failed,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return null;
    }
  }

  /// 根据订单信息生成支付信息（七相聚合支付）
  Future<PaymentOrder?> createQixiangPayment(PaymentOrder order) async {
    try {
      if (kDebugMode) {
        print('🔄 [PaymentProvider] 开始调用七相支付API...');
        print('📋 [PaymentProvider] 订单ID: ${order.orderId}');
        print('📋 [PaymentProvider] 支付类型: ${order.type}');
        print('📋 [PaymentProvider] 订单金额: ${order.amount}');
      }

      final result = await _paymentService.createQixiangPayment(order);

      if (kDebugMode) {
        print('✅ [PaymentProvider] 七相支付API调用成功');
        print('📋 [PaymentProvider] 返回的二维码: ${result.qrCode}');
      }

      return result;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ [PaymentProvider] 生成支付信息失败: $e');
        print('❌ [PaymentProvider] 错误类型: ${e.runtimeType}');
        print('❌ [PaymentProvider] 堆栈跟踪: $stackTrace');
      }
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return null;
    }
  }

  /// 查询订单状态
  Future<void> queryOrderStatus(String orderId, PaymentType type) async {
    try {
      final order = await _paymentService.queryOrder(
        orderId: orderId,
        type: type,
      );

      // 保留原有的二维码信息（查询订单不会返回payurl）
      final String? preservedQrCode = state.currentOrder?.qrCode;

      if (kDebugMode) {
        print('🔄 [PaymentProvider] 查询订单状态');
        print('📋 [PaymentProvider] 订单状态: ${order.status}');
        print('📋 [PaymentProvider] 保留的二维码: $preservedQrCode');
      }

      // 更新状态
      PaymentProcessStatus newStatus;
      switch (order.status) {
        case PaymentStatus.success:
          newStatus = PaymentProcessStatus.success;
          break;
        case PaymentStatus.failed:
          newStatus = PaymentProcessStatus.failed;
          break;
        case PaymentStatus.refunded:
          newStatus = PaymentProcessStatus.refunded;
          break;
        default:
          newStatus = PaymentProcessStatus.waiting;
      }

      // 如果查询结果没有二维码，使用之前保存的
      final updatedOrder = order.qrCode != null
          ? order
          : PaymentOrder(
              orderId: order.orderId,
              tradeNo: order.tradeNo,
              type: order.type,
              status: order.status,
              amount: order.amount,
              subject: order.subject,
              body: order.body,
              createdAt: order.createdAt,
              paidAt: order.paidAt,
              qrCode: preservedQrCode, // 保留二维码
              wechatParams: order.wechatParams,
            );

      state = state.copyWith(status: newStatus, currentOrder: updatedOrder);
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// 轮询订单状态（用于支付完成后自动检测）
  Future<bool> pollOrderStatus(
    String orderId,
    PaymentType type, {
    int maxAttempts = 30,
    int intervalSeconds = 2,
  }) async {
    state = state.copyWith(status: PaymentProcessStatus.polling);

    try {
      final order = await _paymentService.pollOrderStatus(
        orderId,
        type,
        maxAttempts: maxAttempts,
        intervalSeconds: intervalSeconds,
      );

      state = PaymentState(
        status: PaymentProcessStatus.success,
        currentOrder: order,
      );

      return true;
    } catch (e) {
      state = PaymentState(
        status: PaymentProcessStatus.failed,
        currentOrder: state.currentOrder,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// 申请退款
  Future<bool> refund({
    required String outTradeNo,
    required String outRefundNo,
    required double refundAmount,
    required PaymentType type,
  }) async {
    try {
      final request = RefundRequest(
        outTradeNo: outTradeNo,
        outRefundNo: outRefundNo,
        refundAmount: refundAmount,
      );

      if (type == PaymentType.alipay) {
        await _paymentService.refundAlipay(request);
      } else {
        await _paymentService.refundWechat(request);
      }

      state = state.copyWith(status: PaymentProcessStatus.refunded);
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// 重置状态
  void reset() {
    state = PaymentState(status: PaymentProcessStatus.initial);
  }

  /// 清除错误信息
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Payment State Provider
final paymentProvider = NotifierProvider<PaymentNotifier, PaymentState>(
  PaymentNotifier.new,
);
