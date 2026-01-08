import 'package:flutter/material.dart';
import '../model/scene_model.dart';

class SceneMenu extends StatelessWidget {
  final SceneType selectedScene;
  final Function(SceneType) onSceneSelected;

  const SceneMenu({
    Key? key,
    required this.selectedScene,
    required this.onSceneSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SceneType>(
      onSelected: onSceneSelected,
      itemBuilder: (context) {
        return allScenes.map((scene) {
          return PopupMenuItem<SceneType>(
            value: scene.type,
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
          );
        }).toList();
      },
      // 使用child确保图标在悬停时仍然可见
      child: IconButton(
        icon: const Icon(Icons.apps, color: Colors.white),
        onPressed: null, // PopupMenuButton会处理点击事件
        tooltip: '切换场景',
        hoverColor: Colors.white.withOpacity(0.2), // 设置半透明的悬停背景
        splashColor: Colors.transparent, // 移除点击水波纹效果
      ),
      tooltip: '切换场景',
    );
  }
}
