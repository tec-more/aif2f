# 活动功能集成示例

## 快速开始

### 步骤1：在场景页面中导入活动按钮

```dart
import 'package:aif2f/activity/view/activity_fab.dart';
import 'package:aif2f/activity/model/activity_model.dart';
```

### 步骤2：添加浮动按钮到场景页面

```dart
class InterpretView extends StatelessWidget {
  const InterpretView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('传译'),
      ),
      body: const YourTranslationContent(),
      floatingActionButton: ActivityFloatingButtonSmall(
        sceneType: SceneType.interpretation,
      ),
    );
  }
}
```

### 步骤3：运行应用

现在用户可以点击浮动按钮访问该场景的活动列表！

## 完整示例

### 传译场景页面集成

```dart
import 'package:flutter/material.dart';
import 'package:aif2f/activity/model/activity_model.dart';
import 'package:aif2f/activity/view/activity_fab.dart';

class InterpretView extends StatelessWidget {
  const InterpretView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('实时传译'),
        actions: [
          // 其他操作按钮
          IconButton(icon: Icon(Icons.history), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // 翻译控制区域
          TranslationControlPanel(),
          // 翻译结果显示区域
          TranslationResultPanel(),
        ],
      ),
      floatingActionButton: ActivityFloatingButtonSmall(
        sceneType: SceneType.interpretation,
      ),
    );
  }
}
```

### 使用扩展型浮动按钮

如果需要更明显的按钮，可以使用扩展型：

```dart
floatingActionButton: ActivityFloatingButton(
  sceneType: SceneType.interpretation,
),
```

这将显示一个带有"活动"文字标签的按钮。

## 自定义场景的活动页面

### 为不同场景创建专属活动列表

```dart
// 传译活动
context.router.push(
  ActivityListRoute(sceneType: SceneType.interpretation),
);

// 演讲活动
context.router.push(
  ActivityListRoute(sceneType: SceneType.presentation),
);

// 会议活动
context.router.push(
  ActivityListRoute(sceneType: SceneType.meeting),
);

// 教育活动
context.router.push(
  ActivityListRoute(sceneType: SceneType.education),
);
```

### 创建新活动

```dart
// 导航到创建页面
context.router.push(
  ActivityCreateRoute(sceneType: SceneType.interpretation),
);
```

## 与现有代码集成

### 场景页面模板

```dart
import 'package:flutter/material.dart';
import 'package:aif2f/activity/model/activity_model.dart';
import 'package:aif2f/activity/view/activity_fab.dart';
import 'package:aif2f/core/router/app_router.dart';

class YourScenePage extends StatefulWidget {
  const YourScenePage({super.key});

  @override
  State<YourScenePage> createState() => _YourScenePageState();
}

class _YourScenePageState extends State<YourScenePage> {
  // 你的状态管理
  SceneType currentScene = SceneType.interpretation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(getSceneTitle(currentScene)),
        actions: [
          // 活动列表按钮（可选：除了FAB外，还可以在AppBar中添加）
          IconButton(
            icon: const Icon(Icons.event_note),
            onPressed: () {
              context.router.push(
                ActivityListRoute(sceneType: currentScene),
              );
            },
            tooltip: '活动列表',
          ),
        ],
      ),
      body: YourSceneContent(),
      floatingActionButton: ActivityFloatingButtonSmall(
        sceneType: currentScene,
      ),
    );
  }

  String getSceneTitle(SceneType scene) {
    switch (scene) {
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
```

## 高级用法

### 自定义活动按钮位置

如果不使用浮动按钮，可以在任意位置添加：

```dart
// 在页面底部添加按钮
Padding(
  padding: const EdgeInsets.all(16.0),
  child: ElevatedButton.icon(
    onPressed: () {
      context.router.push(
        ActivityListRoute(sceneType: SceneType.interpretation),
      );
    },
    icon: const Icon(Icons.event_note),
    label: const Text('查看活动'),
    style: ElevatedButton.styleFrom(
      minimumSize: const Size.fromHeight(50),
    ),
  ),
)
```

