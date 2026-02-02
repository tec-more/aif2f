import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:aif2f/data/models/payment_model.dart';
import 'package:aif2f/data/providers/payment_provider.dart';
import 'package:aif2f/data/providers/qixiang_pay_provider.dart';

/// 充值页面
@RoutePage()
class RechargePage extends ConsumerStatefulWidget {
  const RechargePage({super.key});

  @override
  ConsumerState<RechargePage> createState() => _RechargePageState();
}

class _RechargePageState extends ConsumerState<RechargePage> {
  final List<double> _presetAmounts = [
    9.9,
    19.9,
    49.9,
    99.9,
    199.9,
    499.9,
  ];
  double? _selectedAmount;
  PaymentType? _selectedPaymentType;

  // 生成订单号
  String _generateOrderNo() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond % 10000;
    return 'RECHARGE$timestamp$random';
  }

  Future<void> _handlePayment(PaymentType type) async {
    if (_selectedAmount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请选择充值金额'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _selectedPaymentType = type;
    final orderNo = _generateOrderNo();

    PaymentOrder? order;

    // 微信支付使用七相支付，支付宝使用原有支付服务
    if (type == PaymentType.wechat) {
      final qixiangNotifier = ref.read(qixiangPayProvider.notifier);
      order = await qixiangNotifier.createPaymentOrder(
        type: type,
        outTradeNo: orderNo,
        money: _selectedAmount!,
        name: '账户充值',
        param: '充值金额: ¥${_selectedAmount!.toStringAsFixed(2)}',
      );
    } else {
      final paymentNotifier = ref.read(paymentProvider.notifier);
      order = await paymentNotifier.createPaymentOrder(
        outTradeNo: orderNo,
        amount: _selectedAmount!,
        subject: '账户充值',
        body: '充值金额: ¥${_selectedAmount!.toStringAsFixed(2)}',
        type: type,
      );
    }

    if (!mounted) return;

    if (order != null) {
      // 显示支付对话框并自动打开支付链接
      _showPaymentDialog(order, type);
      await _openPaymentUrl(order, type);
    } else {
      // 显示错误信息
      final errorMsg = type == PaymentType.wechat
          ? ref.read(qixiangPayProvider).errorMessage ?? '创建订单失败'
          : ref.read(paymentProvider).errorMessage ?? '创建订单失败';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _openPaymentUrl(PaymentOrder order, PaymentType type) async {
    Uri? uri;

    if (type == PaymentType.alipay) {
      // 支付宝：使用 qr_code URL
      if (order.qrCode != null) {
        uri = Uri.parse(order.qrCode!);
      }
    } else if (type == PaymentType.wechat) {
      // 微信支付：七相支付返回的 payUrl（七相支付）
      if (order.qrCode != null) {
        uri = Uri.parse(order.qrCode!);
      }
    }

    if (uri != null && await canLaunchUrl(uri)) {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('无法打开支付页面，请稍后重试'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _showPaymentDialog(PaymentOrder order, PaymentType type) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PaymentDialog(
        order: order,
        type: type,
        onOpenPayment: () => _openPaymentUrl(order, type),
        onConfirm: () {
          Navigator.of(context).pop();
          // 轮询订单状态
          _pollOrderStatus(order.orderId, type);
        },
        onCancel: () {
          Navigator.of(context).pop();
          // 根据支付类型重置相应的provider
          if (type == PaymentType.wechat) {
            ref.read(qixiangPayProvider.notifier).reset();
          } else {
            ref.read(paymentProvider.notifier).reset();
          }
        },
      ),
    );
  }

  Future<void> _pollOrderStatus(String orderId, PaymentType type) async {
    // 显示加载对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _PollingDialog(),
    );

    bool success;

    // 根据支付类型调用不同的服务
    if (type == PaymentType.wechat) {
      final qixiangNotifier = ref.read(qixiangPayProvider.notifier);
      success = await qixiangNotifier.pollOrderStatus(
        orderId,
        type,
        maxAttempts: 30,
        intervalSeconds: 2,
      );
    } else {
      final paymentNotifier = ref.read(paymentProvider.notifier);
      success = await paymentNotifier.pollOrderStatus(
        orderId,
        type,
        maxAttempts: 30,
        intervalSeconds: 2,
      );
    }

    if (!mounted) return;

    // 关闭加载对话框
    Navigator.of(context).pop();

    if (success) {
      // 显示成功对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _SuccessDialog(
          amount: _selectedAmount!,
          onConfirm: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop(); // 返回上一页
          },
        ),
      );
    } else {
      // 显示失败信息
      final errorMsg = type == PaymentType.wechat
          ? ref.read(qixiangPayProvider).errorMessage ?? '支付失败'
          : ref.read(paymentProvider).errorMessage ?? '支付失败';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('账户充值'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 余额显示
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '账户余额',
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      '¥0.00',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 选择充值金额
            const Text(
              '选择充值金额',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // 预设金额网格
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2,
              ),
              itemCount: _presetAmounts.length,
              itemBuilder: (context, index) {
                final amount = _presetAmounts[index];
                final isSelected = _selectedAmount == amount;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedAmount = amount;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '¥${amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // 支付方式
            const Text(
              '选择支付方式',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // 支付宝
            _PaymentMethodCard(
              icon: Icons.account_balance_wallet,
              title: '支付宝',
              subtitle: '推荐使用支付宝支付',
              color: const Color(0xFF1677FF),
              isSelected: _selectedPaymentType == PaymentType.alipay,
              onTap: () => _handlePayment(PaymentType.alipay),
            ),
            const SizedBox(height: 12),

            // 微信支付
            _PaymentMethodCard(
              icon: Icons.wechat,
              title: '微信支付',
              subtitle: '微信安全支付',
              color: const Color(0xFF07C160),
              isSelected: _selectedPaymentType == PaymentType.wechat,
              onTap: () => _handlePayment(PaymentType.wechat),
            ),
          ],
        ),
      ),
    );
  }
}

