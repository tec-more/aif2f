/// 订单状态枚举
enum OrderStatus {
  pending('待支付'),
  processing('处理中'),
  completed('已完成'),
  cancelled('已取消'),
  failed('支付失败'),
  refunded('已退款');

  final String displayName;
  const OrderStatus(this.displayName);

  static OrderStatus fromString(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return OrderStatus.pending;
      case 'PROCESSING':
        return OrderStatus.processing;
      case 'COMPLETED':
      case 'SUCCESS':
        return OrderStatus.completed;
      case 'CANCELLED':
        return OrderStatus.cancelled;
      case 'FAILED':
        return OrderStatus.failed;
      case 'REFUNDED':
        return OrderStatus.refunded;
      default:
        return OrderStatus.pending;
    }
  }
}

/// 订单模型
class OrderModel {
  final String orderNo; // 订单号
  final int productId; // 产品ID
  final String productName; // 产品名称
  final int hours; // 充值时长
  final double amount; // 订单金额
  final OrderStatus status; // 订单状态
  final DateTime? createdAt; // 创建时间
  final DateTime? paidAt; // 支付时间
  final String? paymentMethod; // 支付方式
  final String? tradeNo; // 第三方交易号

  OrderModel({
    required this.orderNo,
    required this.productId,
    required this.productName,
    required this.hours,
    required this.amount,
    required this.status,
    this.createdAt,
    this.paidAt,
    this.paymentMethod,
    this.tradeNo,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      orderNo: json['order_no'] as String? ?? json['orderNo'] as String? ?? '',
      productId: json['product_id'] as int? ?? json['productId'] as int? ?? 0,
      productName: json['product_name'] as String? ?? json['productName'] as String? ?? '',
      hours: json['hours'] as int? ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: OrderStatus.fromString(json['status'] as String? ?? 'PENDING'),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : (json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null),
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'])
          : (json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null),
      paymentMethod: json['payment_method'] as String? ?? json['paymentMethod'] as String?,
      tradeNo: json['trade_no'] as String? ?? json['tradeNo'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_no': orderNo,
      'product_id': productId,
      'product_name': productName,
      'hours': hours,
      'amount': amount,
      'status': status.name,
      'created_at': createdAt?.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
      'payment_method': paymentMethod,
      'trade_no': tradeNo,
    };
  }

  /// 判断订单是否已完成
  bool get isCompleted => status == OrderStatus.completed;

  /// 判断订单是否待支付
  bool get isPending => status == OrderStatus.pending;

  /// 获取状态颜色
  String getStatusColor() {
    switch (status) {
      case OrderStatus.pending:
        return '#FF9800'; // 橙色
      case OrderStatus.processing:
        return '#2196F3'; // 蓝色
      case OrderStatus.completed:
        return '#4CAF50'; // 绿色
      case OrderStatus.cancelled:
        return '#9E9E9E'; // 灰色
      case OrderStatus.failed:
        return '#F44336'; // 红色
      case OrderStatus.refunded:
        return '#9C27B0'; // 紫色
    }
  }

  @override
  String toString() {
    return 'OrderModel(orderNo: $orderNo, productName: $productName, amount: $amount, status: $status)';
  }
}
