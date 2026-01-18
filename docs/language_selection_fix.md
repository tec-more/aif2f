# 语言选择 Bug 修复记录

## 修复日期: 2025-01-13

---

## Bug: 语言选择时的竞态条件

### 问题描述

在语言选择对话框中，点击确认按钮时会依次调用 `setSourceLanguage()` 和 `setTargetLanguage()` 两个异步方法。这导致：

1. **发送两次 WebSocket 消息**：每次调用都会向服务器发送 `session.update` 消息
2. **竞态条件**：两次 WebSocket 调用可能产生不确定的顺序
3. **状态不一致**：在第一次调用完成后、第二次调用开始前，系统处于临时不一致状态
4. **性能浪费**：两次 WebSocket 通信的开销

### 位置

**文件**: [lib/interpret/view/interpret_view.dart](lib/interpret/view/interpret_view.dart#L1043-L1053)

### 原代码

```dart
onPressed: () async {
  // ❌ Bug: 依次调用两个异步方法
  await _viewModel.setSourceLanguage(tempSourceLanguage);
  await _viewModel.setTargetLanguage(tempTargetLanguage);

  outerSetState(() {
    _sourceLanguage = tempSourceLanguage;
    _targetLanguage = tempTargetLanguage;
  });
  Navigator.pop(context);
},
```

**ViewModel 中的原实现** ([interpret_view_model.dart:192-202](lib/interpret/viewmodel/interpret_view_model.dart#L192-L202)):

```dart
/// 设置源语言
void setSourceLanguage(String language) {
  config.sourceLanguage = language;

  // ❌ 每次都会发送 WebSocket 消息
  if (_isConnected) {
    final sourceCode = _languageCodeMap[language] ?? 'zh';
    final targetCode = _languageCodeMap[config.targetLanguage] ?? 'en';
    _translationService.updateLanguages(sourceCode, targetCode);
  }

  notifyListeners();
}

/// 设置目标语言
void setTargetLanguage(String language) {
  config.targetLanguage = language;

  // ❌ 每次都会发送 WebSocket 消息
  if (_isConnected) {
    final sourceCode = _languageCodeMap[config.sourceLanguage] ?? 'zh';
    final targetCode = _languageCodeMap[language] ?? 'en';
    _translationService.updateLanguages(sourceCode, targetCode);
  }

  notifyListeners();
}
```

### 问题分析

#### WebSocket 消息流程

```
User Action: 选择语言并点击确认
    ↓
Call setSourceLanguage("英语")
    ↓
WebSocket Message 1: session.update { source: "en", target: "中文" }
    ↓
Call setTargetLanguage("日语")
    ↓
WebSocket Message 2: session.update { source: "英语", target: "ja" }
    ↓
Final State: 英语 → 日语 ✅
```

#### 问题场景

**场景 1**: 用户从 "中文→英语" 切换到 "英语→日语"

1. `setSourceLanguage("英语")` → 发送 `session.update(source: "en", target: "en")`
   - ⚠️ 此时目标语言还是 "英语"，导致源语言和目标语言相同！
2. `setTargetLanguage("日语")` → 发送 `session.update(source: "en", target: "ja")`

**场景 2**: 网络延迟时的竞态条件

```
时间线:
T0: 调用 setSourceLanguage("英语")
T1: WebSocket 消息 1 发送
T2: 调用 setTargetLanguage("日语")
T3: WebSocket 消息 2 发送
T4: WebSocket 消息 2 到达服务器并处理 → source=en, target=ja ✅
T5: WebSocket 消息 1 到达服务器并处理 → source=en, target=en ❌ (覆盖了正确的状态)
```

### 修复方案

#### 1. 新增 `setLanguages()` 方法

在 ViewModel 中添加一个新方法，同时设置两种语言，只发送一次 WebSocket 消息：

**文件**: [lib/interpret/viewmodel/interpret_view_model.dart](lib/interpret/viewmodel/interpret_view_model.dart#L204-L217)

```dart
/// 同时设置源语言和目标语言（推荐使用）
Future<void> setLanguages(String sourceLanguage, String targetLanguage) async {
  // ✅ 先更新本地配置
  config.sourceLanguage = sourceLanguage;
  config.targetLanguage = targetLanguage;

  // ✅ 只发送一次 WebSocket 消息
  if (_isConnected) {
    final sourceCode = _languageCodeMap[sourceLanguage] ?? 'zh';
    final targetCode = _languageCodeMap[targetLanguage] ?? 'en';
    _translationService.updateLanguages(sourceCode, targetCode);
  }

  notifyListeners();
}
```

#### 2. 简化原有方法

将 `setSourceLanguage()` 和 `setTargetLanguage()` 改为只更新本地状态，不发送 WebSocket 消息：

```dart
/// 设置源语言（仅更新本地状态）
void setSourceLanguage(String language) {
  config.sourceLanguage = language;
  notifyListeners();
}

/// 设置目标语言（仅更新本地状态）
void setTargetLanguage(String language) {
  config.targetLanguage = language;
  notifyListeners();
}
```

#### 3. 更新 View 调用

**文件**: [lib/interpret/view/interpret_view.dart](lib/interpret/view/interpret_view.dart#L1043-L1055)

```dart
onPressed: () async {
  // ✅ 使用新方法一次性设置两种语言，避免发送两次WebSocket消息
  await _viewModel.setLanguages(
    tempSourceLanguage,
    tempTargetLanguage,
  );

  outerSetState(() {
    _sourceLanguage = tempSourceLanguage;
    _targetLanguage = tempTargetLanguage;
  });
  Navigator.pop(context);
},
```

### 修复后的流程

```
User Action: 选择语言并点击确认
    ↓
Call setLanguages("英语", "日语")
    ↓
Update local config: source = "英语", target = "日语"
    ↓
WebSocket Message (仅一次): session.update { source: "en", target: "ja" }
    ↓
Final State: 英语 → 日语 ✅
```

### 优势

1. ✅ **原子性**: 语言配置作为一个整体更新，不会出现中间状态
2. ✅ **性能**: 只发送一次 WebSocket 消息，减少网络开销
3. ✅ **一致性**: 避免竞态条件，确保源语言和目标语言始终匹配
4. ✅ **可维护性**: 清晰的 API 设计，明确表达"同时设置两种语言"的意图

### 对比分析

| 方面 | 修复前 | 修复后 |
|------|--------|--------|
| WebSocket 消息数 | 2 次 | 1 次 ⬇️ 50% |
| 中间状态数量 | 1 个（不一致） | 0 个 ✅ |
| 竞态条件风险 | 高 ❌ | 无 ✅ |
| 代码复杂度 | 分散 | 集中 ✅ |
| API 语义 | 不明确 | 清晰 ✅ |

### 测试建议

#### 1. 单元测试

```dart
test('setLanguages should update both languages atomically', () async {
  final viewModel = InterpretViewModel();
  await viewModel.initialize();

  // 模拟从"中文→英语"切换到"英语→日语"
  await viewModel.setLanguages('英语', '日语');

  expect(viewModel.config.sourceLanguage, '英语');
  expect(viewModel.config.targetLanguage, '日语');

  // 验证只发送了一次 WebSocket 消息
  // (需要 mock TranslationService 并验证调用次数)
});
```

#### 2. 集成测试

```dart
testWidgets('language selection should work without race conditions', (tester) async {
  await tester.pumpWidget(MyApp());
  await tester.tap(find.text('选择语言'));

  // 选择源语言：英语
  await tester.tap(find.text('英语').first);
  await tester.pump();

  // 选择目标语言：日语
  await tester.tap(find.text('日语').last);
  await tester.pump();

  // 点击确认
  await tester.tap(find.text('确认'));
  await tester.pumpAndSettle();

  // 验证最终状态
  expect(find.text('英语 → 日语'), findsOneWidget);
});
```

#### 3. 手动测试步骤

1. ✅ 打开应用，进入同传页面
2. ✅ 点击语言选择按钮
3. ✅ 选择源语言：英语
4. ✅ 选择目标语言：日语
5. ✅ 点击确认按钮
6. ✅ 检查语言显示：应显示 "英语 → 日语"
7. ✅ 开始录音，验证翻译方向正确

### 相关代码位置

| 文件 | 修改内容 | 行号 |
|------|----------|------|
| [interpret_view_model.dart](lib/interpret/viewmodel/interpret_view_model.dart#L204-L217) | 新增 `setLanguages()` 方法 | 204-217 |
| [interpret_view_model.dart](lib/interpret/viewmodel/interpret_view_model.dart#L192-L196) | 简化 `setSourceLanguage()` | 192-196 |
| [interpret_view_model.dart](lib/interpret/viewmodel/interpret_view_model.dart#L198-L202) | 简化 `setTargetLanguage()` | 198-202 |
| [interpret_view.dart](lib/interpret/view/interpret_view.dart#L1043-L1055) | 更新调用代码 | 1043-1055 |

### 其他需要检查的地方

#### `swapLanguages()` 方法

✅ **无需修改** - 该方法已经正确实现：

```dart
void swapLanguages() async {
  // 1. 交换本地配置
  final temp = config.sourceLanguage;
  config.sourceLanguage = config.targetLanguage;
  config.targetLanguage = temp;

  // 2. 一次性发送 WebSocket 消息
  if (_isConnected) {
    final sourceCode = _languageCodeMap[config.sourceLanguage] ?? 'zh';
    final targetCode = _languageCodeMap[config.targetLanguage] ?? 'en';
    _translationService.updateLanguages(sourceCode, targetCode);
  }

  // 3. 交换文本并通知
  // ...
}
```

### 总结

此 Bug 是典型的**状态更新原子性问题**：

- ❌ **原问题**: 将一个逻辑操作（设置两种语言）拆分成两个独立的异步调用
- ✅ **解决方案**: 提供一个原子操作方法，确保状态一致性
- 📊 **影响**: 减少了 50% 的 WebSocket 通信，消除了竞态条件风险
- 🎯 **最佳实践**: 当多个状态更新需要保持一致性时，应该提供原子操作方法

---

## 类似问题检查清单

在项目中检查是否存在类似的多状态更新问题：

- [ ] 音频参数设置（采样率、通道数、编码格式）
- [ ] 翻译配置更新（语言、模型、温度参数）
- [ ] UI 主题设置（颜色、字体、尺寸）
- [ ] 用户配置更新（用户名、头像、偏好设置）

如果发现类似模式，应该考虑提供原子操作方法。
