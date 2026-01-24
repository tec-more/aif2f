# 语音识别与翻译集成指南

## 目录
- [系统架构](#系统架构)
- [设置翻译语言](#设置翻译语言)
- [自动翻译ASR结果](#自动翻译asr结果)
- [API参考](#api参考)
- [完整示例](#完整示例)

---

## 系统架构

```
系统音频流
    ↓
科大讯飞ASR识别
    ↓
InterpretState.inputOneText (识别文本)
    ↓
TranslationService.sendTextMessage()
    ↓
InterpretState.translatedOneText (翻译结果)
    ↓
UI显示
```

---

## 设置翻译语言

### 1. 通过ViewModel设置语言

在 `InterpretViewModel` 中有以下方法可以设置语言：

```dart
// 设置第一栏源语言（识别语言）
viewModel.setOneSourceLanguage('中文');

// 设置第一栏目标语言（翻译语言）
viewModel.setOneTargetLanguage('英语');

// 设置第二栏源语言
viewModel.setTwoSourceLanguage('英语');

// 设置第二栏目标语言
viewModel.setTwoTargetLanguage('中文');
```

### 2. 支持的语言

当前支持的语言（在 `_languageCodeMap` 中定义）：

```dart
final Map<String, String> _languageCodeMap = {
  '英语': 'en',
  '中文': 'zh',
  '日语': 'ja',
  '韩语': 'ko',
  '法语': 'fr',
  '德语': 'de',
  '西班牙语': 'es',
  '俄语': 'ru',
};
```

### 3. 在UI中设置语言示例

```dart
// 源语言选择器
DropdownButton<String>(
  value: state.sourceOneLanguage,
  items: [
    DropdownMenuItem(value: '中文', child: Text('中文')),
    DropdownMenuItem(value: '英语', child: Text('英语')),
    DropdownMenuItem(value: '日语', child: Text('日语')),
    // ... 更多语言
  ],
  onChanged: (language) {
    ref.read(interpretViewModelProvider.notifier)
        .setOneSourceLanguage(language!);
  },
)

// 目标语言选择器
DropdownButton<String>(
  value: state.targetOneLanguage,
  items: [
    DropdownMenuItem(value: '英语', child: Text('英语')),
    DropdownMenuItem(value: '中文', child: Text('中文')),
    // ... 更多语言
  ],
  onChanged: (language) {
    ref.read(interpretViewModelProvider.notifier)
        .setOneTargetLanguage(language!);
  },
)
```

---

## 自动翻译ASR结果

### 方法1: 在ASR回调中触发翻译

修改 `interpret_view_model.dart` 中的 ASR 回调：

```dart
// 在 startSystemSound() 方法中
_xfyunAsrService.onTextRecognized = (text) {
  debugPrint('科大讯飞ASR识别结果: $text');

  // 更新识别文本
  state = state.copyWith(inputOneText: text);

  // 自动翻译识别结果
  if (text.isNotEmpty) {
    _translateRecognizedText(text);
  }
};
```

### 方法2: 添加翻译方法到ViewModel

在 `InterpretViewModel` 中添加翻译方法：

```dart
class InterpretViewModel extends Notifier<InterpretState> {
  // 添加翻译服务实例
  final TranslationService _translationService = TranslationService();

  // 初始化时连接翻译服务
  @override
  InterpretState build() {
    // 初始化翻译服务
    _initTranslationService();
    return const InterpretState();
  }

  /// 初始化翻译服务
  Future<void> _initTranslationService() async {
    try {
      await _translationService.initAndConnect(
        apiKey: AppConfig.zhipuApiKey,
        sourceLanguage: 'zh', // 默认源语言
        targetLanguage: 'en', // 默认目标语言
      );

      // 监听翻译结果
      _translationService.translationStream.listen((translatedText) {
        debugPrint('翻译结果: $translatedText');
        // 更新翻译结果到状态
        state = state.copyWith(translatedOneText: translatedText);
      });

      // 监听错误
      _translationService.errorStream.listen((error) {
        debugPrint('翻译错误: $error');
        state = state.copyWith(statusMessage: '翻译错误: $error');
      });
    } catch (e) {
      debugPrint('初始化翻译服务失败: $e');
    }
  }

  /// 翻译识别的文本
  void _translateRecognizedText(String text) {
    if (text.trim().isEmpty) return;

    try {
      // 更新语言配置
      final sourceLangCode = _getLanguageCode(state.sourceOneLanguage);
      final targetLangCode = _getLanguageCode(state.targetOneLanguage);

      _translationService.updateLanguages(
        sourceLangCode,
        targetLangCode,
        1, // type 1 表示第一栏
      );

      // 发送文本进行翻译
      _translationService.sendTextMessage(text);
      state = state.copyWith(statusMessage: '正在翻译...');
    } catch (e) {
      debugPrint('翻译失败: $e');
    }
  }

  /// 手动翻译文本
  Future<void> translateText(String text, [int type = 1]) async {
    if (text.isEmpty || state.isProcessing) return;

    if (type == 1) {
      state = state.copyWith(
        inputOneText: text,
        translatedOneText: '',
        isProcessing: true,
        statusMessage: '正在翻译...',
      );
    } else {
      state = state.copyWith(
        inputTwoText: text,
        translatedTwoText: '',
        isProcessing: true,
        statusMessage: '正在翻译...',
      );
    }

    try {
      final sourceLangCode = type == 1
          ? _getLanguageCode(state.sourceOneLanguage)
          : _getLanguageCode(state.sourceTwoLanguage);
      final targetLangCode = type == 1
          ? _getLanguageCode(state.targetOneLanguage)
          : _getLanguageCode(state.targetTwoLanguage);

      _translationService.updateLanguages(sourceLangCode, targetLangCode, type);
      _translationService.sendTextMessage(text);
    } catch (e) {
      state = state.copyWith(
        statusMessage: '翻译失败: $e',
        isProcessing: false
      );
      debugPrint('翻译错误: $e');
    }
  }
}
```

### 方法3: 使用Stream监听自动翻译

```dart
class InterpretViewModel extends Notifier<InterpretState> {
  StreamSubscription? _translationSubscription;

  @override
  InterpretState build() {
    _setupAutoTranslation();
    return const InterpretState();
  }

  /// 设置自动翻译
  void _setupAutoTranslation() {
    // 监听ASR识别结果的变化，自动翻译
    // 注意：这需要在UI层面或通过其他机制实现
  }

  @override
  void dispose() {
    _translationSubscription?.cancel();
    super.dispose();
  }
}
```

---

## API参考

### InterpretViewModel 方法

#### setOneSourceLanguage()

设置第一栏源语言（ASR识别的语言）。

```dart
void setOneSourceLanguage(String language)
```

**参数:**
- `language`: 语言名称（如 '中文', '英语', '日语'）

**示例:**
```dart
viewModel.setOneSourceLanguage('中文');
```

#### setOneTargetLanguage()

设置第一栏目标语言（翻译后的语言）。

```dart
void setOneTargetLanguage(String language)
```

**参数:**
- `language`: 语言名称（如 '英语', '中文', '日语'）

**示例:**
```dart
viewModel.setOneTargetLanguage('英语');
```

#### translateText()

手动翻译文本。

```dart
Future<void> translateText(String text, [int type = 1])
```

**参数:**
- `text`: 要翻译的文本
- `type`: 栏目类型（1=第一栏, 2=第二栏）

**示例:**
```dart
// 翻译第一栏
await viewModel.translateText('你好世界', 1);

// 翻译第二栏
await viewModel.translateText('Hello World', 2);
```

### TranslationService 方法

#### sendTextMessage()

发送文本消息进行翻译。

```dart
void sendTextMessage(String text)
```

**参数:**
- `text`: 要翻译的文本

**示例:**
```dart
_translationService.sendTextMessage('你好世界');
```

#### updateLanguages()

更新翻译语言配置。

```dart
void updateLanguages(String sourceLanguage, String targetLanguage, int type)
```

**参数:**
- `sourceLanguage`: 源语言代码（'zh', 'en', 'ja' 等）
- `targetLanguage`: 目标语言代码
- `type`: 栏目类型（1=第一栏, 2=第二栏）

**示例:**
```dart
_translationService.updateLanguages('zh', 'en', 1);
```

---

## 完整示例

### 示例1: ASR识别 + 自动翻译

```dart
class RealtimeAsrWithTranslation {
  late InterpretViewModel _viewModel;
  late XfyunRealtimeAsrService _asrService;
  late TranslationService _translationService;

  Future<void> initialize() async {
    // 1. 初始化翻译服务
    _translationService = TranslationService();
    await _translationService.initAndConnect(
      sourceLanguage: 'zh',
      targetLanguage: 'en',
    );

    // 监听翻译结果
    _translationService.translationStream.listen((translatedText) {
      print('翻译结果: $translatedText');
      // 更新UI
      _viewModel.state = _viewModel.state.copyWith(
        translatedOneText: translatedText,
      );
    });

    // 2. 初始化ASR服务
    _asrService = XfyunRealtimeAsrService();

    // 3. 设置ASR回调，自动翻译
    _asrService.onTextRecognized = (text) {
      print('识别: $text');

      // 更新识别文本
      _viewModel.state = _viewModel.state.copyWith(
        inputOneText: text,
      );

      // 自动翻译
      _translationService.sendTextMessage(text);
    };

    // 4. 连接ASR服务
    await _asrService.connect();
  }

  Future<void> start() async {
    // 开始音频捕获和识别
    // ...
  }
}
```

### 示例2: UI中设置语言并翻译

```dart
class TranslationPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(interpretViewModelProvider);

    return Column(
      children: [
        // 语言选择
        Row(
          children: [
            // 源语言
            DropdownButton<String>(
              value: state.sourceOneLanguage,
              items: [
                DropdownMenuItem(value: '中文', child: Text('中文 →')),
                DropdownMenuItem(value: '英语', child: Text('英语 →')),
                DropdownMenuItem(value: '日语', child: Text('日语 →')),
              ],
              onChanged: (lang) {
                ref.read(interpretViewModelProvider.notifier)
                    .setOneSourceLanguage(lang!);
              },
            ),

            // 目标语言
            DropdownButton<String>(
              value: state.targetOneLanguage,
              items: [
                DropdownMenuItem(value: '英语', child: Text('→ 英语')),
                DropdownMenuItem(value: '中文', child: Text('→ 中文')),
                DropdownMenuItem(value: '日语', child: Text('→ 日语')),
              ],
              onChanged: (lang) {
                ref.read(interpretViewModelProvider.notifier)
                    .setOneTargetLanguage(lang!);
              },
            ),
          ],
        ),

        // 识别文本显示
        TextField(
          decoration: InputDecoration(
            labelText: '识别文本 (${state.sourceOneLanguage})',
          ),
          controller: TextEditingController(text: state.inputOneText),
        ),

        // 翻译结果显示
        TextField(
          decoration: InputDecoration(
            labelText: '翻译结果 (${state.targetOneLanguage})',
          ),
          controller: TextEditingController(text: state.translatedOneText),
        ),

        // 手动翻译按钮
        ElevatedButton(
          onPressed: () {
            ref.read(interpretViewModelProvider.notifier)
                .translateText(state.inputOneText, 1);
          },
          child: Text('翻译'),
        ),
      ],
    );
  }
}
```

### 示例3: 实时语音识别 + 翻译完整流程

```dart
class CompleteAsrTranslationFlow {
  Future<void> startCompleteFlow() async {
    // 1. 设置语言
    final viewModel = ref.read(interpretViewModelProvider.notifier);
    viewModel.setOneSourceLanguage('中文');
    viewModel.setOneTargetLanguage('英语');

    // 2. 初始化翻译服务
    final translationService = TranslationService();
    await translationService.initAndConnect(
      sourceLanguage: 'zh',
      targetLanguage: 'en',
    );

    // 3. 监听翻译结果
    translationService.translationStream.listen((translatedText) {
      // 自动更新翻译结果到UI
      viewModel.state = viewModel.state.copyWith(
        translatedOneText: translatedText,
        isProcessing: false,
        statusMessage: '翻译完成',
      );
    });

    // 4. 设置ASR回调
    final asrService = XfyunRealtimeAsrService();
    asrService.onTextRecognized = (text) {
      // 更新识别文本
      viewModel.state = viewModel.state.copyWith(
        inputOneText: text,
      );

      // 触发翻译
      translationService.sendTextMessage(text);
    };

    // 5. 开始识别
    await asrService.connect();

    // 6. 开始系统音频捕获
    await viewModel.startSystemSound();
  }
}
```

---

## 常见配置

### 中文 → 英文

```dart
viewModel.setOneSourceLanguage('中文');
viewModel.setOneTargetLanguage('英语');
```

### 英文 → 中文

```dart
viewModel.setOneSourceLanguage('英语');
viewModel.setOneTargetLanguage('中文');
```

### 日语 → 英语

```dart
viewModel.setOneSourceLanguage('日语');
viewModel.setOneTargetLanguage('英语');
```

### 双语互译

```dart
// 第一栏：中文 → 英文
viewModel.setOneSourceLanguage('中文');
viewModel.setOneTargetLanguage('英语');

// 第二栏：英文 → 中文
viewModel.setTwoSourceLanguage('英语');
viewModel.setTwoTargetLanguage('中文');
```

---

## 注意事项

1. **语言代码映射**: 确保 `_languageCodeMap` 中包含所需语言
2. **翻译服务连接**: 使用翻译前需要先调用 `initAndConnect()`
3. **异步操作**: 翻译是异步的，需要通过 Stream 监听结果
4. **错误处理**: 建议监听 `errorStream` 处理翻译错误
5. **资源释放**: 使用完毕后调用 `disconnect()` 或 `dispose()`

---

## 相关文档

- [科大讯飞ASR使用文档](XFYUN_ASR_GUIDE.md)
- [TranslationService API](../lib/core/services/translation_service.dart)
- [InterpretViewModel API](../lib/interpret/viewmodel/interpret_view_model.dart)
