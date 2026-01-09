import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:aif2f/scene/model/scene_model.dart';
import 'package:aif2f/core/router/app_router.dart';

class SceneMenu extends StatelessWidget {
  final SceneType selectedScene;

  const SceneMenu({
    super.key,
    required this.selectedScene,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) => _handleMenuSelection(context, value),
      itemBuilder: (context) => _buildMenuItems(context),
      tooltip: '场景和活动',
      child: IconButton(
        icon: const Icon(Icons.apps, color: Colors.white),
        onPressed: null,
        tooltip: '场景和活动',
        hoverColor: Colors.white.withOpacity(0.2),
        splashColor: Colors.transparent,
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems(BuildContext context) {
    final items = <PopupMenuEntry<String>>[];

    // 添加场景切换选项
    for (final scene in allScenes) {
      items.add(
        PopupMenuItem<String>(
          value: 'scene_${scene.type.name}',
          child: Row(
            children: [
              Icon(
                scene.icon,
                color: scene.type == selectedScene
                    ? Theme.of(context).primaryColor
                    : Colors.black,
              ),
              const SizedBox(width: 10),
              Text(
                scene.name,
                style: TextStyle(
                  fontWeight: scene.type == selectedScene ? FontWeight.bold : null,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 添加分隔线
    items.add(const PopupMenuDivider());

    // 添加"查看活动"选项
    items.add(
      PopupMenuItem<String>(
        value: 'activity',
        child: Row(
          children: [
            const Icon(Icons.event_note, color: Colors.black),
            const SizedBox(width: 10),
            Text('查看${_getSceneName()}活动'),
          ],
        ),
      ),
    );

    return items;
  }

  void _handleMenuSelection(BuildContext context, String value) {
    if (value.startsWith('scene_')) {
      // 处理场景切换
      final sceneName = value.substring(6); // 移除 'scene_' 前缀
      final sceneType = SceneType.values.firstWhere((e) => e.name == sceneName);

      switch (sceneType) {
        case SceneType.interpretation:
          context.router.push(const InterpretRoute());
          break;
        case SceneType.presentation:
          context.router.push(const PresentationSceneRoute());
          break;
        case SceneType.meeting:
          context.router.push(const MeetingSceneRoute());
          break;
        case SceneType.education:
          context.router.push(const EducationSceneRoute());
          break;
      }
    } else if (value == 'activity') {
      // 处理查看活动
      context.router.push(
        ActivitySceneRoute(sceneType: selectedScene),
      );
    }
  }

  String _getSceneName() {
    switch (selectedScene) {
      case SceneType.interpretation:
        return '传译';
      case SceneType.presentation:
        return '演讲';
      case SceneType.meeting:
        return '会议';
      case SceneType.education:
        return '教育';
    }
  }
}

