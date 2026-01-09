import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:aif2f/scene/model/scene_model.dart';
import 'package:aif2f/core/router/app_router.dart';

class SceneMenu extends StatelessWidget {
  final SceneType selectedScene;

  const SceneMenu({super.key, required this.selectedScene});

  @override
  Widget build(BuildContext context) {
    // 获取当前选中场景的信息
    final currentScene = allScenes.firstWhere(
      (scene) => scene.type == selectedScene,
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: Icon(currentScene.icon, color: Colors.white),
          onPressed: () => _showSceneGrid(context),
          tooltip: '场景',
        ),
        // 右下角小箭头指示器
        // Positioned(
        //   bottom: 8,
        //   right: 8,
        //   child: Icon(Icons.circle_rounded, size: 10, color: Colors.purple),
        // ),
      ],
    );
  }

  void _showSceneGrid(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择场景'),
        content: SizedBox(
          width: 300,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemCount: allScenes.length,
            itemBuilder: (context, index) {
              final scene = allScenes[index];
              final isSelected = scene.type == selectedScene;

              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _handleSceneSelection(context, scene.type);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        scene.icon,
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.grey[700],
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        scene.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _handleSceneSelection(BuildContext context, SceneType sceneType) {
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
      case SceneType.interview:
        context.router.push(const InterviewSceneRoute());
        break;
    }
  }
}
