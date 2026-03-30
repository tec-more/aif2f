import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aif2f/core/router/app_router.dart';
import 'package:aif2f/data/providers/auth_provider.dart';
import 'package:aif2f/data/providers/membership_provider.dart';
import 'package:aif2f/data/services/toast_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // 延迟执行，避免在 widget tree 构建时修改 provider
    Future(() {
      _initializeAuth();
    });
  }

  Future<void> _initializeAuth() async {
    await ref.read(authProvider.notifier).initializeAuth();
    // 初始化会员信息
    ref.read(membershipProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '笑话面对面',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1), // 靛蓝色 - 主色调
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      routerConfig: AppRouter().config(),
      builder: (context, child) {
        return Navigator(
          key: ToastService.navigatorKey,
          onGenerateRoute: (settings) {
            return MaterialPageRoute(builder: (context) => child!);
          },
        );
      },
    );
  }
}
