import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

/// 关于页面
@RoutePage()
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('关于'),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'AI面对面 - 智能对话应用',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            Text('版本 1.0.0'),
          ],
        ),
      ),
    );
  }
}
