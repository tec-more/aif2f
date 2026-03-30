import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:aif2f/data/models/product_model.dart';
import 'package:aif2f/data/models/payment_model.dart';
import 'package:aif2f/data/providers/payment_provider.dart';
import 'package:aif2f/data/providers/auth_provider.dart';
import 'package:aif2f/data/providers/membership_provider.dart';
import 'package:aif2f/data/services/toast_service.dart';

/// 支付方式选择对话框
class PaymentMethodDialog extends ConsumerStatefulWidget {
  final ProductModel product;

  const PaymentMethodDialog({super.key, required this.product});

  @override
  ConsumerState<PaymentMethodDialog> createState() =>
      _PaymentMethodDialogState();
}

class _PaymentMethodDialogState extends ConsumerState<PaymentMethodDialog> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleWeChatPay() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 获取当前用户ID
      final authState = ref.read(authProvider);

      if (kDebugMode) {
        print('🔄 [PaymentMethodDialog] 开始创建支付订单');
        print('🔍 [PaymentMethodDialog] 认证状态: ${authState.status}');
        print('👤 [PaymentMethodDialog] 用户是否为null: ${authState.user == null}');
        print('👤 [PaymentMethodDialog] 用户信息: ${authState.user}');
      }

      // 检查用户是否登录
      if (authState.user == null) {
        if (kDebugMode) {
          print('❌ [PaymentMethodDialog] 用户未登录');
        }
        setState(() {
          _errorMessage = '请先登录后再进行支付';
          _isLoading = false;
        });
        return;
      }

      final customerId = authState.user!.id;

      // 生成订单号
      final orderNo = 'ORD${DateTime.now().millisecondsSinceEpoch}';

      if (kDebugMode) {
        print('📧 [PaymentMethodDialog] 订单号: $orderNo');
        print('👤 [PaymentMethodDialog] 客户ID: $customerId');
        print('📦 [PaymentMethodDialog] 产品ID: ${widget.product.id}');
        print('💰 [PaymentMethodDialog] 金额: ${widget.product.price}');
      }

      // 创建支付订单
      final paymentNotifier = ref.read(paymentProvider.notifier);
      final order = await paymentNotifier.createPaymentOrder(
        outTradeNo: orderNo,
        amount: widget.product.price,
        subject: widget.product.name,
        body: '购买${widget.product.name}，获得${widget.product.totalHours}小时',
        type: PaymentType.wechat,
        productId: widget.product.id.toString(),
        customerId: customerId,
        productName: widget.product.name,
        productType: 'hours',
        unitPrice: widget.product.price,
      );

      if (kDebugMode) {
        print('🎯 [PaymentMethodDialog] 订单创建结果: $order');
        print('🔍 [PaymentMethodDialog] order 是否为null: ${order == null}');
      }

      if (order != null) {
        // 订单创建成功，关闭当前对话框
        if (kDebugMode) {
          print('✅ [PaymentMethodDialog] 订单创建成功，准备显示支付界面');
          print('📱 [PaymentMethodDialog] 二维码: ${order.qrCode}');
        }
        if (mounted) {
          Navigator.of(context).pop();
          _showPaymentQRCode(order);
        }
      } else {
        if (kDebugMode) {
          print('❌ [PaymentMethodDialog] 订单创建失败');
        }
        setState(() {
          _errorMessage = '创建支付订单失败';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _showPaymentQRCode(PaymentOrder order) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          _PaymentQRCodeDialog(order: order, product: widget.product),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择支付方式'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '购买：${widget.product.name}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '金额：¥${widget.product.price.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            '获得：${widget.product.totalHours}小时${widget.product.bonusHours != null && widget.product.bonusHours! > 0 ? " (含${widget.product.bonusHours}小时赠送)" : ""}',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          // 只显示微信支付选项
          ListTile(
            leading: const Icon(Icons.wechat, color: Color(0xFF07C160)),
            title: const Text('微信支付'),
            trailing: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
            onTap: _isLoading ? null : _handleWeChatPay,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
      ],
    );
  }
}

/// 支付二维码对话框
class _PaymentQRCodeDialog extends ConsumerStatefulWidget {
  final PaymentOrder order;
  final ProductModel product;

  const _PaymentQRCodeDialog({required this.order, required this.product});

  @override
  ConsumerState<_PaymentQRCodeDialog> createState() =>
      _PaymentQRCodeDialogState();
}

