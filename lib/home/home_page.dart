import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:aif2f/interpret/view/interpret_view.dart';
import 'package:aif2f/scene/model/scene_model.dart';
import 'package:aif2f/scene/view/scene_menu.dart';
import 'package:aif2f/user/view/user_menu.dart';

/// 主页 - 包含Scaffold和AppBar
@RoutePage()
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 设置场景菜单默认选项为演讲
  SceneType _selectedScene = SceneType.interpretation;

  // 处理场景选择的回调函数
  void _handleSceneSelected(SceneType type) {
    setState(() {
      _selectedScene = type;
    });

    // 根据场景切换路由
    // 注意：路由将在代码生成后可用
    // switch (type) {
    //   case SceneType.interpretation:
    //     context.router.navigate(const InterpretRoute());
    //     break;
    //   case SceneType.presentation:
    //     // 可以在这里添加其他场景的路由
    //     break;
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI面对面'),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // 场景菜单按钮（用户菜单左边）
          SceneMenu(
            selectedScene: _selectedScene,
            onSceneSelected: _handleSceneSelected,
          ),
          // 用户菜单按钮，放置在右上角
          const UserMenu(),
        ],
      ),
      body: const InterpretView(),
    );
  }
}
