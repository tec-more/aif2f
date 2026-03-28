import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
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
      // 从 API 获取产品数据
      // 使用 /api/v1/product/list 地址获取产品列表
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/product/list',
      );

      final data = response.data;
      if (data == null) return _getDefaultProducts();

      // API 返回的数据结构中，产品列表在 data['items'] 中
      final dataMap = data['data'] as Map<String, dynamic>?;
      final List<dynamic> productsJson =
          dataMap?['items'] as List<dynamic>? ?? [];

      final products = productsJson
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .where((product) => product.isActive)
          .toList();

      // 按 sort 字段从小到大排序
      products.sort((a, b) {
        // 尝试从不同字段获取排序值
        // 首先尝试 sortOrder 字段
        final aSort = a.sortOrder ?? 0;
        final bSort = b.sortOrder ?? 0;

        // 如果 sortOrder 相同，使用 id 字段作为排序依据
        if (aSort == bSort) {
          return a.id.compareTo(b.id);
        }

        return aSort.compareTo(bSort);
      });

      return products;
    } catch (e) {
      // 如果获取失败，返回默认产品列表
      print('获取产品列表失败: $e');
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
        data: {'product_id': productId, 'payment_type': paymentType},
      );

      final data = response.data;
      final orderNo =
          data?['order_no'] as String? ?? data?['orderNo'] as String? ?? '';

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
  /// [customerId] 客户ID，必填
  /// [page] 页码，默认1
  /// [pageSize] 每页数量，默认20
  Future<List<OrderModel>> getOrders(int customerId, {int page = 1, int pageSize = 20}) async {
    try {
      if (kDebugMode) {
        print('🔄 [OrderService] 开始获取订单列表');
        print('👤 [OrderService] 客户ID: $customerId');
        print('📋 [OrderService] 页码: $page, 每页数量: $pageSize');
      }

      // 使用客户订单接口 /v1/orders/customer/{customer_id}
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/orders/customer/$customerId',
        queryParameters: {'page': page, 'page_size': pageSize},
      );

      if (kDebugMode) {
        print('✅ [OrderService] API响应成功');
        print('📦 [OrderService] 响应数据: ${response.data}');
      }

      final data = response.data;
      if (data == null) {
        if (kDebugMode) {
          print('⚠️ [OrderService] 响应data为null');
        }
        return [];
      }

      if (kDebugMode) {
        print('📦 [OrderService] 响应数据: $data');
      }

      // API返回格式: { code: 0, msg: "...", data: { total: int, items: [...] } }
      final dataMap = data['data'] as Map<String, dynamic>?;
      if (dataMap == null) {
        if (kDebugMode) {
          print('⚠️ [OrderService] 响应data.data为null');
        }
        return [];
      }

      final List<dynamic> ordersJson = dataMap['items'] as List<dynamic>? ?? [];

      if (kDebugMode) {
        print('📊 [OrderService] 总订单数: ${dataMap['total']}');
        print('📋 [OrderService] 当前页订单数量: ${ordersJson.length}');
      }

      final orders = ordersJson
          .map((json) => OrderModel.fromJson(json as Map<String, dynamic>))
          .toList();

      if (kDebugMode) {
        print('✅ [OrderService] 成功解析 ${orders.length} 个订单');
        if (orders.isNotEmpty) {
          print('📋 [OrderService] 第一个订单: ${orders.first.orderNo}');
        }
      }

      return orders;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ [OrderService] 获取订单列表失败');
        print('❌ [OrderService] 错误: $e');
        print('❌ [OrderService] 堆栈: $stackTrace');
      }
      throw Exception('获取订单列表失败: $e');
    }
  }

  /// 获取订单详情
  /// [orderNo] 订单号
  Future<OrderModel> getOrderDetail(String orderNo) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/customer/order/$orderNo',
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
        '/customer/orders/$orderNo/cancel',
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}
