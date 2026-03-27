import 'dart:io';

import 'package:flutter/material.dart';

/// 七相支付配置
class QixiangPayConfig {
  /// API 网关地址
  static const String gatewayUrl = 'https://api.payqixiang.cn/mapi.php';

  /// 查询商户信息 API
  static String get queryMerchantInfoUrl => 'https://api.payqixiang.cn/api.php';

  /// 查询订单 API
  static String get queryOrderUrl => 'https://api.payqixiang.cn/api.php';

  /// 退款 API
  static const String refundUrl =
      'https://api.payqixiang.cn/api.php?act=refund';

  /// 商户ID（从环境变量或配置文件读取）
  static const String pid = String.fromEnvironment(
    'QIXIANG_PID',
    // defaultValue: '3126', // 商户ID
    defaultValue: '1003', // 测试账号
  );

  /// 商户密钥（从环境变量或配置文件读取）
  static const String key = String.fromEnvironment(
    'QIXIANG_KEY',
    // defaultValue: 'KgK8Ae3os8gi2Bo5StgSWk55ws54aC3k', // 商户KEY
    defaultValue: 'fnv5Xf0BnV5n5bGzFf7V7Fvn9tVtzn9v', // 测试Key
  );

  /// 异步通知地址（需要在后端实现）
  static String get wechatNotifyUrl => '$baseUrl/api/v1/pay/wechat/notify';

  /// 跳转通知地址
  static String get wechatReturnUrl => '$baseUrl/api/v1/pay/wechat/return';

  /// 异步通知地址（需要在后端实现）
  static String get alipayNotifyUrl => '$baseUrl/api/v1/pay/alipay/notify';

  /// 跳转通知地址
  static String get alipayReturnUrl => '$baseUrl/api/v1/pay/alipay/return';

  /// 支付基础地址（用于构建回调URL）
  static const String baseUrl = String.fromEnvironment(
    'QIXIANG_BASE_URL',
    defaultValue: 'http://139.199.83.208:19998',
  );

  /// 支付方式
  static const String alipayType = 'alipay';
  static const String wechatType = 'wxpay';

  /// 设备类型
  /// - mobile: 移动设备 (iOS/Android)
  /// - pc: 桌面设备 (Windows/Linux/macOS)
  /// - jump: 其他平台
  static String get deviceType {
    if (Platform.isAndroid || Platform.isIOS) {
      return 'mobile';
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return 'jump';
      // return 'pc';
    } else {
      return 'jump';
    }
  }

  /// 签名类型
  static const String signType = 'MD5';

  /// 连接超时时间（毫秒）
  static const int connectTimeout = 15000;

  /// 接收超时时间（毫秒）
  static const int receiveTimeout = 15000;
}
