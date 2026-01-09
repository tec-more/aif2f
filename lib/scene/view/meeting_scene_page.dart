import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:aif2f/scene/model/scene_model.dart';
import 'package:aif2f/scene/view/scene_menu.dart';
import 'package:aif2f/user/view/user_menu.dart';

/// 会议场景页面
@RoutePage()
class MeetingScenePage extends StatelessWidget {
  const MeetingScenePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('会议场景'),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          SceneMenu(selectedScene: SceneType.meeting),
          const UserMenu(),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.meeting_room,
              size: 80,
              color: Colors.green,
            ),
            SizedBox(height: 20),
            Text(
              '会议场景',
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
