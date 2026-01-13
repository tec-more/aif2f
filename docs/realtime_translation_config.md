# InterpretView 实时翻译配置更新

## 📝 更新内容

**文件:** [lib/interpret/view/interpret_view.dart](../lib/interpret/view/interpret_view.dart)

### 修改内容

1. **添加配置导入**
   ```dart
   import 'package:aif2f/core/config/app_config.dart';
   ```

2. **在 initState 中配置智谱AI**
   ```dart
   @override
   void initState() {
     super.initState();
     _viewModel = InterpretViewModel();

     // 配置智谱AI服务
     _viewModel.setZhipuConfig(
       apiKey: AppConfig.zhipuApiKey,
       baseUrl: AppConfig.zhipuBaseUrl,
     );

     _viewModel.addListener(_onViewModelChanged);
   }
   ```

---

## ✅ 功能验证

### 实时翻译功能现在使用智谱AI

当用户点击"实时翻译"按钮时：

```
用户点击"实时翻译"
    ↓
InterpretViewModel.startRealTimeTranslation()
    ↓
RealTimeTranslationService.startRealTimeTranslation()
    ↓
ZhipuTranslationService.translateText()
    ↓
智谱AI API (https://open.bigmodel.cn/api/paas/v4)
    ↓
返回翻译结果并更新UI
```

### API端点

- **基础URL**: `https://open.bigmodel.cn/api/paas/v4`
- **翻译端点**: `/chat/completions`
- **模型**: `glm-4-flash`
- **认证**: JWT Token (从API Key生成)

---

## 🔄 数据流程

### 录音翻译流程

```dart
// 1. 用户点击"录音"按钮
ElevatedButton(
  onPressed: () {
    if (isRecording) {
      _viewModel.stopRecordingAndTranslate(); // 停止录音
    } else {
      _viewModel.startRecordingAndTranslate(); // 开始录音
    }
  },
  child: Text(isRecording ? '停止' : '录音'),
)

// 2. ViewModel 处理录音和翻译
await _viewModel.startRecordingAndTranslate();
// ... 用户说话 ...
await _viewModel.stopRecordingAndTranslate();

// 3. 结果通过监听器自动更新UI
void _onViewModelChanged() {
  setState(() {
    if (_viewModel.currentTranslation != null) {
      _sourceController.text = _viewModel.currentTranslation!.sourceText;
      _targetController.text = _viewModel.currentTranslation!.targetText;
    }
  });
}
```

### 实时翻译流程

```dart
// 1. 用户点击"实时翻译"按钮
ElevatedButton.icon(
  onPressed: () {
    if (isRealTimeTranslating) {
      _viewModel.stopRealTimeTranslation();
    } else {
      _viewModel.startRealTimeTranslation();
    }
  },
  icon: Icon(isRealTimeTranslating ? Icons.stop : Icons.wifi_tethering),
  label: Text(isRealTimeTranslating ? '停止' : '实时翻译'),
)

// 2. 持续录音和翻译（每3秒处理一次）
// 3. 翻译结果通过流实时更新
```

---

## 📊 状态管理

### UI状态指示

页面显示三种状态：

1. **空闲状态** (无指示器)
   - 没有录音或翻译

2. **录音状态** (红色指示器)
   ```dart
   if (_viewModel.isRecording)
     Container(
       decoration: BoxDecoration(
         color: Colors.red.withValues(alpha: 0.1),
         border: Border.all(color: Colors.red),
       ),
       child: Row(
         children: [
           Container(红色圆点),
           Text('正在录音...'),
         ],
       ),
     )
   ```

3. **处理状态** (蓝色指示器)
   ```dart
   else if (_viewModel.isProcessing)
     Container(
       child: Row(
         children: [
           CircularProgressIndicator(),
           Text(_viewModel.statusMessage),
         ],
       ),
     )
   ```

---

## 🎯 配置说明

### AppConfig 配置

**位置:** [lib/core/config/app_config.dart](../lib/core/config/app_config.dart)

```dart
class AppConfig {
  /// 智谱AI配置
  static const String zhipuApiKey = String.fromEnvironment(
    'ZHIPU_API_KEY',
    defaultValue: '35bd6c37532642a4ad0e4899b9dddfe0.SHg4UhGjeMHcArnf',
  );

  static const String zhipuBaseUrl = String.fromEnvironment(
    'ZHIPU_BASE_URL',
    defaultValue: 'https://open.bigmodel.cn/api/paas/v4',
  );
}
```

### 环境变量配置

**方式1: 通过编译参数**
```bash
flutter run --dart-define=ZHIPU_API_KEY=your_api_key
```

**方式2: 通过 .env 文件**
```env
ZHIPU_API_KEY=35bd6c37532642a4ad0e4899b9dddfe0.SHg4UhGjeMHcArnf
ZHIPU_BASE_URL=https://open.bigmodel.cn/api/paas/v4
```

---

## 🔍 调试技巧

### 查看API调用

```dart
// 在 ZhipuTranslationService 中启用详细日志
Future<String> translateText({...}) async {
  try {
    debugPrint('=== 发送翻译请求 ===');
    debugPrint('文本: $text');
    debugPrint('源语言: $sourceLanguage');
    debugPrint('目标语言: $targetLanguage');
    debugPrint('API URL: $_baseUrl');

    final response = await _dio.post(...);

    debugPrint('=== 收到响应 ===');
    debugPrint('状态码: ${response.statusCode}');

    return result;
  } catch (e) {
    debugPrint('=== 请求失败 ===');
    debugPrint('错误: $e');
    rethrow;
  }
}
```

### 验证配置

```dart
// 在 initState 中添加验证日志
@override
void initState() {
  super.initState();
  _viewModel = InterpretViewModel();

  // 配置智谱AI服务
  _viewModel.setZhipuConfig(
    apiKey: AppConfig.zhipuApiKey,
    baseUrl: AppConfig.zhipuBaseUrl,
  );

  // 验证配置
  debugPrint('=== 智谱AI配置 ===');
  debugPrint('API Key: ${AppConfig.zhipuApiKey.substring(0, 10)}...');
  debugPrint('Base URL: ${AppConfig.zhipuBaseUrl}');

  _viewModel.addListener(_onViewModelChanged);
}
```

---

## 📚 相关文档

- [集成指南](zhipu_ai_integration.md)
- [网络错误修复](network_error_fix.md)
- [JWT认证修复](jwt_auth_fix.md)
- [故障排除](troubleshooting.md)

---

## ✨ 总结

**问题:** InterpretView 页面没有配置智谱AI服务
**解决:** 在 initState 中添加智谱AI配置
**状态:** ✅ 已完成

**功能验证:**
- ✅ 录音翻译使用智谱AI
- ✅ 实时翻译使用智谱AI
- ✅ 文本翻译使用智谱AI
- ✅ 所有翻译请求发送到正确的API端点

**用户体验:**
- 自动配置，无需手动设置
- 使用配置文件中的API密钥
- 支持环境变量覆盖
- 完整的错误处理

---

**更新日期:** 2025-01-13
**版本:** v1.2.0
**状态:** ✅ 完成并验证
