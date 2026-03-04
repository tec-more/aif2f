import 'package:aif2f/data/models/product_model.dart';
import 'package:aif2f/data/models/order_model.dart';
import 'package:aif2f/data/services/api_client.dart';

/// 产品服务
class ProductService {
  late ApiClient _apiClient;

  ProductService() {
    _apiClient = ApiClient();
    _apiClient.init();
  }

  /// 获取产品列表
  /// 返回激活的产品列表，按排序字段排序
  Future<List<ProductModel>> getProducts() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/products', // 假设API端点是 /products
      );

      final data = response.data;
      if (data == null) return [];

      final List<dynamic> productsJson = data['products'] as List<dynamic>? ?? data as List<dynamic>? ?? [];

      final products = productsJson
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .where((product) => product.isActive)
          .toList()
        ..sort((a, b) => (a.sortOrder ?? 999).compareTo(b.sortOrder ?? 999));

      return products;
    } catch (e) {
      // 如果获取失败，返回默认产品列表
      return _getDefaultProducts();
    }
  }

  /// 创建订单
  /// [productId] 产品ID
  /// [paymentType] 支付类型（alipay/wechat）
  /// 返回订单号
  Future<String> createOrder(int productId, String paymentType) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/orders/create',
        data: {
          'product_id': productId,
          'payment_type': paymentType,
        },
      );

      final data = response.data;
      final orderNo = data?['order_no'] as String? ?? data?['orderNo'] as String? ?? '';

      return orderNo;
    } catch (e) {
      throw Exception('创建订单失败: $e');
    }
  }

  /// 获取默认产品列表（当API请求失败时使用）
  List<ProductModel> _getDefaultProducts() {
    return [
      ProductModel(
        id: 1,
        name: '体验包',
        description: '适合体验用户',
        originalPrice: 1.0,
        price: 1.0,
        hours: 1,
        bonusHours: 0,
        discount: null,
        isActive: true,
        sortOrder: 1,
      ),
      ProductModel(
        id: 2,
        name: '基础包',
        description: '适合轻度使用',
        originalPrice: 10.0,
        price: 9.0,
        hours: 10,
        bonusHours: 0,
        discount: '限时9折',
        isActive: true,
        sortOrder: 2,
      ),
      ProductModel(
        id: 3,
        name: '标准包',
        description: '适合日常使用',
        originalPrice: 50.0,
        price: 45.0,
        hours: 50,
        bonusHours: 0,
        discount: '限时9折',
        isActive: true,
        sortOrder: 3,
      ),
      ProductModel(
        id: 4,
        name: '超值包',
        description: '适合重度使用',
        originalPrice: 100.0,
        price: 80.0,
        hours: 100,
        bonusHours: 20,
        discount: '限时8折+赠送20小时',
        isActive: true,
        sortOrder: 4,
      ),
      ProductModel(
        id: 5,
        name: '豪华包',
        description: '超值优惠',
        originalPrice: 200.0,
        price: 150.0,
        hours: 200,
        bonusHours: 50,
        discount: '限时75折+赠送50小时',
        isActive: true,
        sortOrder: 5,
      ),
    ];
  }
}

/// 订单服务
class OrderService {
  late ApiClient _apiClient;

  OrderService() {
    _apiClient = ApiClient();
    _apiClient.init();
  }

  /// 获取用户订单列表
  /// [page] 页码，默认1
  /// [pageSize] 每页数量，默认20
  Future<List<OrderModel>> getOrders({int page = 1, int pageSize = 20}) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/orders',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
        },
      );

      final data = response.data;
      if (data == null) return [];

      final List<dynamic> ordersJson = data['orders'] as List<dynamic>? ?? data as List<dynamic>? ?? [];

      final orders = ordersJson
          .map((json) => OrderModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return orders;
    } catch (e) {
      throw Exception('获取订单列表失败: $e');
    }
  }

  /// 获取订单详情
  /// [orderNo] 订单号
  Future<OrderModel> getOrderDetail(String orderNo) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/orders/$orderNo',
      );

      final data = response.data;
      if (data == null) {
        throw Exception('订单不存在');
      }

      return OrderModel.fromJson(data);
    } catch (e) {
      throw Exception('获取订单详情失败: $e');
    }
  }

  /// 取消订单
  /// [orderNo] 订单号
  Future<bool> cancelOrder(String orderNo) async {
    try {
      await _apiClient.post<Map<String, dynamic>>(
        '/orders/$orderNo/cancel',
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}
