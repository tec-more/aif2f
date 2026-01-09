# 菜单路由使用指南

## 概述

本项目实现了两种菜单的路由导航：
1. **场景菜单** (SceneMenu) - 切换不同的功能场景
2. **用户菜单** (UserMenu) - 用户相关功能

## 场景菜单路由

### 可用场景

| 场景类型 | 路由 | 页面 | 图标 |
|---------|------|------|------|
| 传译 | `InterpretRoute` | InterpretView | Icons.translate |
| 演讲 | `PresentationSceneRoute` | PresentationScenePage | Icons.present_to_all |
| 会议 | `MeetingSceneRoute` | MeetingScenePage | Icons.meeting_room |
| 教育 | `EducationSceneRoute` | EducationScenePage | Icons.school |

### 路由路径

- `/interpret` - 传译场景（主页默认显示）
- `/scene/presentationscene` - 演讲场景
- `/scene/meetingscene` - 会议场景
- `/scene/educationscene` - 教育场景

### 使用示例

```dart
// 在代码中导航到特定场景
context.router.push(const InterpretRoute());
context.router.push(const PresentationSceneRoute());
context.router.push(const MeetingSceneRoute());
context.router.push(const EducationSceneRoute());
```

### 场景菜单实现

场景菜单位于应用 AppBar 左侧，点击后会显示所有可用场景。选择场景后会自动导航到对应页面。

**文件位置**: [lib/scene/view/scene_menu.dart](../lib/scene/view/scene_menu.dart)

```dart
PopupMenuButton<SceneType>(
  onSelected: (sceneType) {
    onSceneSelected(sceneType);  // 更新选中状态

    // 导航到对应路由
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
  },
  // ...
)
```

## 用户菜单路由

### 可用选项

| 选项 | 路由 | 页面 | 图标 |
|-----|------|------|------|
| 个人信息 | `ProfileRoute` | ProfilePage | Icons.person_outline |
| 设置 | `SettingsRoute` | SettingsPage | Icons.settings_outlined |
| 关于 | `AboutRoute` | AboutPage | Icons.info_outline |
| 退出登录 | - | - | Icons.logout |

### 路由路径

- `/user/profile` - 个人信息页面
- `/user/settings` - 设置页面
- `/user/about` - 关于页面

### 使用示例

```dart
// 在代码中导航到用户相关页面
context.router.push(const ProfileRoute());
context.router.push(const SettingsRoute());
context.router.push(const AboutRoute());
```

### 用户菜单实现

用户菜单位于应用 AppBar 右侧，点击后会显示用户相关功能选项。

**文件位置**: [lib/user/view/user_menu.dart](../lib/user/view/user_menu.dart)

```dart
PopupMenuButton<String>(
  onSelected: (value) {
    switch (value) {
      case 'profile':
        context.router.push(ProfileRoute());
        break;
      case 'settings':
        context.router.push(SettingsRoute());
        break;
      case 'about':
        context.router.push(AboutRoute());
        break;
      case 'logout':
        _showLogoutConfirmation(context);
        break;
    }
  },
  // ...
)
```

## 添加新的场景路由

### 步骤 1: 创建场景页面

在 `lib/scene/view/` 目录下创建新的页面文件：

```dart
// lib/scene/view/new_scene_page.dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

@RoutePage()
class NewScenePage extends StatelessWidget {
  const NewScenePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('新场景'),
      ),
      body: const Center(
        child: Text('新场景页面'),
      ),
    );
  }
}
```

### 步骤 2: 更新场景模型

在 `lib/scene/model/scene_model.dart` 中添加新场景类型：

```dart
enum SceneType {
  interpretation,
  presentation,
  meeting,
  education,
  newScene,  // 添加新场景
}

List<Scene> allScenes = [
  Scene(type: SceneType.interpretation, name: '传译', icon: Icons.translate),
  Scene(type: SceneType.presentation, name: '演讲', icon: Icons.present_to_all),
  Scene(type: SceneType.meeting, name: '会议', icon: Icons.meeting_room),
  Scene(type: SceneType.education, name: '教育', icon: Icons.school),
  Scene(type: SceneType.newScene, name: '新场景', icon: Icons.new_releases),  // 添加新场景
];
```

### 步骤 3: 运行路由生成器

```bash
# 生成路由常量
dart tool/generate_routes_constants.dart

# 重新生成路由代码
flutter pub run build_runner build --delete-conflicting-outputs
```

