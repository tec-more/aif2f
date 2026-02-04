import 'dart:async';
import 'package:auto_route/auto_route.dart';
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

/// 登录页面
@RoutePage()
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authNotifier = ref.read(authProvider.notifier);
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    final success = await authNotifier.login(username, password);

    if (!mounted) return;

    if (success) {
      // 登录成功，返回上一页或导航到主页
      Navigator.of(context).pop();
    } else {
      // 显示错误信息
      final rawErrorMsg = ref.read(authProvider).errorMessage ?? '登录失败';
      final errorMsg = _cleanErrorMessage(rawErrorMsg);
      toastService.showError(errorMsg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo 或标题
                  const Icon(
                    Icons.person_outline,
                    size: 80,
                    color: Color(0xFF6366F1),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '欢迎回来',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '登录到您的账户',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // 用户名输入框
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: '用户名',
                      hintText: '请输入用户名',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入用户名';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 密码输入框
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: '密码',
                      hintText: '请输入密码',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入密码';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // 登录按钮
                  authState.status == AuthStatus.loading
                      ? const Center(child: CircularProgressIndicator())
                      : PrimaryButton(
                          text: '登录',
                          onPressed: () => _handleLogin(),
                          isDisabled: false,
                        ),
                  const SizedBox(height: 16),

                  // 注册链接
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('还没有账户？'),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const RegisterPage(),
                            ),
                          );
                        },
                        child: const Text('立即注册'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 注册页面
@RoutePage()
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _verificationCodeController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // 验证码倒计时
  int _countdown = 0;
  Timer? _countdownTimer;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authNotifier = ref.read(authProvider.notifier);
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final verificationCode = _verificationCodeController.text.trim();

    final success = await authNotifier.register(username, email, password, verificationCode);

    if (!mounted) return;

    if (success) {
      // 注册成功，先显示提示，再返回登录页
      toastService.showSuccess('注册成功，请登录');

      // 延迟关闭页面，让用户看到成功提示
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    } else {
      // 显示错误信息
      final rawErrorMsg = ref.read(authProvider).errorMessage ?? '注册失败';
      final errorMsg = _cleanErrorMessage(rawErrorMsg);
      toastService.showError(errorMsg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('注册'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '创建新账户',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // 用户名输入框
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: '用户名',
                      hintText: '请输入用户名',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入用户名';
                      }
                      if (value.trim().length < 3) {
                        return '用户名至少3个字符';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 邮箱输入框
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: '邮箱',
                      hintText: '请输入邮箱',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入邮箱';
                      }
                      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(value.trim())) {
                        return '请输入有效的邮箱地址';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 验证码输入框
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
                          onPressed: _countdown > 0 ? null : _sendVerificationCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _countdown > 0
                                ? Colors.grey
                                : Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(
                            _countdown > 0 ? '$_countdown秒后重试' : '发送验证码',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 密码输入框
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: '密码',
                      hintText: '请输入密码',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
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
                  const SizedBox(height: 16),

                  // 确认密码输入框
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: '确认密码',
                      hintText: '请再次输入密码',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请再次输入密码';
                      }
                      if (value != _passwordController.text) {
                        return '两次输入的密码不一致';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // 注册按钮
                  authState.status == AuthStatus.loading
                      ? const Center(child: CircularProgressIndicator())
                      : PrimaryButton(
                          text: '注册',
                          onPressed: () => _handleRegister(),
                          isDisabled: false,
                        ),
                  const SizedBox(height: 16),

                  // 登录链接
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('已有账户？'),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('立即登录'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
