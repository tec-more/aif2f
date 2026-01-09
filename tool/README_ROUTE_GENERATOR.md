# 路由常量自动生成器使用说明

## 概述

这个工具可以自动扫描项目中的 `@RoutePage()` 注解，并生成 `AppRoutes` 常量类，避免手动维护路由配置。

## 工作原理

1. **扫描阶段**：扫描各个模块目录（`home/`, `interpret/`, `user/` 等）中的页面文件
2. **识别阶段**：查找带有 `@RoutePage()` 或 `@RoutePage(name: 'xxx')` 注解的类
3. **生成阶段**：自动生成 `AppRoutes` 类，包含所有路由的配置

## 使用方法

### 添加新路由页面

1. 在页面文件中添加 `@RoutePage()` 注解：

```dart
// lib/home/new_page.dart
import 'package:auto_route/auto_route.dart';

@RoutePage()
class NewPage extends StatelessWidget {
  const NewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('新页面')),
      body: const Center(child: Text('内容')),
    );
  }
}
```

2. 运行生成器：

```bash
dart tool/generate_routes_constants.dart
```

3. 重新生成路由代码：

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 生成器输出示例

运行生成器后，会看到类似输出：

```
🔍 正在扫描路由页面...

✅ 找到路由页面: HomePage -> HomeRoute
✅ 找到路由页面: InterpretView -> InterpretRoute
✅ 找到路由页面: AboutPage -> AboutRoute

📝 共找到 3 个路由页面

💾 已备份原文件到 app_router.dart.bak
✅ 已更新 app_router.dart 文件

🎨 正在格式化代码...
✅ 代码格式化完成

🎉 路由常量生成完成！
💡 提示: 运行以下命令重新生成路由代码:
   flutter pub run build_runner build --delete-conflicting-outputs
```

## 生成的代码结构

生成器会在 `lib/core/router/app_router.dart` 中生成如下代码：

```dart
import 'package:auto_route/auto_route.dart';
import 'package:aif2f/home/home_page.dart';
import 'package:aif2f/interpret/view/interpret_view.dart';
// ... 其他导入

part 'app_router.gr.dart';

/// 应用路由常量类
/// 集中管理所有路由配置，便于维护和扩展
/// ⚠️  注意: 此文件由代码生成器自动生成，请勿手动修改
/// 如需修改路由配置，请运行: dart tool/generate_routes_constants.dart
class AppRoutes {
  AppRoutes._();

  /// Home页面 (home 模块)
  static final home = AutoRoute(
    page: HomeRoute.page,
    path: '/',
    initial: true,
  );

  /// Interpret视图 (interpret 模块)
  static final interpret = AutoRoute(
    page: InterpretRoute.page,
    path: '/interpret',
  );

  /// 所有路由的集合
  static final List<AutoRoute> all = [
    home,
    interpret,
    // ... 其他路由
  ];
}

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => AppRoutes.all;
}
```

## 路由命名规则

### 变量名规则

- 移除 `Page` 或 `View` 后缀
- 首字母小写

示例：
- `HomePage` → `home`
- `InterpretView` → `interpret`
- `SettingsPage` → `settings`
- `UserProfilePage` → `userProfile`

### 路由名称规则

- 默认：移除 `Page` 或 `View` 后缀，添加 `Route` 后缀
- 自定义：使用 `@RoutePage(name: 'CustomRoute')` 指定

示例：
- `HomePage` → `HomeRoute`
- `InterpretView` → `InterpretRoute`
- 自定义：`@RoutePage(name: 'MyCustomRoute')` → `MyCustomRoute`

### 路由路径规则

- `HomePage` → `/` (根路径，标记为 initial)
- `InterpretView` → `/interpret`
- 其他页面 → `/模块名/页面名`

示例：
- `SettingsPage` (user 模块) → `/user/settings`
- `ProfilePage` (user 模块) → `/user/profile`

## 自定义路由

如果需要自定义路由名称，使用 `name` 参数：

```dart
@RoutePage(name: 'CustomNameRoute')
class MyPage extends StatelessWidget {
  // ...
}
```

## 目录结构支持

生成器支持多种目录结构：

```
lib/
├── home/
│   ├── home_page.dart         ✅ 支持
│   └── view/
│       └── page.dart          ✅ 支持
├── interpret/
│   └── view/
│       └── interpret_view.dart ✅ 支持
└── user/
    └── view/
        └── settings_page.dart  ✅ 支持
```

## 注意事项

1. **⚠️ 不要手动修改** `app_router.dart` 中的 `AppRoutes` 类
2. **每次添加新页面后** 都需要运行生成器
3. **备份文件**：每次运行会创建 `app_router.dart.bak` 备份
4. **代码格式化**：生成器会自动格式化生成的代码

## 故障排除

### 问题：找不到某个路由页面

**原因**：
- 页面不在支持的模块目录中
- 没有添加 `@RoutePage()` 注解

**解决**：
1. 确认页面在 `home/`, `interpret/`, `scene/`, `user/` 等模块目录中
2. 确认添加了 `@RoutePage()` 注解

### 问题：路由变量名不理想

**原因**：页面命名不符合预期

**解决**：
- 重命名页面类，遵循命名规则
- 或使用自定义路由名称：`@RoutePage(name: 'YourRoute')`

### 问题：路径不符合预期

**原因**：自动生成的路径规则不匹配

**解决**：
可以在生成后手动调整路径（但下次重新生成会被覆盖），或修改生成器源码中的 `_generateRoutePath` 函数。

## 高级定制

如需修改生成逻辑，编辑 `tool/generate_routes_constants.dart`：

- `_generateVariableName()`: 修改变量名生成规则
- `_generateRoutePath()`: 修改路由路径生成规则
- `_toRouteName()`: 修改路由名称生成规则

修改后运行：
```bash
dart tool/generate_routes_constants.dart
```
