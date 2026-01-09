import 'package:flutter/material.dart';

/// 场景类型
enum SceneType {
  interpretation, // 传译
  presentation, // 演讲
  meeting, // 会议
  education, // 教育
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
];

// ==================== 活动相关模型 ====================

/// 活动状态
enum ActivityStatus {
  /// 进行中
  active,

  /// 已暂停
  paused,

  /// 已完成
  completed,

  /// 已归档
  archived,
}

/// 场景活动模型
/// 每个场景可以有多个活动
class SceneActivity {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final ActivityStatus status;
  final SceneType sceneType;

  SceneActivity({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    this.status = ActivityStatus.active,
    required this.sceneType,
  });

  /// 创建副本并修改部分属性
  SceneActivity copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
    ActivityStatus? status,
    SceneType? sceneType,
  }) {
    return SceneActivity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      sceneType: sceneType ?? this.sceneType,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'status': status.index,
      'sceneType': sceneType.name,
    };
  }

  /// 从 JSON 创建
  factory SceneActivity.fromJson(Map<String, dynamic> json) {
    return SceneActivity(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: ActivityStatus.values[json['status'] as int],
      sceneType: SceneType.values.firstWhere(
        (e) => e.name == json['sceneType'],
        orElse: () => SceneType.interpretation,
      ),
    );
  }
}

/// 场景活动管理器
/// 负责管理所有场景的活动
class SceneActivityManager {
  final List<SceneActivity> _activities = [];

  /// 获取所有活动
  List<SceneActivity> get activities => List.unmodifiable(_activities);

  /// 获取指定场景的活动
  List<SceneActivity> getActivitiesByScene(SceneType sceneType) {
    return _activities
        .where((activity) => activity.sceneType == sceneType)
        .toList();
  }

  /// 获取指定状态的活动
  List<SceneActivity> getActivitiesByStatus(ActivityStatus status) {
    return _activities.where((activity) => activity.status == status).toList();
  }

  /// 添加活动
  void addActivity(SceneActivity activity) {
    _activities.add(activity);
  }

  /// 更新活动
  void updateActivity(SceneActivity updatedActivity) {
    final index = _activities.indexWhere((a) => a.id == updatedActivity.id);
    if (index != -1) {
      _activities[index] = updatedActivity;
    }
  }

  /// 删除活动
  void deleteActivity(String id) {
    _activities.removeWhere((activity) => activity.id == id);
  }

  /// 根据 ID 获取活动
  SceneActivity? getActivityById(String id) {
    try {
      return _activities.firstWhere((activity) => activity.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 清空所有活动
  void clear() {
    _activities.clear();
  }
}