class _PaymentQRCodeDialogState extends ConsumerState<_PaymentQRCodeDialog> {
  bool _isCheckingPayment = false;
  bool _isLoadingQRCode = true;
  String? _errorMessage;
  PaymentOrder? _qrCodeOrder; // 保存包含二维码的订单

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print('🎬 [PaymentQRCodeDialog] initState 被调用');
      print('📋 [PaymentQRCodeDialog] 订单ID: ${widget.order.orderId}');
      print('📋 [PaymentQRCodeDialog] 订单类型: ${widget.order.type}');
      print('📋 [PaymentQRCodeDialog] 订单金额: ${widget.order.amount}');
    }
    _loadQRCode();
  }

  Future<void> _loadQRCode() async {
    if (kDebugMode) {
      print('════════════════════════════════════════');
      print('🔄 [PaymentQRCodeDialog] _loadQRCode 开始执行');
      print('════════════════════════════════════════');
    }

    setState(() {
      _isLoadingQRCode = true;
      _errorMessage = null;
    });

    try {
      if (kDebugMode) {
        print('📞 [PaymentQRCodeDialog] 准备调用 createQixiangPayment');
        print('📋 [PaymentQRCodeDialog] 订单ID: ${widget.order.orderId}');
      }

      final qrCodeOrder = await ref
          .read(paymentProvider.notifier)
          .createQixiangPayment(widget.order);

      if (kDebugMode) {
        print('🔄 [PaymentQRCodeDialog] createQixiangPayment 返回');
        print('📋 [PaymentQRCodeDialog] qrCodeOrder 是否为null: ${qrCodeOrder == null}');
        if (qrCodeOrder != null) {
          print('📋 [PaymentQRCodeDialog] 二维码链接: ${qrCodeOrder.qrCode}');
        }
      }

      if (qrCodeOrder != null && mounted) {
        setState(() {
          _qrCodeOrder = qrCodeOrder; // 保存包含二维码的订单
          _isLoadingQRCode = false;
        });
        if (kDebugMode) {
          print('✅ [PaymentQRCodeDialog] 二维码已生成，等待用户支付');
        }
        // 不再自动轮询，等待用户手动确认
      } else {
        if (kDebugMode) {
          print('❌ [PaymentQRCodeDialog] 二维码订单为null');
        }
        setState(() {
          _errorMessage = '生成支付信息失败';
          _isLoadingQRCode = false;
        });
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ [PaymentQRCodeDialog] 生成支付信息异常');
        print('❌ [PaymentQRCodeDialog] 错误: $e');
        print('❌ [PaymentQRCodeDialog] 类型: ${e.runtimeType}');
        print('❌ [PaymentQRCodeDialog] 堆栈: $stackTrace');
      }
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoadingQRCode = false;
      });
    }

    if (kDebugMode) {
      print('════════════════════════════════════════');
      print('🏁 [PaymentQRCodeDialog] _loadQRCode 执行完毕');
      print('════════════════════════════════════════');
    }
  }

  /// 检查支付状态（用户点击"已完成支付"时调用）
  Future<void> _checkPaymentStatus() async {
    setState(() {
      _isCheckingPayment = true;
    });

    try {
      if (kDebugMode) {
        print('🔄 [PaymentQRCodeDialog] 检查支付状态');
        print('📋 [PaymentQRCodeDialog] 订单ID: ${widget.order.orderId}');
      }

      await ref.read(paymentProvider.notifier).pollOrderStatus(
        widget.order.orderId,
        PaymentType.wechat,
        maxAttempts: 1, // 只查询一次
        intervalSeconds: 0,
      );

      if (kDebugMode) {
        print('✅ [PaymentQRCodeDialog] 支付状态查询完成');
      }

      if (mounted) {
        // 使用ToastService显示成功提示（Overlay方式，确保在最顶层）
        ToastService().showSuccess('支付成功！');

        // 关闭所有对话框（二维码对话框和支付方式选择对话框）
        Navigator.of(context).pop(); // 关闭二维码对话框
        Navigator.of(context).pop(); // 关闭支付方式选择对话框

        // 刷新用户信息和会员状态
        if (kDebugMode) {
          print('🔄 [PaymentQRCodeDialog] 刷新用户信息和会员状态');
        }
        await ref.read(authProvider.notifier).fetchCurrentUser();
        await ref.read(membershipProvider.notifier).refresh();

        // 延迟1秒后再次刷新，确保后端数据已更新
        await Future.delayed(const Duration(seconds: 1));
        if (kDebugMode) {
          print('🔄 [PaymentQRCodeDialog] 第二次刷新用户信息');
        }
        await ref.read(authProvider.notifier).fetchCurrentUser();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [PaymentQRCodeDialog] 支付状态查询失败: $e');
      }
      if (mounted) {
        setState(() {
          _isCheckingPayment = false;
        });
        // 使用ToastService显示错误提示
        ToastService().showWarning('支付尚未完成，请稍后再试');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('扫码支付'),
      content: SizedBox(
        width: 300,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '订单号：${widget.order.orderId}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: _errorMessage != null
                      ? Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        )
                      : _isLoadingQRCode
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('二维码生成中...', style: TextStyle(fontSize: 14)),
                              ],
                            )
                          : _qrCodeOrder?.qrCode != null
                              ? Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // 二维码图片
                                      QrImageView(
                                        data: _qrCodeOrder!.qrCode!,
                                        version: QrVersions.auto,
                                        size: 180.0,
                                        backgroundColor: Colors.white,
                                        errorCorrectionLevel: QrErrorCorrectLevel.H,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '请使用微信扫描二维码',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : const Text('二维码生成失败'),
                ),
              ),
              const SizedBox(height: 12),
              // 显示金额
              Text(
                '¥${widget.product.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF07C160),
                ),
              ),
              const SizedBox(height: 8),
              // 显示可复制的链接（作为备用）
              if (_qrCodeOrder?.qrCode != null)
                Column(
                  children: [
                    Text(
                      '或复制下方链接在微信中打开',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              _qrCodeOrder!.qrCode!,
                              style: TextStyle(
                                fontSize: 9,
                                fontFamily: 'monospace',
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () {
                              // 复制链接到剪贴板
                              Clipboard.setData(ClipboardData(text: _qrCodeOrder!.qrCode!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('链接已复制到剪贴板'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '复制',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              if (_isCheckingPayment)
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('正在确认支付...', style: TextStyle(fontSize: 13)),
                  ],
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        if (_qrCodeOrder?.qrCode != null && !_isCheckingPayment)
          ElevatedButton(
            onPressed: _checkPaymentStatus,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF07C160),
              foregroundColor: Colors.white,
            ),
            child: const Text('已完成支付'),
          ),
      ],
    );
  }
}
