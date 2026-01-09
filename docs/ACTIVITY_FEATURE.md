# 活动功能使用指南

## 概述

活动功能允许用户为不同的场景创建、管理和跟踪翻译活动。每个活动都包含标题、描述、创建时间和状态等信息。

## 功能特性

### 1. **活动管理**
- ✅ 创建新活动
- ✅ 查看活动列表
- ✅ 查看活动详情
- ✅ 编辑活动（待实现）
- ✅ 删除活动
- ✅ 活动状态管理

### 2. **场景关联**
每个活动都与特定场景相关联：
- 🌐 传译活动
- 📊 演讲活动
- 👥 会议活动
- 🎓 教育活动

### 3. **活动状态**
- 🟢 进行中 (Active)
- 🟠 已暂停 (Paused)
- 🔵 已完成 (Completed)
- ⚫ 已归档 (Archived)

## 数据模型

### Activity 类

```dart
class Activity {
  final String id;                  // 活动唯一标识
  final String title;               // 活动标题
  final String description;         // 活动描述
  final DateTime createdAt;         // 创建时间
  final ActivityStatus status;      // 活动状态
  final SceneType sceneType;        // 关联场景
}
```

### ActivityStatus 枚举

```dart
enum ActivityStatus {
  active,      // 进行中
  paused,      // 已暂停
  completed,   // 已完成
  archived,    // 已归档
}
```

### ActivityManager 类

活动管理器提供完整的 CRUD 操作：

```dart
class ActivityManager {
  List<Activity> get activities;                              // 获取所有活动
  List<Activity> getActivitiesByScene(SceneType sceneType);   // 按场景获取
  List<Activity> getActivitiesByStatus(ActivityStatus status); // 按状态获取
  void addActivity(Activity activity);                        // 添加活动
  void updateActivity(Activity activity);                     // 更新活动
  void deleteActivity(String id);                             // 删除活动
  Activity? getActivityById(String id);                       // 按ID获取
  void clear();                                                // 清空所有
}
```

## 页面结构

### 1. ActivityListPage - 活动列表页

**路径**: `ActivityListRoute(sceneType: SceneType.interpretation)`

**功能**:
- 显示指定场景的所有活动
- 点击活动卡片查看详情
- 删除活动（带撤销功能）
- 空状态提示

**组件**:
- `ActivityList` - 活动列表主体
- `ActivityCard` - 活动卡片
- `ActivityDetailSheet` - 活动详情底部弹窗

### 2. ActivityCreatePage - 创建活动页

**路径**: `ActivityCreateRoute(sceneType: SceneType.interpretation)`

**功能**:
- 创建新活动
- 表单验证
- 显示场景信息

**表单字段**:
- 活动标题（必填，2-50字符）
- 活动描述（必填，最多500字符）

### 3. ActivityFloatingButton - 活动快捷按钮

**类型**:
- `ActivityFloatingButton` - 扩展型按钮（带文字）
- `ActivityFloatingButtonSmall` - 紧凑型按钮（仅图标）

**使用**:
```dart
// 在场景页面中添加
ActivityFloatingButton(sceneType: SceneType.interpretation)
```

## 使用示例

### 在场景页面中集成活动按钮

```dart
import 'package:aif2f/activity/view/activity_fab.dart';

class InterpretView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('传译')),
      body: YourContent(),
      floatingActionButton: ActivityFloatingButton(
        sceneType: SceneType.interpretation,
      ),
    );
  }
}
```

### 导航到活动列表

```dart
import 'package:aif2f/core/router/app_router.dart';

// 方法1：使用路由
context.router.push(
  ActivityListRoute(sceneType: SceneType.interpretation),
);

// 方法2：使用快捷按钮
ActivityFloatingButton(sceneType: SceneType.interpretation)
```

### 创建和管理活动

```dart
import 'package:aif2f/activity/model/activity_model.dart';

// 创建活动管理器
final manager = ActivityManager();

// 创建新活动
final activity = Activity(
  id: DateTime.now().millisecondsSinceEpoch.toString(),
  title: '商务会议翻译',
  description: '为中美贸易会议提供实时翻译',
  createdAt: DateTime.now(),
  sceneType: SceneType.interpretation,
);

// 添加活动
manager.addActivity(activity);

// 获取特定场景的活动
final interpretationActivities = manager.getActivitiesByScene(
  SceneType.interpretation
);

// 更新活动状态
final updatedActivity = activity.copyWith(
  status: ActivityStatus.completed,
);
manager.updateActivity(updatedActivity);

// 删除活动
manager.deleteActivity(activity.id);
```

## 路由配置

所有活动相关的路由已自动生成并配置：

```dart
// app_router.dart
static final activityList = AutoRoute(
  page: ActivityListRoute.page,
  path: '/activity/activitylist',
);

static final activityCreate = AutoRoute(
  page: ActivityCreateRoute.page,
  path: '/activity/activitycreate',
);
```