### 根据活动数量显示徽章

```dart
class ActivityButtonWithBadge extends StatelessWidget {
  final SceneType sceneType;

  const ActivityButtonWithBadge({super.key, required this.sceneType});

  @override
  Widget build(BuildContext context) {
    final manager = ActivityManager();
    final activityCount = manager.getActivitiesByScene(sceneType).length;

    return Stack(
      children: [
        ActivityFloatingButtonSmall(sceneType: sceneType),
        if (activityCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                activityCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
```

### 带状态管理的活动按钮

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ActivityButtonWithState extends StatelessWidget {
  final SceneType sceneType;

  const ActivityButtonWithState({super.key, required this.sceneType});

  @override
  Widget build(BuildContext context) {
    final activityManager = context.watch<ActivityManager>();
    final activities = activityManager.getActivitiesByScene(sceneType);

    return FloatingActionButton.extended(
      onPressed: () {
        context.router.push(
          ActivityListRoute(sceneType: sceneType),
        );
      },
      icon: Badge.count(
        count: activities.length,
        child: const Icon(Icons.event_note),
      ),
      label: Text('活动 (${activities.length})'),
    );
  }
}
```

## 常见使用场景

### 场景1：在翻译会话开始时创建活动

```dart
void startTranslationSession(BuildContext context) async {
  // 1. 导航到创建活动页面
  final result = await context.router.push<bool>(
    ActivityCreateRoute(sceneType: SceneType.interpretation),
  );

  // 2. 如果活动创建成功，开始翻译
  if (result == true) {
    startRecording();
  }
}
```

### 场景2：在会话结束时更新活动状态

```dart
void endTranslationSession(BuildContext context, String activityId) {
  final manager = context.read<ActivityManager>();
  final activity = manager.getActivityById(activityId);

  if (activity != null) {
    final updated = activity.copyWith(
      status: ActivityStatus.completed,
    );
    manager.updateActivity(updated);
  }
}
```

### 场景3：在AppBar中添加活动菜单

```dart
AppBar(
  title: const Text('传译'),
  actions: [
    // 活动列表
    IconButton(
      icon: const Icon(Icons.event_note),
      onPressed: () => context.router.push(
        ActivityListRoute(sceneType: SceneType.interpretation),
      ),
      tooltip: '活动列表',
    ),
    // 创建活动
    IconButton(
      icon: const Icon(Icons.add_circle_outline),
      onPressed: () => context.router.push(
        ActivityCreateRoute(sceneType: SceneType.interpretation),
      ),
      tooltip: '创建活动',
    ),
    const UserMenu(),
  ],
)
```

## 测试集成

### 验证按钮是否正常工作

```dart
testWidgets('Activity button navigates to list', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        floatingActionButton: ActivityFloatingButtonSmall(
          sceneType: SceneType.interpretation,
        ),
      ),
    ),
  );

  // 点击按钮
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();

  // 验证导航
  expect(find.text('传译活动'), findsOneWidget);
});
```

## 故障排除

### 问题：按钮点击无反应
**检查**:
1. 路由是否正确生成
2. ActivityFloatingButton 是否正确导入
3. context 是否可用

**解决**:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 问题：活动列表为空
**原因**: 内存中的数据在页面重建时丢失

**解决**: 实现数据持久化（参考 [ACTIVITY_FEATURE.md](./ACTIVITY_FEATURE.md)）

## 最佳实践

1. **始终指定 sceneType**: 确保活动与正确场景关联
2. **使用类型安全**: 使用生成的路由类而不是字符串路径
3. **提供反馈**: 操作成功/失败时显示 SnackBar
4. **状态管理**: 考虑使用 Provider/Riverpod 管理活动状态
5. **数据持久化**: 实现本地存储以保存活动数据

## 相关文档

- [活动功能文档](./ACTIVITY_FEATURE.md)
- [菜单路由指南](./MENU_ROUTING_GUIDE.md)
- [路由生成器文档](../tool/README_ROUTE_GENERATOR.md)
