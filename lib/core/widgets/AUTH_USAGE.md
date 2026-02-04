# 权限认证使用说明

## 概述

项目中添加了基于登录状态的权限认证功能，用于保护需要用户登录才能访问的页面。

## 组件说明

### AuthRequired

最基本的权限检查组件，未登录用户会自动跳转到登录页面。

**使用方式：**

```dart
import 'package:aif2f/core/widgets/auth_required.dart';

@override
Widget build(BuildContext context) {
  return AuthRequired(
    child: Scaffold(
      appBar: AppBar(title: Text('需要登录的页面')),
      body: yourPageContent,
    ),
  );
}
```

### AuthRequiredWithLoader

带有自定义加载页面的权限检查组件。

**使用方式：**

```dart
import 'package:aif2f/core/widgets/auth_required.dart';

@override
Widget build(BuildContext context) {
  return AuthRequiredWithLoader(
    loadingWidget: Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在跳转到登录页面...'),
          ],
        ),
      ),
    ),
    child: Scaffold(
      appBar: AppBar(title: Text('需要登录的页面')),
      body: yourPageContent,
    ),
  );
}
```

## 已添加权限检查的页面

- ✅ 充值页面 (RechargePage)

## 需要添加权限检查的页面

以下页面建议添加权限检查：

1. **个人中心** (ProfilePage)
2. **设置页面** (SettingsPage)
3. **关于页面** (AboutPage)

## 如何为页面添加权限检查

### 步骤 1: 导入组件

在需要保护的页面文件顶部添加导入：

```dart
import 'package:aif2f/core/widgets/auth_required.dart';
```

### 步骤 2: 包裹 build 方法的返回值

将 `build` 方法的返回值用 `AuthRequired` 包裹：

**修改前：**
```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text('我的页面')),
    body: yourContent,
  );
}
```

**修改后：**
```dart
@override
Widget build(BuildContext context) {
  return AuthRequired(
    child: Scaffold(
      appBar: AppBar(title: Text('我的页面')),
      body: yourContent,
    ),
  );
}
```

## 工作原理

1. **已登录用户**：直接显示页面内容
2. **未登录用户**：
   - 自动跳转到登录页面
   - 显示加载指示器
   - 用户登录成功后可以返回原页面

## 注意事项

1. **不要在登录页面使用**：登录页面本身不需要权限检查，否则会造成无限循环
2. **公开页面不需要**：首页、帮助页面等公开访问的页面不需要权限检查
3. **Provider 访问**：组件内部使用 `authProvider` 检查用户状态，无需手动传递

## 示例：完整页面代码

```dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aif2f/core/widgets/auth_required.dart';

@RoutePage()
class MyProtectedPage extends ConsumerWidget {
  const MyProtectedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuthRequired(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('需要登录的页面'),
        ),
        body: Center(
          child: Text('只有登录用户才能看到这个页面'),
        ),
      ),
    );
  }
}
```
