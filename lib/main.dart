import 'package:flutter/material.dart';
import 'interpret/view/interpret_view.dart';
import 'user/view/user_menu.dart';
import 'scene/view/scene_menu.dart';
import 'scene/model/scene_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI面对面',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0078D4), // Windows 11 蓝色
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        popupMenuTheme: const PopupMenuThemeData(color: Colors.white),
      ),
      home: const RootPage(),
    );
  }
}

/// 根页面 - 包含Scaffold和AppBar
class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  // 设置场景菜单默认选项为演讲
  SceneType _selectedScene = SceneType.interpretation;

  // 处理场景选择的回调函数
  void _handleSceneSelected(SceneType type) {
    setState(() {
      _selectedScene = type;
    });
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