## 路径模式

- 活动列表: `/activity/activitylist?sceneType=interpretation`
- 创建活动: `/activity/activitycreate?sceneType=interpretation`

## UI 设计

### 活动卡片
- 场景图标（圆形背景）
- 活动标题（加粗）
- 活动描述（最多2行）
- 创建时间（相对时间格式）
- 状态标签
- 删除按钮

### 颜色方案
- 传译: 🔵 蓝色 (Colors.blue)
- 演讲: 🟣 紫色 (Colors.purple)
- 会议: 🟢 绿色 (Colors.green)
- 教育: 🟠 橙色 (Colors.orange)

### 状态标签颜色
- 进行中: 🟢 绿色
- 已暂停: 🟠 橙色
- 已完成: 🔵 蓝色
- 已归档: ⚫ 灰色

## 待实现功能

### 短期
- [ ] 编辑活动功能
- [ ] 分享活动功能
- [ ] 本地存储集成（SharedPreferences/sqflite）
- [ ] 活动搜索功能
- [ ] 活动筛选功能

### 中期
- [ ] 活动统计数据
- [ ] 活动历史记录
- [ ] 活动模板功能
- [ ] 批量操作（删除、归档）

### 长期
- [ ] 云端同步
- [ ] 活动协作功能
- [ ] 活动导出（PDF、Excel）
- [ ] 活动提醒和通知

## 数据持久化

### 当前状态
- ⚠️ 数据仅存储在内存中
- ⚠️ 应用重启后数据丢失

### 推荐方案

**方案1: SharedPreferences（适合少量数据）**
```yaml
dependencies:
  shared_preferences: ^2.2.2
```

**方案2: sqflite（适合结构化数据）**
```yaml
dependencies:
  sqflite: ^2.3.0
  path_provider: ^2.1.1
```

**方案3: Hive（轻量级NoSQL）**
```yaml
dependencies:
  hive: ^2.2.3
  hive_flutter: ^1.1.0
```

### 实现示例（SharedPreferences）

```dart
class ActivityStorage {
  static const String _key = 'activities';

  // 保存活动列表
  Future<void> saveActivities(List<Activity> activities) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = activities.map((a) => a.toJson()).toList();
    await prefs.setString(_key, jsonEncode(jsonList));
  }

  // 加载活动列表
  Future<List<Activity>> loadActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) return [];

    final jsonList = jsonDecode(jsonString) as List;
    return jsonList
        .map((json) => Activity.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
```

## 测试建议

### 单元测试
```dart
test('ActivityManager should add activity', () {
  final manager = ActivityManager();
  final activity = testActivity;

  manager.addActivity(activity);

  expect(manager.activities, contains(activity));
});

test('ActivityManager should delete activity', () {
  final manager = ActivityManager();
  final activity = testActivity;
  manager.addActivity(activity);

  manager.deleteActivity(activity.id);

  expect(manager.activities, isEmpty);
});
```

### Widget 测试
```dart
testWidgets('ActivityListPage shows empty state', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ActivityListPage(sceneType: SceneType.interpretation),
    ),
  );

  expect(find.text('暂无传译活动'), findsOneWidget);
});
```

## 故障排除

### 问题：活动列表为空
**原因**: 数据未正确加载或存储
**解决**:
1. 检查 `ActivityManager` 是否正确初始化
2. 确认数据持久化已实现
3. 查看 `_loadActivities()` 方法

### 问题：路由跳转失败
**原因**: 路由未正确生成
**解决**:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 问题：场景类型不匹配
**原因**: 使用了错误的 `SceneType`
**解决**: 确保使用正确的枚举值
```dart
// ✅ 正确
SceneType.interpretation

// ❌ 错误
SceneType('interpretation')
```

## 相关文件

- [activity_model.dart](../lib/activity/model/activity_model.dart) - 数据模型
- [activity_list_page.dart](../lib/activity/view/activity_list_page.dart) - 活动列表页
- [activity_create_page.dart](../lib/activity/view/activity_create_page.dart) - 创建活动页
- [activity_fab.dart](../lib/activity/view/activity_fab.dart) - 快捷按钮

## 最佳实践

1. **使用 ActivityManager**: 始终通过管理器操作活动数据
2. **状态管理**: 考虑使用 Provider/Riverpod 管理活动状态
3. **错误处理**: 添加适当的错误处理和用户提示
4. **数据验证**: 创建和更新活动时进行数据验证
5. **性能优化**: 大量活动时使用虚拟列表（ListView.builder）
6. **用户体验**: 提供加载状态、错误状态和空状态

## 未来改进

- 🔔 活动提醒
- 📊 活动统计和图表
- 🎨 自定义活动主题
- 🏷️ 活动标签和分类
- 🔍 全文搜索
- 📤 导出和分享
- 🔄 活动版本历史
- 👥 多人协作
