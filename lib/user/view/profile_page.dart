import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

/// 个人信息页面
@RoutePage()
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('个人信息'),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('个人信息页面'),
      ),
    );
  }
}