/// 支付方式卡片
class _PaymentMethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? color : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

/// 支付确认对话框
class _PaymentDialog extends StatelessWidget {
  final PaymentOrder order;
  final PaymentType type;
  final VoidCallback onOpenPayment;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _PaymentDialog({
    required this.order,
    required this.type,
    required this.onOpenPayment,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isAlipay = type == PaymentType.alipay;
    final isWechat = type == PaymentType.wechat;

    return AlertDialog(
      title: Text(isAlipay ? '支付宝支付' : '微信支付'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '订单金额: ¥${order.amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text('订单号: ${order.orderId}'),
          const SizedBox(height: 8),
          if (isAlipay) ...[
            const Text('请在支付宝中完成支付'),
            if (order.qrCode != null) ...[
              const SizedBox(height: 16),
              const Text('点击下方按钮打开支付页面'),
            ],
          ],
          if (isWechat) ...[
            const Text('请在微信中完成支付'),
            if (order.qrCode != null) ...[
              const SizedBox(height: 16),
              const Text('点击下方按钮打开支付页面'),
            ],
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('取消'),
        ),
        if (order.qrCode != null)
          ElevatedButton.icon(
            onPressed: onOpenPayment,
            icon: const Icon(Icons.payment, size: 18),
            label: const Text('打开支付'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isAlipay ? const Color(0xFF1677FF) : const Color(0xFF07C160),
            ),
          ),
        ElevatedButton(
          onPressed: onConfirm,
          child: const Text('已完成支付'),
        ),
      ],
    );
  }
}

/// 轮询对话框
class _PollingDialog extends StatelessWidget {
  const _PollingDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text('正在确认支付...'),
          const SizedBox(height: 8),
          Text(
            '请稍候',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

/// 成功对话框
class _SuccessDialog extends StatelessWidget {
  final double amount;
  final VoidCallback onConfirm;

  const _SuccessDialog({
    required this.amount,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.green[100],
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.green,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '支付成功',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text('充值金额: ¥${amount.toStringAsFixed(2)}'),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: onConfirm,
          child: const Text('确定'),
        ),
      ],
    );
  }
}
