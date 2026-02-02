import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aif2f/data/providers/auth_provider.dart';
import 'package:aif2f/components/button/primary_button.dart';

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
  bool _obscurePassword = true;
  bool _isLoginMode = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
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

    final success = await authNotifier.register(username, email, password);

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
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 标题
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
                const SizedBox(height: 24),

                // 用户名输入框
                TextFormField(
                  controller: _usernameController,
                  enabled: !isLoading,
                  decoration: const InputDecoration(
                    labelText: '用户名',
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

                // 密码输入框
                TextFormField(
                  controller: _passwordController,
                  enabled: !isLoading,
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
                PrimaryButton(
                  text: _isLoginMode ? '登录' : '注册',
                  onPressed: () {
                    if (_isLoginMode) {
                      _handleLogin();
                    } else {
                      _handleRegister();
                    }
                  },
                  isDisabled: isLoading,
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
      ),
    );
  }
}
