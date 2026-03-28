import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aif2f/data/models/product_model.dart';
import 'package:aif2f/data/models/payment_model.dart';
import 'package:aif2f/data/providers/payment_provider.dart';
import 'package:aif2f/data/providers/auth_provider.dart';

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
      // 生成订单号
      final orderNo = 'ORD${DateTime.now().millisecondsSinceEpoch}';

      // 获取当前用户ID
      final authState = ref.read(authProvider);
      final customerId = authState.user?.id;

      if (kDebugMode) {
        print('🔄 [PaymentMethodDialog] 开始创建支付订单');
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
  bool _isPolling = false;
  bool _isLoadingQRCode = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadQRCode();
  }

  Future<void> _loadQRCode() async {
    setState(() {
      _isLoadingQRCode = true;
      _errorMessage = null;
    });

    try {
      if (kDebugMode) {
        print(
          '🔄 [PaymentQRCodeDialog] 开始生成支付信息，订单ID: ${widget.order.orderId}',
        );
      }

      final qrCodeOrder = await ref
          .read(paymentProvider.notifier)
          .createQixiangPayment(widget.order);

      if (kDebugMode) {
        print('✅ [PaymentQRCodeDialog] 生成支付信息成功: ${qrCodeOrder?.qrCode}');
      }

      if (qrCodeOrder != null && mounted) {
        setState(() {
          _isLoadingQRCode = false;
        });
        _startPolling();
      } else {
        setState(() {
          _errorMessage = '生成支付信息失败';
          _isLoadingQRCode = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [PaymentQRCodeDialog] 生成支付信息异常: $e');
      }
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoadingQRCode = false;
      });
    }
  }

  Future<void> _startPolling() async {
    setState(() {
      _isPolling = true;
    });

    try {
      await ref
          .read(paymentProvider.notifier)
          .pollOrderStatus(widget.order.orderId, PaymentType.wechat);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('支付成功！'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [PaymentQRCodeDialog] 订单轮询异常: $e');
      }
      if (mounted) {
        setState(() {
          _isPolling = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('扫码支付'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '订单号：${widget.order.orderId}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            '复制下方链接在微信中打开支付',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 250,
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[50],
            ),
            child: Center(
              child: _errorMessage != null
                  ? Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    )
                  : _isLoadingQRCode
                  ? const CircularProgressIndicator()
                  : widget.order.qrCode != null
                  ? Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          widget.order.qrCode!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: Theme.of(context).colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    )
                  : const Text('二维码生成中...'),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '¥${widget.product.price.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF07C160),
            ),
          ),
          const SizedBox(height: 8),
          if (_isPolling)
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('等待支付...'),
              ],
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}
