import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aif2f/data/providers/auth_provider.dart';
import 'package:aif2f/components/button/primary_button.dart';
import 'package:aif2f/data/services/verification_service.dart';
import 'package:aif2f/data/models/verification_model.dart';
import 'package:aif2f/data/services/toast_service.dart';

/// 清理错误信息，移除技术性前缀和符号
String _cleanErrorMessage(String errorMsg) {
  // 移除常见的异常前缀
  errorMsg = errorMsg.replaceAll('Exception: ', '');
  errorMsg = errorMsg.replaceAll('Error: ', '');

  // 移除 Dio 相关的技术性前缀
  errorMsg = errorMsg.replaceAll(RegExp(r'_dio@\w+:\s*'), '');
  errorMsg = errorMsg.replaceAll(RegExp(r'DioException:\s*'), '');
  errorMsg = errorMsg.replaceAll(RegExp(r'dio:\s*'), '');

  // 移除 Dart 对象描述
  errorMsg = errorMsg.replaceAll(RegExp(r'^Instance of\s+'), '');

  // 移除开头的 > 符号和空格（包括多个）
  errorMsg = errorMsg.replaceAll(RegExp(r'^\s*>\s*'), '');
  errorMsg = errorMsg.replaceAll(RegExp(r'^>\s*'), '');

  // 移除可能的换行符和多余空格
  errorMsg = errorMsg.replaceAll('\n', ' ');
  errorMsg = errorMsg.replaceAll(RegExp(r'\s+'), ' ');
  errorMsg = errorMsg.trim();

  // 如果清理后为空，返回默认消息
  return errorMsg.isNotEmpty ? errorMsg : '操作失败，请稍后重试';
}

/// 登录对话框
class LoginDialog extends ConsumerStatefulWidget {
  final VoidCallback? onLoginSuccess;

  const LoginDialog({
    super.key,
    this.onLoginSuccess,
  });

  @override
  ConsumerState<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends ConsumerState<LoginDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _verificationCodeController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoginMode = true;

  // 验证码倒计时
  int _countdown = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    // 延迟执行，避免在 widget tree 构建时修改 provider
    Future(() {
      // 如果当前状态是 loading，重置为未认证状态
      // 这是为了解决应用启动时自动登录卡住的问题
      final authState = ref.read(authProvider);
      if (authState.status == AuthStatus.loading && mounted) {
        ref.read(authProvider.notifier).resetToUnauthenticated();
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _verificationCodeController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  // 发送验证码
  Future<void> _sendVerificationCode() async {
    // 防止重复发送：如果正在倒计时，直接返回
    if (_countdown > 0) {
      toastService.showWarning('请等待 $_countdown 秒后再试');
      return;
    }

    // 注册模式使用邮箱
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      toastService.showWarning('请先输入邮箱');
      return;
    }

    // 简单的邮箱格式验证
    if (!email.contains('@') || !email.contains('.')) {
      toastService.showWarning('请输入有效的邮箱地址');
      return;
    }

    // 立即开始倒计时，不等待API返回
    setState(() {
      _countdown = 60;
    });
    _startCountdown();

    // 异步发送验证码
    try {
      final verificationService = VerificationService();
      await verificationService.sendVerificationCode(
        email: email,
        type: VerificationCodeType.register,
      );

      if (!mounted) return;

      toastService.showSuccess('验证码已发送，请查收邮箱');
    } catch (e) {
      if (!mounted) return;
      // 发送失败，但倒计时继续，避免频繁点击
      final errorMsg = _cleanErrorMessage(e.toString());
      toastService.showWarning(errorMsg);
    }
  }

  // 开始倒计时
  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authNotifier = ref.read(authProvider.notifier);
    final email = _usernameController.text.trim();
    final password = _passwordController.text;

    final success = await authNotifier.login(email, password);

    if (!mounted) return;

    if (success) {
      // 登录成功，关闭对话框
      Navigator.of(context).pop(true);
      widget.onLoginSuccess?.call();
    } else {
      // 显示错误信息
      final rawErrorMsg = ref.read(authProvider).errorMessage ?? '登录失败';
      final errorMsg = _cleanErrorMessage(rawErrorMsg);
      toastService.showError(errorMsg);
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (kDebugMode) {
      print('🎯 [LoginDialog] 开始处理注册');
    }

    final authNotifier = ref.read(authProvider.notifier);
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final verificationCode = _verificationCodeController.text.trim();

    if (kDebugMode) {
      print('📥 [LoginDialog] 注册表单数据:');
      print('  - 用户名: $username');
      print('  - 邮箱: $email');
      print('  - 密码: ${password.length > 0 ? "***" : ""}');
      print('  - 验证码: $verificationCode');
    }

    final success = await authNotifier.register(
      username,
      email,
      password,
      verificationCode,
    );

    if (kDebugMode) {
      print('📤 [LoginDialog] authNotifier.register() 返回: $success');
    }

    if (!mounted) return;

    if (success) {
      if (kDebugMode) {
        print('✅ [LoginDialog] 注册成功，显示成功提示');
      }

      // 注册成功，先显示提示，再关闭对话框
      toastService.showSuccess('注册成功');

      // 延迟关闭对话框，让用户看到成功提示
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          if (kDebugMode) {
            print('🚪 [LoginDialog] 关闭对话框');
          }
          Navigator.of(context).pop(true);
          widget.onLoginSuccess?.call();
        }
      });
    } else {
      if (kDebugMode) {
        print('❌ [LoginDialog] 注册失败，显示错误信息');
      }

      // 显示错误信息
      final authState = ref.read(authProvider);
      final rawErrorMsg = authState.errorMessage ?? '注册失败';
      if (kDebugMode) {
        print('❌ [LoginDialog] AuthState 错误: $rawErrorMsg');
      }

      final errorMsg = _cleanErrorMessage(rawErrorMsg);
      if (kDebugMode) {
        print('❌ [LoginDialog] 清理后的错误: $errorMsg');
      }

      toastService.showError(errorMsg);
    }

