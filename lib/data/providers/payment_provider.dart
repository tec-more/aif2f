import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payment_model.dart';
import '../services/payment_service.dart';

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

  PaymentState({
    required this.status,
    this.currentOrder,
    this.errorMessage,
  });

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
  }) async {
    state = state.copyWith(status: PaymentProcessStatus.creating);

    try {
      final request = CreatePaymentOrderRequest(
        outTradeNo: outTradeNo,
        totalAmount: amount,
        subject: subject,
        body: body,
        type: type,
      );

      PaymentOrder order;
      if (type == PaymentType.alipay) {
        order = await _paymentService.createAlipayOrder(request);
      } else {
        order = await _paymentService.createWechatOrder(request);
      }

      state = PaymentState(
        status: PaymentProcessStatus.waiting,
        currentOrder: order,
      );

      return order;
    } catch (e) {
      state = PaymentState(
        status: PaymentProcessStatus.failed,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return null;
    }
  }

  /// 查询订单状态
  Future<void> queryOrderStatus(String orderId, PaymentType type) async {
    try {
      PaymentOrder order;
      if (type == PaymentType.alipay) {
        order = await _paymentService.queryAlipayOrder(orderId);
      } else {
        order = await _paymentService.queryWechatOrder(orderId);
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

      state = state.copyWith(
        status: newStatus,
        currentOrder: order,
      );
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
final paymentProvider =
    NotifierProvider<PaymentNotifier, PaymentState>(PaymentNotifier.new);
