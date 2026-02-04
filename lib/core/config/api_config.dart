/// API 配置
class ApiConfig {
  /// API 基础地址
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:9998',
  );

  /// API 版本
  static const String apiVersion = '/api/v1';

  /// 完整的 API 基础路径
  static String get apiBaseUrl => '$baseUrl$apiVersion';

  /// 连接超时时间（毫秒）
  static const int connectTimeout = 5000;

  /// 接收超时时间（毫秒）
  static const int receiveTimeout = 10000;

  /// API 端点路径
  static const String authPath = '/auth';
  static const String usersPath = '/users';
  static const String customerPath = '/customer';
  static const String alipayPath = '/pay/alipay';
  static const String wechatPayPath = '/pay/wechat';

  /// 认证相关端点
  static String get loginEndpoint => '$apiBaseUrl$authPath/login';
  static String get registerEndpoint => '$apiBaseUrl$authPath/register';
  static String get logoutEndpoint => '$apiBaseUrl$authPath/logout';
  static String get currentUserEndpoint => '$apiBaseUrl$authPath/me';
  static String get changePasswordEndpoint =>
      '$apiBaseUrl$authPath/change-password';

  /// 客户相关端点
  static String get customerLoginEndpoint => '$apiBaseUrl$customerPath/auth/login';
  static String get customerRegisterEndpoint =>
      '$apiBaseUrl$customerPath/auth/register';
  static String get customerMeEndpoint => '$apiBaseUrl$customerPath/auth/me';

  /// 用户相关端点
  static String userListEndpoint(int page, int pageSize) =>
      '$apiBaseUrl$usersPath/list?page=$page&page_size=$pageSize';
  static String userDetailEndpoint(int userId) =>
      '$apiBaseUrl$usersPath/$userId';
  static String userUpdateEndpoint(int userId) =>
      '$apiBaseUrl$usersPath/$userId';

  /// 支付宝支付端点
  static String get alipayCreateOrderEndpoint =>
      '$apiBaseUrl$alipayPath/orders';
  static String alipayQueryOrderEndpoint(String orderId) =>
      '$apiBaseUrl$alipayPath/orders/$orderId';
  static String get alipayRefundEndpoint => '$apiBaseUrl$alipayPath/refunds';
  static String get alipayNotifyEndpoint => '$apiBaseUrl$alipayPath/notify';

  /// 微信支付端点
  static String get wechatPayCreateOrderEndpoint =>
      '$apiBaseUrl$wechatPayPath/orders';
  static String wechatPayQueryOrderEndpoint(String orderId) =>
      '$apiBaseUrl$wechatPayPath/orders/$orderId';
  static String get wechatPayRefundEndpoint =>
      '$apiBaseUrl$wechatPayPath/refunds';
  static String get wechatPayNotifyEndpoint =>
      '$apiBaseUrl$wechatPayPath/notify';
}