    if (kDebugMode) {
      print('🏁 [LoginDialog] _handleRegister() 结束');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Stack(
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 标题栏
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Column(
                    children: [
                      Icon(
                        _isLoginMode ? Icons.login : Icons.person_add,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isLoginMode ? '欢迎回来' : '创建账户',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isLoginMode ? '登录到您的账户' : '注册新账户',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // 表单区域
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // 用户名/邮箱输入框
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: _isLoginMode ? '邮箱' : '用户名',
                            prefixIcon: const Icon(Icons.person),
                            border: const OutlineInputBorder(),
                            hintText: _isLoginMode ? '请输入邮箱' : '请输入用户名',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return _isLoginMode ? '请输入邮箱' : '请输入用户名';
                            }
                            // 登录模式下，验证邮箱格式
                            if (_isLoginMode) {
                              if (!value.trim().contains('@') || !value.trim().contains('.')) {
                                return '请输入有效的邮箱地址';
                              }
                            } else {
                              // 注册模式下，用户名至少3个字符
                              if (value.trim().length < 3) {
                                return '用户名至少3个字符';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // 邮箱输入框（仅注册模式）
                        if (!_isLoginMode) ...[
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: '邮箱',
                              prefixIcon: Icon(Icons.email),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return '请输入邮箱';
                              }
                              // 简单的邮箱格式验证
                              if (!value.contains('@') || !value.contains('.')) {
                                return '请输入有效的邮箱地址';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        // 验证码输入框（仅注册模式）
                        if (!_isLoginMode) ...[
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _verificationCodeController,
                                  decoration: const InputDecoration(
                                    labelText: '验证码',
                                    prefixIcon: Icon(Icons.verified_user),
                                    border: OutlineInputBorder(),
                                    hintText: '请输入验证码',
                                  ),
                                  validator: (value) {
                                    // 注册模式下验证码必填
                                    if (value == null || value.trim().isEmpty) {
                                      return '请输入验证码';
                                    }
                                    if (value.trim().length != 6) {
                                      return '验证码为6位数字';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _countdown > 0
                                      ? null
                                      : _sendVerificationCode,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _countdown > 0
                                        ? Colors.grey
                                        : Theme.of(context).colorScheme.primary,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: Colors.grey,
                                  ),
                                  child: Text(
                                    _countdown > 0
                                        ? '$_countdown秒后重试'
                                        : '发送验证码',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],

                        // 密码输入框
                        TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: '密码',
                              prefixIcon: const Icon(Icons.lock),
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '请输入密码';
                              }
                              if (value.length < 6) {
                                return '密码至少6个字符';
                              }
                              return null;
                            },
                          ),

                        const SizedBox(height: 24),

                        // 登录/注册按钮
                        SizedBox(
                          width: double.infinity,
                          child: PrimaryButton(
                            text: isLoading ? '处理中...' : (_isLoginMode ? '登录' : '注册'),
                            onPressed: () {
                              if (_isLoginMode) {
                                _handleLogin();
                              } else {
                                _handleRegister();
                              }
                            },
                            isDisabled: isLoading,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 切换登录/注册模式
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  setState(() {
                                    _isLoginMode = !_isLoginMode;
                                  });
                                },
                          child: Text(
                            _isLoginMode ? '还没有账户？立即注册' : '已有账户？去登录',
                          ),
                        ),

                        // 取消按钮
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  Navigator.of(context).pop(false);
                                },
                          child: const Text('取消'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 关闭按钮
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close),
              onPressed: isLoading
                  ? null
                  : () {
                      Navigator.of(context).pop(false);
                    },
              tooltip: '关闭',
            ),
          ),
        ],
      ),
    );
  }
}
