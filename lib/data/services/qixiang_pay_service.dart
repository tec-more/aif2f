import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:aif2f/core/config/qixiang_pay_config.dart';
import 'package:aif2f/data/models/payment_model.dart';

/// 七相支付服务
class QixiangPayService {
  late final Dio _dio;

  QixiangPayService() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: Duration(milliseconds: QixiangPayConfig.connectTimeout),
        receiveTimeout: Duration(milliseconds: QixiangPayConfig.receiveTimeout),
      ),
    );
  }

  /// 生成MD5签名
  /// 按照参数名ASCII码从小到大排序，然后拼接成 key=value&key=value 格式
  /// 最后加上商户密钥KEY进行MD5加密
  String _generateSign(Map<String, dynamic> params) {
    // 1. 过滤掉sign、sign_type和空值
    final filteredParams = <String, String>{};
    params.forEach((key, value) {
      if (key != 'sign' &&
          key != 'sign_type' &&
          value != null &&
          value.toString().isNotEmpty) {
        filteredParams[key] = value.toString();
      }
    });

    // 2. 按照参数名ASCII码从小到大排序
    final sortedKeys = filteredParams.keys.toList()..sort();

    // 3. 拼接成 key=value&key=value 格式
    final signStr = sortedKeys
        .map((key) => '$key=${filteredParams[key]}')
        .join('&');

    // 4. 加上商户密钥KEY进行MD5加密（直接拼接，不使用&key=格式）
    final finalStr = '$signStr${QixiangPayConfig.key}';
    final sign = md5.convert(utf8.encode(finalStr)).toString().toLowerCase();

    // 打印签名生成过程
    print('🔐 签名生成过程:');
    print('   过滤后参数: $filteredParams');
    print('   排序后键: $sortedKeys');
    print('   拼接字符串: $signStr');
    print('   最终字符串: $finalStr');
    print('   生成签名: $sign');

    return sign;
  }

  /// 创建支付订单（统一下单）
  Future<QixiangPayOrder> createOrder({
    required PaymentType type,
    required String outTradeNo,
    required double money,
    required String name,
    String? param,
    String? clientIp,
  }) async {
    final paymentType = type == PaymentType.alipay
        ? QixiangPayConfig.alipayType
        : QixiangPayConfig.wechatType;

    // 使用更简单的notify_url和return_url，避免URL编码问题
    final notifyUrl = 'http://localhost:9998/api/qixiang-pay/notify';
    final returnUrl = 'http://localhost:9998/recharge/result';

    final params = <String, dynamic>{
      'pid': QixiangPayConfig.pid,
      'type': paymentType,
      'out_trade_no': outTradeNo,
      'notify_url': notifyUrl,
      'return_url': returnUrl,
      'name': name,
      'money': money.toStringAsFixed(2),
      'clientip': clientIp ?? '127.0.0.1',
      'device': QixiangPayConfig.deviceType,
      'sign_type': QixiangPayConfig.signType,
    };

    // 打印请求参数
    print('📝 微信支付请求参数: $params');

    // 生成签名
    final sign = _generateSign(params);
    params['sign'] = sign;

    // 打印签名
    print('🔐 生成的签名: $sign');

    try {
      print('🚀 发送支付请求到: ${QixiangPayConfig.gatewayUrl}');
      final response = await _dio.post(
        QixiangPayConfig.gatewayUrl,
        data: FormData.fromMap(params),
        options: Options(contentType: 'application/x-www-form-urlencoded'),
      );

      print('✅ 支付请求响应: ${response.data}');

      // 检查response.data的类型
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;

        if (data['code'] == 1) {
          return QixiangPayOrder.fromJson(data);
        } else {
          print('❌ 支付请求失败: ${data['msg']}');
          throw Exception(data['msg'] ?? '创建订单失败');
        }
      } else {
        // 如果是字符串，尝试解析为JSON
        try {
          final data = jsonDecode(response.data) as Map<String, dynamic>;
          if (data['code'] == 1) {
            return QixiangPayOrder.fromJson(data);
          } else {
            print('❌ 支付请求失败: ${data['msg']}');
            throw Exception(data['msg'] ?? '创建订单失败');
          }
        } catch (e) {
          print('❌ 响应解析失败: $e');
          throw Exception('支付请求失败: 响应格式错误');
        }
      }
    } on DioException catch (e) {
      print('❌ 网络错误: ${e.message}');
      print('❌ 错误详情: ${e.response}');
      throw _handleDioError(e);
    }
  }

  /// 查询订单
  Future<QixiangPayOrderDetail> queryOrder({
    required String outTradeNo,
    String? tradeNo,
  }) async {
    final params = <String, dynamic>{
      'act': 'order',
      'pid': QixiangPayConfig.pid,
      'key': QixiangPayConfig.key,
      if (tradeNo != null && tradeNo.isNotEmpty) 'trade_no': tradeNo,
      if (outTradeNo.isNotEmpty) 'out_trade_no': outTradeNo,
    };

    try {
      final response = await _dio.get(
        QixiangPayConfig.queryOrderUrl,
        queryParameters: params,
      );

      final data = response.data as Map<String, dynamic>;

      if (data['code'] == 1) {
        return QixiangPayOrderDetail.fromJson(data);
      } else {
        throw Exception(data['msg'] ?? '查询订单失败');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 验证回调签名
  bool verifySign(Map<String, dynamic> params) {
    final receivedSign = params['sign'] as String?;
    if (receivedSign == null || receivedSign.isEmpty) {
      return false;
    }

    final calculatedSign = _generateSign(params);
    return receivedSign == calculatedSign;
  }

  /// 退款
  Future<QixiangPayRefundResult> refund({
    String? tradeNo,
    String? outTradeNo,
    required double money,
  }) async {
    if ((tradeNo == null || tradeNo.isEmpty) &&
        (outTradeNo == null || outTradeNo.isEmpty)) {
      throw Exception('订单号不能为空');
    }

    final params = <String, dynamic>{
      'act': 'refund',
      'pid': QixiangPayConfig.pid,
      'key': QixiangPayConfig.key,
      'money': money.toStringAsFixed(2),
      if (tradeNo != null && tradeNo.isNotEmpty) 'trade_no': tradeNo,
      if (outTradeNo != null && outTradeNo.isNotEmpty)
        'out_trade_no': outTradeNo,
    };

    try {
      final response = await _dio.post(
        QixiangPayConfig.refundUrl,
        data: FormData.fromMap(params),
      );

      final data = response.data as Map<String, dynamic>;

      if (data['code'] == 1) {
        return QixiangPayRefundResult.fromJson(data);
      } else {
        throw Exception(data['msg'] ?? '退款失败');
      }
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

/// 七相支付订单响应
class QixiangPayOrder {
  final int code;
  final String? msg;
  final String? tradeNo;
  final String? payUrl;
  final String? qrcode;

  QixiangPayOrder({
    required this.code,
    this.msg,
    this.tradeNo,
    this.payUrl,
    this.qrcode,
  });

  factory QixiangPayOrder.fromJson(Map<String, dynamic> json) {
    return QixiangPayOrder(
      code: json['code'] as int,
      msg: json['msg'] as String?,
      tradeNo: json['trade_no'] as String?,
      payUrl: json['payurl'] as String?,
      qrcode: json['qrcode'] as String?,
    );
  }
}

/// 七相支付订单详情
class QixiangPayOrderDetail {
  final int code;
  final String? msg;
  final String? tradeNo;
  final String? outTradeNo;
  final String? apiTradeNo;
  final String? type;
  final String? name;
  final double? money;
  final int? status; // 1为支付成功，0为未支付
  final String? addtime;
  final String? endtime;

  QixiangPayOrderDetail({
    required this.code,
    this.msg,
    this.tradeNo,
    this.outTradeNo,
    this.apiTradeNo,
    this.type,
    this.name,
    this.money,
    this.status,
    this.addtime,
    this.endtime,
  });

  factory QixiangPayOrderDetail.fromJson(Map<String, dynamic> json) {
    return QixiangPayOrderDetail(
      code: json['code'] as int,
      msg: json['msg'] as String?,
      tradeNo: json['trade_no'] as String?,
      outTradeNo: json['out_trade_no'] as String?,
      apiTradeNo: json['api_trade_no'] as String?,
      type: json['type'] as String?,
      name: json['name'] as String?,
      money: (json['money'] as num?)?.toDouble(),
      status: json['status'] as int?,
      addtime: json['addtime'] as String?,
      endtime: json['endtime'] as String?,
    );
  }

  /// 是否已支付成功
  bool get isPaid => status == 1;

  /// 转换为PaymentOrder
  PaymentOrder toPaymentOrder(PaymentType type) {
    return PaymentOrder(
      orderId: outTradeNo ?? '',
      tradeNo: tradeNo,
      type: type,
      status: isPaid ? PaymentStatus.success : PaymentStatus.pending,
      amount: money ?? 0.0,
      subject: name,
      createdAt: addtime != null ? DateTime.tryParse(addtime!) : null,
      paidAt: endtime != null ? DateTime.tryParse(endtime!) : null,
      qrCode: payUrl,
    );
  }

  /// 支付URL（如果有）
  String? get payUrl => null;
}

/// 七相支付退款结果
class QixiangPayRefundResult {
  final int code;
  final String? msg;

  QixiangPayRefundResult({required this.code, this.msg});

  factory QixiangPayRefundResult.fromJson(Map<String, dynamic> json) {
    return QixiangPayRefundResult(
      code: json['code'] as int,
      msg: json['msg'] as String?,
    );
  }

  bool get isSuccess => code == 1;
}
