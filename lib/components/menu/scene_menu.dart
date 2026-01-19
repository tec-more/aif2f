import 'package:flutter/material.dart';
import 'package:aif2f/scene/model/scene_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import 'package:aif2f/core/router/app_router.dart';

/// 场景选择菜单组件
///
/// 显示当前选中的场景图标，点击后弹出场景选择对话框
class SceneMenu extends ConsumerWidget {
  /// 构造函数
  const SceneMenu({
    super.key,
    required this.selectedScene,
    this.scenes = const [],
    this.iconSize = 24,
    this.iconColor,
    this.tooltip = '场景',
    this.onSceneSelected,
  });

  /// 当前选中的场景类型
  final SceneType selectedScene;

  /// 可选的场景列表，默认使用所有场景
  final List<Scene> scenes;

  /// 图标大小
  final double iconSize;

  /// 图标颜色
  final Color? iconColor;

  /// 提示文本
  final String tooltip;

  /// 场景选择回调，优先级高于默认导航
  final void Function(BuildContext context, SceneType sceneType)?
  onSceneSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取当前选中场景的信息
    final displayScenes = scenes ?? allScenes;

    // 获取当前选中场景的信息
    final currentScene = displayScenes.firstWhere(
      (scene) => scene.type == selectedScene,
      orElse: () => displayScenes.first,
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: Icon(
            currentScene.icon,
            color: iconColor ?? Theme.of(context).iconTheme.color,
            size: iconSize,
          ),
          onPressed: () => _showSceneGrid(context),
          tooltip: tooltip,
        ),
        // 右下角小箭头指示器（可配置）
        Positioned(
          bottom: 8,
          right: 8,
          child: Icon(Icons.circle_rounded, size: 10, color: Colors.purple),
        ),
      ],
    );
  }

  /// 显示场景选择网格
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
            itemCount: scenes.length,
            itemBuilder: (context, index) {
              final scene = scenes[index];
              final isSelected = scene.type == selectedScene;

              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _handleSceneSelection(context, scene.type);
                },
                child: _buildSceneItem(context, scene, isSelected),
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

  /// 构建场景选择项
  Widget _buildSceneItem(BuildContext context, Scene scene, bool isSelected) {
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? primaryColor.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? primaryColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            scene.icon,
            color: isSelected ? primaryColor : Colors.grey[700],
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            scene.name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? primaryColor : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  /// 处理场景选择
  void _handleSceneSelection(BuildContext context, SceneType sceneType) {
    // 如果提供了自定义回调，则优先使用
    if (onSceneSelected != null) {
      onSceneSelected!(context, sceneType);
      return;
    }

    // 默认导航逻辑
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
