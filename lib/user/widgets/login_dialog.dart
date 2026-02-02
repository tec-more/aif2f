import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aif2f/data/providers/auth_provider.dart';
import 'package:aif2f/components/button/primary_button.dart';
import 'package:aif2f/data/services/verification_service.dart';
import 'package:aif2f/data/models/verification_model.dart';

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
    // 注册模式使用邮箱
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先输入邮箱'), backgroundColor: Colors.orange),
      );
      return;
    }

    // 简单的邮箱格式验证
    if (!email.contains('@') || !email.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效的邮箱地址'), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      final verificationService = VerificationService();
      await verificationService.sendVerificationCode(
        email: email,
        type: VerificationCodeType.register,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('验证码已发送，请查收邮箱'), backgroundColor: Colors.green),
      );

      // 开始倒计时
      setState(() {
        _countdown = 60;
      });
      _startCountdown();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
      );
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
      final errorMsg = ref.read(authProvider).errorMessage ?? '登录失败';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authNotifier = ref.read(authProvider.notifier);
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final success = await authNotifier.register(
      username,
      email,
      password,
    );

    if (!mounted) return;

    if (success) {
      // 注册成功，关闭对话框
      Navigator.of(context).pop(true);
      widget.onLoginSuccess?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('注册成功'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // 显示错误信息
      final errorMsg = ref.read(authProvider).errorMessage ?? '注册失败';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
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
