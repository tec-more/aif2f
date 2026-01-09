import 'package:flutter/material.dart';

/// 场景类型
enum SceneType {
  interpretation, // 传译
  presentation, // 演讲
  meeting, // 会议
  education, // 教育
  activity, // 活动
}

/// 场景信息
class Scene {
  final SceneType type;
  final String name;
  final IconData icon;

  Scene({required this.type, required this.name, required this.icon});
}

/// 所有场景
List<Scene> allScenes = [
  Scene(type: SceneType.interpretation, name: '传译', icon: Icons.translate),
  Scene(type: SceneType.presentation, name: '演讲', icon: Icons.present_to_all),
  Scene(type: SceneType.meeting, name: '会议', icon: Icons.meeting_room),
  Scene(type: SceneType.education, name: '教育', icon: Icons.school),
  Scene(type: SceneType.activity, name: '活动', icon: Icons.event_note),
];
