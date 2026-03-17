import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

/// 支付对话框组件
class PaymentDialog extends StatefulWidget {
  final String title;
  final String url;
  final VoidCallback onClose;

  const PaymentDialog({
    Key? key,
    required this.title,
    required this.url,
    required this.onClose,
  }) : super(key: key);

  @override
  _PaymentDialogState createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  late InAppWebViewController _controller;
  bool _isLoading = true;
  String _currentUrl = '';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.4,
        height: MediaQuery.of(context).size.height,
        child: Column(
          children: [
            // 标题栏
            Container(
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.transparent, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
            ),
            // InAppWebView内容
            Expanded(
              child: Stack(
                children: [
                  InAppWebView(
                    initialUrlRequest: URLRequest(url: WebUri(widget.url)),
                    onWebViewCreated: (controller) {
                      _controller = controller;
                    },
                    onLoadStart: (controller, url) {
                      setState(() {
                        _isLoading = true;
                        if (url != null) {
                          _currentUrl = url.toString();
                        }
                      });
                    },
                    onLoadStop: (controller, url) {
                      setState(() {
                        _isLoading = false;
                        if (url != null) {
                          _currentUrl = url.toString();
                        }
                      });
                    },
                    onLoadError: (controller, url, code, message) {
                      setState(() {
                        _isLoading = false;
                      });
                      print('加载错误: $message (代码: $code)');
                    },
                    onConsoleMessage: (controller, consoleMessage) {
                      print('控制台消息: ${consoleMessage.message}');
                    },
                  ),
                  if (_isLoading)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          const Text('加载支付页面中...'),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 显示支付对话框的工具方法
void showPaymentDialog({
  required BuildContext context,
  required String title,
  required String url,
  required VoidCallback onClose,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) =>
        PaymentDialog(title: title, url: url, onClose: onClose),
  );
}
