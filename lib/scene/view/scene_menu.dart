import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:aif2f/scene/model/scene_model.dart';
import 'package:aif2f/core/router/app_router.dart';

class SceneMenu extends StatelessWidget {
  final SceneType selectedScene;

  const SceneMenu({super.key, required this.selectedScene});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) => _handleMenuSelection(context, value),
      itemBuilder: (context) => _buildMenuItems(context),
      tooltip: '场景',
      child: IconButton(
        icon: const Icon(Icons.apps, color: Colors.white),
        onPressed: null,
        tooltip: '场景',
        hoverColor: Colors.white.withValues(alpha: 0.2),
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
                  fontWeight: scene.type == selectedScene
                      ? FontWeight.bold
                      : null,
                ),
              ),
            ],
          ),
        ),
      );
    }

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
        case SceneType.activity:
          context.router.push(const ActivitySceneRoute());
          break;
      }
    }
  }
}