### 步骤 4: 更新场景菜单

在 `lib/scene/view/scene_menu.dart` 中添加新场景的路由导航：

```dart
onSelected: (sceneType) {
  onSceneSelected(sceneType);

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
    case SceneType.newScene:  // 添加新场景
      context.router.push(const NewSceneRoute());
      break;
  }
},
```

## 添加新的用户菜单选项

### 步骤 1: 创建页面

在 `lib/user/view/` 目录下创建新页面：

```dart
// lib/user/view/new_page.dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

@RoutePage()
class NewPage extends StatelessWidget {
  const NewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('新页面'),
      ),
      body: const Center(
        child: Text('新页面'),
      ),
    );
  }
}
```

### 步骤 2: 运行路由生成器

```bash
dart tool/generate_routes_constants.dart
flutter pub run build_runner build --delete-conflicting-outputs
```

### 步骤 3: 更新用户菜单

在 `lib/user/view/user_menu.dart` 中添加新选项：

```dart
PopupMenuButton<String>(
  onSelected: (value) {
    switch (value) {
      case 'profile':
        context.router.push(ProfileRoute());
        break;
      case 'settings':
        context.router.push(SettingsRoute());
        break;
      case 'about':
        context.router.push(AboutRoute());
        break;
      case 'newPage':  // 添加新选项
        context.router.push(NewRoute());
        break;
      case 'logout':
        _showLogoutConfirmation(context);
        break;
    }
  },
  itemBuilder: (context) {
    return [
      // ... 现有菜单项
      PopupMenuItem(
        value: 'newPage',
        child: Row(
          children: const [
            Icon(Icons.new_releases, color: Colors.black),
            SizedBox(width: 10),
            Text('新页面'),
          ],
        ),
      ),
      // ...
    ];
  },
)
```

## 路由导航方法

### push - 导航到新页面

```dart
// 导航到新页面（保留当前页面在栈中）
context.router.push(const SettingsRoute());
```

### pop - 返回上一页

```dart
// 返回上一页
context.router.pop();
```

### replace - 替换当前页面

```dart
// 替换当前页面
context.router.replace(const SettingsRoute());
```

### navigate - 清空栈并导航

```dart
// 清空路由栈并导航到新页面
context.router.navigate(const SettingsRoute());
```

## 路由传参

### 定义带参数的路由

```dart
@RoutePage()
class DetailPage extends StatelessWidget {
  final String id;
  const DetailPage({super.key, @PathParam('id') required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Text('详情 ID: $id'),
    );
  }
}
```

### 导航时传递参数

```dart
// 传递路径参数
context.router.push(DetailRoute(id: '123'));

// 传递查询参数
context.router.push(const DetailRoute(id: '123').appendQueryParams({'tab': 'info'}));
```

## 最佳实践

1. **使用路由常量**：始终使用生成的路由类（如 `SettingsRoute()`），而不是硬编码路径字符串
2. **类型安全**：路由参数在编译时检查，避免运行时错误
3. **代码生成**：添加新页面后记得运行路由生成器
4. **路由守卫**：对于需要登录的页面，使用路由守卫进行权限控制
5. **深链接**：支持深链接，使应用可以通过 URL 打开特定页面

## 故障排除

### 问题：路由跳转无效

**原因**：
- 路由未正确生成
- 缺少 `@RoutePage()` 注解
- build_runner 未运行

**解决**：
```bash
# 清理并重新生成
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### 问题：找不到路由类

**原因**：导入路径错误或未生成路由代码

**解决**：
1. 确保导入了正确的路由文件：`import 'package:aif2f/core/router/app_router.dart';`
2. 检查 `app_router.gr.dart` 是否存在且包含对应的路由类
3. 重新运行 build_runner

### 问题：页面显示空白

**原因**：路由配置错误或页面未正确注册

**解决**：
1. 检查 `AppRoutes.all` 中是否包含该路由
2. 确认路由路径正确
3. 查看控制台是否有错误信息

## 相关文件

- [app_router.dart](../lib/core/router/app_router.dart) - 路由配置
- [scene_menu.dart](../lib/scene/view/scene_menu.dart) - 场景菜单
- [user_menu.dart](../lib/user/view/user_menu.dart) - 用户菜单
- [generate_routes_constants.dart](../tool/generate_routes_constants.dart) - 路由生成器
- [README_ROUTE_GENERATOR.md](../tool/README_ROUTE_GENERATOR.md) - 路由生成器文档
