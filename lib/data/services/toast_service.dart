import 'package:flutter/material.dart';

/// 消息类型枚举
enum ToastType {
  success,  // 成功
  error,    // 错误
  warning,  // 警告
  info,     // 信息
}

/// 全局消息通知服务
///
/// 使用 Overlay 确保消息总是显示在最顶层（包括 Dialog、BottomSheet 等）
class ToastService {
  // 私有构造函数，确保单例
  ToastService._internal();

  static final ToastService _instance = ToastService._internal();

  factory ToastService() => _instance;

  // Overlay 相关
  OverlayEntry? _overlayEntry;
  bool _isShowing = false;

  // 内部使用的 navigatorKey（静态，供外部访问）
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// 显示成功消息（绿色）
  void showSuccess(String message) {
    _showToast(
      message: message,
      type: ToastType.success,
    );
  }

  /// 显示错误消息（红色）
  void showError(String message) {
    _showToast(
      message: message,
      type: ToastType.error,
    );
  }

  /// 显示警告消息（橙色）
  void showWarning(String message) {
    _showToast(
      message: message,
      type: ToastType.warning,
    );
  }

  /// 显示信息消息（蓝色）
  void showInfo(String message) {
    _showToast(
      message: message,
      type: ToastType.info,
    );
  }

  /// 显示 Toast 消息
  void _showToast({
    required String message,
    required ToastType type,
    Duration duration = const Duration(seconds: 3),
  }) {
    // 如果已经有 Toast 在显示，先移除
    if (_isShowing && _overlayEntry != null) {
      _overlayEntry?.remove();
      _isShowing = false;
    }

    // 获取 NavigatorState
    final navigatorState = navigatorKey.currentState;
    if (navigatorState == null) {
      debugPrint('ToastService: NavigatorState is null');
      return;
    }

    // 获取 Overlay
    final overlay = navigatorState.overlay;
    if (overlay == null) {
      debugPrint('ToastService: Overlay is null');
      return;
    }

    // 创建 Toast Widget
    _overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        type: type,
        onRemoved: _removeToast,
      ),
    );

    // 插入 Overlay
    overlay.insert(_overlayEntry!);
    _isShowing = true;

    // 自动移除
    Future.delayed(duration, () {
      if (_isShowing) {
        _removeToast();
      }
    });
  }

  /// 移除 Toast
  void _removeToast() {
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      _isShowing = false;
    }
  }

  /// 清理资源
  void dispose() {
    _removeToast();
  }
}

/// Toast Widget 组件
class _ToastWidget extends StatefulWidget {
  final String message;
  final ToastType type;
  final VoidCallback onRemoved;

  const _ToastWidget({
    required this.message,
    required this.type,
    required this.onRemoved,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // 初始化动画控制器
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // 创建滑动动画（从顶部滑入）
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // 创建渐变动画
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // 播放入场动画
    _controller.forward();

    // 自动播放离场动画并移除
    Future.delayed(const Duration(seconds: 2, milliseconds: 700), () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onRemoved();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 根据类型获取背景色和图标
  Color get backgroundColor {
    switch (widget.type) {
      case ToastType.success:
        return Colors.green;
      case ToastType.error:
        return Colors.red;
      case ToastType.warning:
        return Colors.orange;
      case ToastType.info:
        return Colors.blue;
    }
  }

  IconData get icon {
    switch (widget.type) {
      case ToastType.success:
        return Icons.check_circle;
      case ToastType.error:
        return Icons.error;
      case ToastType.warning:
        return Icons.warning;
      case ToastType.info:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16, // 状态栏下方
      left: 16,
      right: 16,
      child: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 全局 Toast 服务实例
final toastService = ToastService();
