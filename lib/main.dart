import 'package:flutter/material.dart';
import 'package:aif2f/core/router/app_router.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AI面对面',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0078D4), // Windows 11 蓝色
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        popupMenuTheme: const PopupMenuThemeData(color: Colors.white),
      ),
      routerConfig: AppRouter().config(),
    );
  }
}
