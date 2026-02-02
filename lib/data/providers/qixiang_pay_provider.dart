import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aif2f/data/models/payment_model.dart';
import 'package:aif2f/data/services/qixiang_pay_service.dart';

/// 七相支付服务Provider
final qixiangPayServiceProvider = Provider<QixiangPayService>((ref) {
  return QixiangPayService();
});

/// 七相支付状态
class QixiangPayState {
  final PaymentOrder? order;
  final bool isLoading;
  final String? errorMessage;

  QixiangPayState({
    this.order,
    this.isLoading = false,
    this.errorMessage,
  });

  QixiangPayState copyWith({
    PaymentOrder? order,
    bool? isLoading,
    String? errorMessage,
  }) {
    return QixiangPayState(
      order: order ?? this.order,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// 七相支付Notifier
class QixiangPayNotifier extends Notifier<QixiangPayState> {
  @override
  QixiangPayState build() {
    return QixiangPayState();
  }

  QixiangPayService get _service => ref.read(qixiangPayServiceProvider);

  /// 创建支付订单
  Future<PaymentOrder?> createPaymentOrder({
    required PaymentType type,
    required String outTradeNo,
    required double money,
    required String name,
    String? param,
    String? clientIp,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _service.createOrder(
        type: type,
        outTradeNo: outTradeNo,
        money: money,
        name: name,
        param: param,
        clientIp: clientIp,
      );

      // 将七相支付订单转换为通用PaymentOrder
      final order = PaymentOrder(
        orderId: outTradeNo,
        tradeNo: result.tradeNo,
        type: type,
        status: PaymentStatus.pending,
        amount: money,
        subject: name,
        qrCode: result.payUrl,
      );

      state = state.copyWith(order: order, isLoading: false);
      return order;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return null;
    }
  }

  /// 查询订单状态
  Future<PaymentOrder?> queryOrderStatus({
    required String outTradeNo,
    required PaymentType type,
    String? tradeNo,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _service.queryOrder(
        outTradeNo: outTradeNo,
        tradeNo: tradeNo,
      );

      final order = result.toPaymentOrder(type);
      state = state.copyWith(order: order, isLoading: false);
      return order;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return null;
    }
  }

  /// 轮询查询订单状态
  Future<bool> pollOrderStatus(
    String outTradeNo,
    PaymentType type, {
    int maxAttempts = 30,
    int intervalSeconds = 2,
  }) async {
    for (int i = 0; i < maxAttempts; i++) {
      final order = await queryOrderStatus(
        outTradeNo: outTradeNo,
        type: type,
      );

      if (order != null && order.status == PaymentStatus.success) {
        return true;
      }

      if (order != null &&
          (order.status == PaymentStatus.failed ||
              order.status == PaymentStatus.cancelled)) {
        state = state.copyWith(errorMessage: '支付失败或已取消');
        return false;
      }

      // 等待一段时间后再次查询
      await Future.delayed(Duration(seconds: intervalSeconds));
    }

    state = state.copyWith(errorMessage: '支付超时');
    return false;
  }

  /// 退款
  Future<bool> refund({
    String? tradeNo,
    String? outTradeNo,
    required double money,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _service.refund(
        tradeNo: tradeNo,
        outTradeNo: outTradeNo,
        money: money,
      );

      state = state.copyWith(isLoading: false);
      return result.isSuccess;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// 重置状态
  void reset() {
    state = QixiangPayState();
  }
}

/// 七相支付Provider
final qixiangPayProvider =
    NotifierProvider<QixiangPayNotifier, QixiangPayState>(QixiangPayNotifier.new);
