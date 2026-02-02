/// 七相支付配置
class QixiangPayConfig {
  /// API 网关地址
  static const String gatewayUrl = 'https://api.payqixiang.cn/mapi.php';

  /// 查询商户信息 API
  static String get queryMerchantInfoUrl =>
      'https://api.payqixiang.cn/api.php';

  /// 查询订单 API
  static String get queryOrderUrl =>
      'https://api.payqixiang.cn/api.php';

  /// 退款 API
  static const String refundUrl = 'https://api.payqixiang.cn/api.php?act=refund';

  /// 商户ID（从环境变量或配置文件读取）
  static const String pid = String.fromEnvironment(
    'QIXIANG_PID',
    defaultValue: '1003', // 测试账号
  );

  /// 商户密钥（从环境变量或配置文件读取）
  static const String key = String.fromEnvironment(
    'QIXIANG_KEY',
    defaultValue: 'KM1fKkWc7M74jlJfMff6dOl6L3MdDbFX', // 测试账号
  );

  /// 异步通知地址（需要在后端实现）
  static String get notifyUrl => '$baseUrl/api/qixiang-pay/notify';

  /// 跳转通知地址
  static String get returnUrl => '$baseUrl/recharge/result';

  /// 支付基础地址（用于构建回调URL）
  static const String baseUrl = String.fromEnvironment(
    'QIXIANG_BASE_URL',
    defaultValue: 'http://your-domain.com',
  );

  /// 支付方式
  static const String alipayType = 'alipay';
  static const String wechatType = 'wxpay';

  /// 设备类型（返回跳转URL）
  static const String deviceType = 'jump';

  /// 签名类型
  static const String signType = 'MD5';

  /// 连接超时时间（毫秒）
  static const int connectTimeout = 15000;

  /// 接收超时时间（毫秒）
  static const int receiveTimeout = 15000;
}
