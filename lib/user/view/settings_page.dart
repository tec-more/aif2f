import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

/// 设置页面
@RoutePage()
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('设置页面'),
      ),
    );
  }
}
