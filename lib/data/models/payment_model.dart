/// 支付类型枚举
enum PaymentType {
  alipay('支付宝'),
  wechat('微信支付');

  final String displayName;
  const PaymentType(this.displayName);
}

/// 支付状态枚举
enum PaymentStatus {
  pending('待支付'),
  processing('处理中'),
  success('支付成功'),
  failed('支付失败'),
  refunded('已退款'),
  cancelled('已取消');

  final String displayName;
  const PaymentStatus(this.displayName);

  static PaymentStatus fromString(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return PaymentStatus.pending;
      case 'PROCESSING':
        return PaymentStatus.processing;
      case 'SUCCESS':
      case 'TRADE_SUCCESS':
        return PaymentStatus.success;
      case 'FAILED':
      case 'TRADE_FAILED':
        return PaymentStatus.failed;
      case 'REFUNDED':
      case 'REFUND_SUCCESS':
        return PaymentStatus.refunded;
      case 'CANCELLED':
        return PaymentStatus.cancelled;
      default:
        return PaymentStatus.pending;
    }
  }
}

/// 支付订单模型
class PaymentOrder {
  final String orderId;
  final String? tradeNo;
  final PaymentType type;
  final PaymentStatus status;
  final double amount;
  final String? subject;
  final String? body;
  final DateTime? createdAt;
  final DateTime? paidAt;
  final String? qrCode; // 支付宝二维码URL
  final WeChatPayParams? wechatParams; // 微信支付参数

  PaymentOrder({
    required this.orderId,
    this.tradeNo,
    required this.type,
    required this.status,
    required this.amount,
    this.subject,
    this.body,
    this.createdAt,
    this.paidAt,
    this.qrCode,
    this.wechatParams,
  });

  factory PaymentOrder.fromJson(Map<String, dynamic> json, PaymentType type) {
    return PaymentOrder(
      orderId: (json['order_id'] is String 
          ? json['order_id'] as String
          : (json['order_id']?.toString() ?? 
              json['order_no'] as String? ?? 
              json['out_trade_no'] as String? ?? '')),
      tradeNo: json['trade_no'] as String? ?? json['transaction_id'] as String?,
      type: type,
      status: PaymentStatus.fromString(
        json['trade_status'] as String? ?? json['trade_state'] as String? ?? 'PENDING',
      ),
      amount: (json['total_amount'] as num?)?.toDouble() ??
          ((json['total_fee'] as num?)?.toDouble() ?? 0.0) / 100,
      subject: json['subject'] as String?,
      body: json['body'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : (json['gmt_create'] != null
              ? DateTime.parse(json['gmt_create'])
              : (json['time_end'] != null ? DateTime.parse(json['time_end']) : null)),
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'])
          : (json['gmt_payment'] != null ? DateTime.parse(json['gmt_payment']) : null),
      qrCode: json['qr_code'] as String?,
      wechatParams: json['prepay_id'] != null
          ? WeChatPayParams.fromJson(json)
          : null,
    );
  }
}

/// 微信支付参数
class WeChatPayParams {
  final String appId;
  final String partnerId;
  final String prepayId;
  final String packageValue;
  final String nonceStr;
  final int timestamp;
  final String sign;

  WeChatPayParams({
    required this.appId,
    required this.partnerId,
    required this.prepayId,
    required this.packageValue,
    required this.nonceStr,
    required this.timestamp,
    required this.sign,
  });

  factory WeChatPayParams.fromJson(Map<String, dynamic> json) {
    return WeChatPayParams(
      appId: json['appid'] as String? ?? '',
      partnerId: json['partnerid'] as String? ?? '',
      prepayId: json['prepay_id'] as String? ?? '',
      packageValue: json['package'] as String? ?? 'Sign=WXPay',
      nonceStr: json['noncestr'] as String? ?? '',
      timestamp: json['timestamp'] as int? ?? 0,
      sign: json['sign'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appid': appId,
      'partnerid': partnerId,
      'prepayid': prepayId,
      'package': packageValue,
      'noncestr': nonceStr,
      'timestamp': timestamp,
      'sign': sign,
    };
  }
}

/// 创建支付订单请求
class CreatePaymentOrderRequest {
  final String outTradeNo;
  final double totalAmount;
  final String subject;
  final String? body;
  final PaymentType type;
  final String? productId;
  final int? quantity;

  CreatePaymentOrderRequest({
    required this.outTradeNo,
    required this.totalAmount,
    required this.subject,
    this.body,
    required this.type,
    this.productId,
    this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'out_trade_no': outTradeNo,
      'total_amount': totalAmount.toStringAsFixed(2),
      'subject': subject,
      if (body != null) 'body': body,
      if (productId != null) 'product_id': productId,
      if (quantity != null) 'quantity': quantity,
    };
  }
}

/// 退款请求
class RefundRequest {
  final String outTradeNo;
  final String outRefundNo;
  final double refundAmount;

  RefundRequest({
    required this.outTradeNo,
    required this.outRefundNo,
    required this.refundAmount,
  });

  Map<String, dynamic> toJson() {
    return {
      'out_trade_no': outTradeNo,
      'out_refund_no': outRefundNo,
      'refund_amount': refundAmount.toStringAsFixed(2),
      'total_fee': (refundAmount * 100).toInt(),
      'refund_fee': (refundAmount * 100).toInt(),
    };
  }
}

/// API 响应基础模型
class ApiResponse<T> {
  final int? code;
  final String? msg;
  final T? data;
  final bool success;

  ApiResponse({
    this.code,
    this.msg,
    this.data,
    required this.success,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    // 处理后端返回的格式: { code: int, msg: str, data: any }
    // 或者 { code: 0, msg: success, data: { ... } }
    final code = json['code'] as int?;
    final msg = json['msg'] as String?;
    final data = json['data'];

    return ApiResponse(
      code: code,
      msg: msg,
      data: fromJsonT != null && data != null ? fromJsonT(data) : data,
      success: code == 0 || code == null,
    );
  }
}
