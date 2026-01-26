# 自动滚动功能说明

## 功能概述

已成功集成自动滚动功能，确保新翻译的句子始终显示在可见区域。

---

## 实现效果

### ✅ 新句子到达时
- 自动平滑滚动到最新内容（300ms动画）
- 用户无需手动滚动
- 始终看到最新的翻译结果

### ✅ 用户手动滚动时
- 智能检测用户滚动意图
- 用户向上滚动查看旧内容时，暂停自动滚动
- 用户向下滚动到底部附近时，恢复自动滚动

### ✅ 性能优化
- 使用 `ScrollController` 精确控制
- 仅在有新句子时触发滚动
- 避免不必要的重绘

---

## 使用方式

### 自动激活
功能会在运行时自动生效，无需任何配置。

### 滚动行为

1. **默认状态（自动滚动开启）**：
   ```
   句子1 → Translation 1
   句子2 → Translation 2
   句子3 → Translation 3  ← 新内容，自动滚动到这里
   ```

2. **用户向上滚动（查看旧内容）**：
   ```
   句子1 → Translation 1  ← 用户滚动到这里
   句子2 → Translation 2
   句子3 → Translation 3
   句子4 → Translation 4  ← 新内容到达，但不自动滚动
   ```

3. **用户向下滚动到底部（恢复自动滚动）**：
   ```
   句子1 → Translation 1
   句子2 → Translation 2
   句子3 → Translation 3
   句子4 → Translation 4  ← 用户滚动到这里附近（100px内）
   句子5 → Translation 5  ← 新内容，恢复自动滚动
   ```

---

## 技术实现

### 核心文件

**[auto_scroll_translation_view.dart](lib/interpret/widgets/auto_scroll_translation_view.dart)**

```dart
class AutoScrollTranslationView extends StatefulWidget {
  final List<String> sourceSentences;
  final List<String> targetSentences;
  final double fontSize;
  // ...
}
```

### 关键逻辑

1. **检测新句子**：
   ```dart
   final currentCount = widget.sourceSentences.length + widget.targetSentences.length;
   final hasNewSentences = currentCount > _lastSentenceCount;
   ```

2. **自动滚动**：
   ```dart
   _scrollController.animateTo(
     _scrollController.position.maxScrollExtent,
     duration: const Duration(milliseconds: 300),
     curve: Curves.easeOut,
   );
   ```

3. **智能暂停/恢复**：
   ```dart
   if (userScrollsUp) {
     _isUserScrolling = true;  // 暂停自动滚动
   } else if (nearBottom) {
     _isUserScrolling = false;  // 恢复自动滚动
   }
   ```

---

## 配置选项

### 调整滚动速度

在 `auto_scroll_translation_view.dart` 中修改：

```dart
// 默认 300ms，可调整为：
duration: const Duration(milliseconds: 200),  // 更快
duration: const Duration(milliseconds: 500),  // 更慢
```

### 调整恢复阈值

默认距离底部 100px 时恢复自动滚动：

```dart
if (_scrollController.position.pixels >=
    _scrollController.position.maxScrollExtent - 100) {
  _isUserScrolling = false;
}
```

可调整为：
```dart
- 50   // 更敏感，接近底部就恢复
- 200  // 更宽松，需要更接近底部
```

---

## 替代方案

如果当前方案不满足需求，可以考虑：

### 方案A: 反向滚动（聊天风格）

```dart
ListView.builder(
  reverse: true,  // 新内容固定在底部
  // ...
)
```

### 方案B: 固定显示最新N条

```dart
final latestSentences = allSentences.takeLast(5).toList();
// 只显示最新5条
```

---

## 测试建议

1. **基本测试**：
   - 说话，观察是否自动滚动到新内容
   - 验证内容可见性

2. **交互测试**：
   - 手动向上滚动查看旧内容
   - 继续说话，验证不会自动滚动（尊重用户操作）
   - 手动滚动到底部，继续说话，验证恢复自动滚动

3. **性能测试**：
   - 长时间翻译，验证内存占用
   - 快速连续输入，验证滚动流畅度

---

## 故障排除

### 问题：不自动滚动

**检查**：
1. 确认有新句子到达（查看控制台日志）
2. 确认 `_scrollController.hasClients` 为 true
3. 确认 `!_isUserScrolling` 为 true

### 问题：滚动过于频繁

**解决**：
- 增加 `duration`（滚动速度）
- 调整恢复阈值（-100 → -200）

### 问题：用户手动滚动时被自动滚动打断

**解决**：
- 已通过 `_isUserScrolling` 标志解决
- 检查 ScrollNotification 监听是否正常工作

---

## 相关文件

- 📁 [auto_scroll_translation_view.dart](lib/interpret/widgets/auto_scroll_translation_view.dart) - 自动滚动组件
- 📁 [interpret_view.dart](lib/interpret/view/interpret_view.dart) - 集成点（第1048-1061行）
- 📁 [app_config.dart](lib/core/config/app_config.dart) - 分隔符配置

---

## 总结

✅ **已完成**：
- 新句子自动滚动到可见区域
- 智能检测用户滚动意图
- 平滑动画效果（300ms）
- 零配置，开箱即用

🎯 **用户体验**：
- 始终看到最新翻译
- 可随时查看历史内容
- 自动滚动不会打扰手动操作

📱 **适用场景**：
- 实时同传翻译
- 长时间会议记录
- 演讲字幕显示
