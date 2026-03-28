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
  final int? productId; // 产品ID（可选）
  final String? productName; // 产品名称（可选）
  final int? hours; // 充值时长（可选）
  final double amount; // 订单金额
  final OrderStatus status; // 订单状态
  final DateTime? createdAt; // 创建时间
  final DateTime? paidAt; // 支付时间
  final String? paymentMethod; // 支付方式
  final String? tradeNo; // 第三方交易号
  final List<String>? productSummary; // 产品摘要列表（可选）
  final int? itemCount; // 商品数量（可选）
  final String? firstProductImage; // 第一个产品图片（可选）

  OrderModel({
    required this.orderNo,
    this.productId,
    this.productName,
    this.hours,
    required this.amount,
    required this.status,
    this.createdAt,
    this.paidAt,
    this.paymentMethod,
    this.tradeNo,
    this.productSummary,
    this.itemCount,
    this.firstProductImage,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // 处理状态字段 - 支持 payment_status (paid/pending) 和 status 字段
    final String statusStr = json['payment_status'] as String? ??
                             json['status'] as String? ?? 'PENDING';
    final OrderStatus orderStatus = _parseStatus(statusStr);

    // 处理金额字段 - 支持 final_amount, amount, total_amount
    final double amountValue = (json['final_amount'] as num?)?.toDouble() ??
                               (json['amount'] as num?)?.toDouble() ??
                               (json['total_amount'] as num?)?.toDouble() ?? 0.0;

    // 处理支付时间字段 - 支持 pay_time, paid_at, paidAt
    DateTime? paidTime;
    if (json['pay_time'] != null) {
      try {
        paidTime = DateTime.parse(json['pay_time']);
      } catch (e) {
        paidTime = null;
      }
    } else if (json['paid_at'] != null) {
      try {
        paidTime = DateTime.parse(json['paid_at']);
      } catch (e) {
        paidTime = null;
      }
    } else if (json['paidAt'] != null) {
      try {
        paidTime = DateTime.parse(json['paidAt']);
      } catch (e) {
        paidTime = null;
      }
    }

    // 处理产品名称 - 优先使用 first_product_name，然后是 product_name
    final String? productNameValue = json['first_product_name'] as String? ??
                                     json['product_name'] as String? ??
                                     json['productName'] as String?;

    // 处理产品摘要列表
    List<String>? productSummaryList;
    if (json['product_summary'] != null) {
      try {
        final summaryData = json['product_summary'];
        if (summaryData is List) {
          productSummaryList = summaryData.map((e) => e.toString()).toList();
        }
      } catch (e) {
        productSummaryList = null;
      }
    }

    return OrderModel(
      orderNo: json['order_no'] as String? ?? json['orderNo'] as String? ?? '',
      productId: json['product_id'] as int? ?? json['productId'] as int?,
      productName: productNameValue,
      hours: json['hours'] as int?,
      amount: amountValue,
      status: orderStatus,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : (json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null),
      paidAt: paidTime,
      paymentMethod: json['payment_method'] as String? ?? json['paymentMethod'] as String?,
      tradeNo: json['trade_no'] as String? ?? json['tradeNo'] as String?,
      productSummary: productSummaryList,
      itemCount: json['item_count'] as int?,
      firstProductImage: json['first_product_image'] as String?,
    );
  }

  /// 解析状态字符串
  static OrderStatus _parseStatus(String status) {
    final upperStatus = status.toUpperCase();
    switch (upperStatus) {
      case 'PAID':
      case 'COMPLETED':
      case 'SUCCESS':
        return OrderStatus.completed;
      case 'PENDING':
        return OrderStatus.pending;
      case 'PROCESSING':
        return OrderStatus.processing;
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
    return 'OrderModel(orderNo: $orderNo, productName: $productName, amount: $amount, status: $status, itemCount: $itemCount)';
  }
}
