import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aif2f/data/models/product_model.dart';
import 'package:aif2f/data/models/order_model.dart';
import 'package:aif2f/data/services/product_service.dart';
import 'package:aif2f/data/providers/auth_provider.dart';

/// 产品服务 Provider
final productServiceProvider = Provider<ProductService>((ref) {
  return ProductService();
});

/// 订单服务 Provider
final orderServiceProvider = Provider<OrderService>((ref) {
  return OrderService();
});

/// 产品列表状态
class ProductState {
  final List<ProductModel> products;
  final bool isLoading;
  final String? errorMessage;

  ProductState({
    this.products = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  ProductState copyWith({
    List<ProductModel>? products,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ProductState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// 产品列表 Notifier
class ProductNotifier extends Notifier<ProductState> {
  @override
  ProductState build() {
    // 初始化时加载产品列表
    _loadProducts();
    return ProductState(isLoading: true);
  }

  ProductService get _service => ref.read(productServiceProvider);

  /// 加载产品列表
  Future<void> _loadProducts() async {
    try {
      final products = await _service.getProducts();
      state = ProductState(products: products, isLoading: false);
    } catch (e) {
      state = ProductState(
        products: [],
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// 刷新产品列表
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _loadProducts();
  }

  /// 清除错误信息
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// 产品列表 State Provider
final productProvider = NotifierProvider<ProductNotifier, ProductState>(ProductNotifier.new);

/// 便捷访问：产品列表
final productsProvider = Provider<List<ProductModel>>((ref) {
  final state = ref.watch(productProvider);
  return state.products;
});

/// 订单列表状态
class OrderState {
  final List<OrderModel> orders;
  final bool isLoading;
  final String? errorMessage;

  OrderState({
    this.orders = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  OrderState copyWith({
    List<OrderModel>? orders,
    bool? isLoading,
    String? errorMessage,
  }) {
    return OrderState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// 订单列表 Notifier
class OrderNotifier extends Notifier<OrderState> {
  @override
  OrderState build() {
    return OrderState();
  }

  OrderService get _service => ref.read(orderServiceProvider);

  /// 加载订单列表
  Future<void> loadOrders({int page = 1, int pageSize = 20}) async {
    if (kDebugMode) {
      print('════════════════════════════════════════');
      print('🔄 [OrderNotifier] 开始加载订单列表');
      print('📋 [OrderNotifier] 页码: $page, 每页: $pageSize');
      print('════════════════════════════════════════');
    }

    // 获取当前登录用户ID
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated || authState.user == null) {
      if (kDebugMode) {
        print('❌ [OrderNotifier] 用户未登录');
      }
      state = OrderState(
        orders: [],
        isLoading: false,
        errorMessage: '请先登录',
      );
      return;
    }

    final customerId = authState.user!.id;

    if (kDebugMode) {
      print('👤 [OrderNotifier] 客户ID: $customerId');
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final orders = await _service.getOrders(customerId, page: page, pageSize: pageSize);

      if (kDebugMode) {
        print('✅ [OrderNotifier] 订单加载成功');
        print('📋 [OrderNotifier] 订单数量: ${orders.length}');
        if (orders.isNotEmpty) {
          for (var i = 0; i < orders.length; i++) {
            print('   ${i + 1}. ${orders[i].orderNo} - ${orders[i].status.displayName} - ¥${orders[i].amount}');
          }
        }
      }

      state = OrderState(orders: orders, isLoading: false);
    } catch (e) {
      if (kDebugMode) {
        print('❌ [OrderNotifier] 订单加载失败');
        print('❌ [OrderNotifier] 错误: $e');
      }
      state = OrderState(
        orders: [],
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }

    if (kDebugMode) {
      print('════════════════════════════════════════');
      print('🏁 [OrderNotifier] 订单加载流程结束');
      print('════════════════════════════════════════');
    }
  }

  /// 刷新订单列表
  Future<void> refresh() async {
    await loadOrders();
  }

  /// 取消订单
  Future<bool> cancelOrder(String orderNo) async {
    try {
      final success = await _service.cancelOrder(orderNo);
      if (success) {
        // 从列表中移除该订单
        final updatedOrders = state.orders.where((order) => order.orderNo != orderNo).toList();
        state = state.copyWith(orders: updatedOrders);
      }
      return success;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  /// 清除错误信息
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// 订单列表 State Provider
final orderProvider = NotifierProvider<OrderNotifier, OrderState>(OrderNotifier.new);

/// 便捷访问：订单列表
final ordersProvider = Provider<List<OrderModel>>((ref) {
  final state = ref.watch(orderProvider);
  return state.orders;
});
