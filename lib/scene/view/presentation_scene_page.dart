import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

/// 演讲场景页面
@RoutePage()
class PresentationScenePage extends StatelessWidget {
  const PresentationScenePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('演讲场景'),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.present_to_all,
              size: 80,
              color: Colors.blue,
            ),
            SizedBox(height: 20),
            Text(
              '演讲场景',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('此功能正在开发中...'),
          ],
        ),
      ),
    );
  }
}
