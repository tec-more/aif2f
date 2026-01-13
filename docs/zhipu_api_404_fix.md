# 智谱AI 404错误修复和服务限制说明

## 🔴 问题: 404错误

**错误信息:**
```
DioException [bad response]: This exception was thrown because the response has a status code of 404
```

**原因:** 智谱AI **不提供** 音频转文字(语音识别)API端点。

---

## ⚠️ 重要限制

### 智谱AI不支持的功能

1. **❌ 语音识别 (Audio Transcription)**
   - 端点: `/audio/transcriptions` (不存在)
   - 模型: Whisper (不支持)
   - 功能: 将音频文件转换为文本

2. **❌ 音频翻译**
   - 直接从音频翻译到目标语言 (不支持)

### 智谱AI支持的功能

1. **✅ 文本翻译**
   - 端点: `/chat/completions` (可用)
   - 模型: `glm-4-flash`
   - 功能: 使用LLM进行文本翻译

---

## 🔧 已实施的修复

### 1. 更新API端点

**文件:** [lib/core/services/zhipu_translation_service.dart](../lib/core/services/zhipu_translation_service.dart)

```dart
// ✅ 正确的端点
static const String _chatCompletionsEndpoint = '/chat/completions';

// ❌ 移除的端点(不存在)
// static const String _speechTranscriptionsEndpoint = '/audio/transcriptions';
```

### 2. 更新方法实现

#### `transcribeAudio()` - 语音识别
```dart
Future<String> transcribeAudio({
  required String audioFilePath,
  String language = 'zh',
}) async {
  // 智谱AI不支持音频转文字API
  throw Exception(
    '智谱AI目前不支持音频转文字API。请使用手动输入文本翻译功能,'
    '或集成其他语音识别服务(如OpenAI Whisper API)。'
  );
}
```

#### `translateText()` - 文本翻译
```dart
Future<String> translateText({...}) async {
  // ✅ 这个方法可以正常工作
  final data = {
    'model': 'glm-4-flash',
    'messages': [
      {
        'role': 'system',
        'content': '你是一个专业的翻译助手...',
      },
      {'role': 'user', 'content': prompt},
    ],
  };

  final response = await _dio.post(
    '$_baseUrl$_chatCompletionsEndpoint', // ✅ 正确的端点
    data: data,
  );
}
```

#### `translateAudio()` - 音频翻译
```dart
Future<ZhipuTranslationResult> translateAudio({...}) async {
  // ❌ 智谱AI不支持
  throw Exception(
    '智谱AI目前不支持音频转文字API。请使用以下方式:\n'
    '1. 手动输入文本进行翻译\n'
    '2. 使用其他语音识别服务(如OpenAI Whisper)配合智谱AI翻译'
  );
}
```

---

## 🎯 可用的功能

### 文本翻译 ✅

**使用方法:**
```dart
final service = ZhipuTranslationService();
service.setApiKey('your_api_key');

// 文本翻译可以正常工作
final result = await service.translateText(
  text: '你好世界',
  sourceLanguage: 'zh',
  targetLanguage: 'en',
);

print('翻译结果: $result'); // "Hello World"
```

**API调用:**
```http
POST https://open.bigmodel.cn/api/paas/v4/chat/completions
Authorization: Bearer {jwt_token}
Content-Type: application/json

{
  "model": "glm-4-flash",
  "messages": [
    {
      "role": "system",
      "content": "你是一个专业的翻译助手..."
    },
    {
      "role": "user",
      "content": "请将以下中文文本翻译成英文:\n\n你好世界"
    }
  ],
  "temperature": 0.3,
  "max_tokens": 2000
}
```

---

## 🔄 推荐的架构方案

### 方案1: 混合服务架构 ⭐ 推荐

```
录音 → OpenAI Whisper API (语音识别)
         ↓
       识别文本
         ↓
智谱AI GLM-4 (文本翻译)
         ↓
       翻译结果
```

**实现:**
```dart
class HybridTranslationService {
  final OpenAIWhisperService _whisper = OpenAIWhisperService();
  final ZhipuTranslationService _zhipu = ZhipuTranslationService();

  Future<String> translateAudio(String audioPath) async {
    // 1. 使用OpenAI进行语音识别
    final text = await _whisper.transcribe(audioPath);

    // 2. 使用智谱AI进行翻译
    final translation = await _zhipu.translateText(
      text: text,
      sourceLanguage: 'zh',
      targetLanguage: 'en',
    );

    return translation;
  }
}
```

### 方案2: 仅文本翻译

**使用场景:** 用户手动输入文本进行翻译

```
用户输入文本 → 智谱AI翻译 → 显示结果
```

**实现:**
```dart
// 在InterpretView中
ElevatedButton(
  onPressed: () async {
    if (_sourceController.text.isNotEmpty) {
      await _viewModel.translateText(_sourceController.text);
    }
  },
  child: Text('翻译'),
)
```

### 方案3: 使用其他语音识别服务

**可选项:**
- 阿里云语音识别
- 腾讯云语音识别
- 百度AI语音识别
- 科大讯飞语音识别

---

## 📊 API对比

| 功能 | OpenAI | 智谱AI |
|------|--------|--------|
| 语音识别 | ✅ Whisper API | ❌ 不支持 |
| 文本翻译 | ✅ GPT-3.5/4 | ✅ GLM-4 |
| 音频翻译 | ✅ | ❌ |
| 聊天对话 | ✅ | ✅ |
| 图像识别 | ✅ GPT-4V | ✅ GLM-4V |

---

## 🛠️ 当前实现状态

### InterpretViewModel 更新

**文件:** [lib/interpret/viewmodel/interpret_view_model.dart](../lib/interpret/viewmodel/interpret_view_model.dart)

**当前状态:**
```dart
Future<void> stopRecordingAndTranslate() async {
  // ...
  final result = await _zhipuService.translateAudio(
    audioFilePath: audioPath,
    sourceLanguage: sourceLanguageCode,
    targetLanguage: targetLanguageCode,
  );
  // ❌ 这会抛出异常,因为智谱AI不支持
}
```

**建议修改:**
```dart
Future<void> stopRecordingAndTranslate() async {
  // 方案1: 仅文本翻译
  if (_sourceController.text.isNotEmpty) {
    await _zhipuService.translateText(
      text: _sourceController.text,
      sourceLanguage: sourceLanguageCode,
      targetLanguage: targetLanguageCode,
    );
  }

  // 方案2: 使用混合服务
  // final text = await _whisperService.transcribe(audioPath);
  // final translation = await _zhipuService.translateText(...);
}
```

---

## 📝 UI更新建议

### InterpretView 更新

**当前问题:** "录音"按钮无法使用

**建议方案:**

1. **隐藏录音功能**
```dart
// 暂时隐藏录音按钮
// Widget _buildRecordButton() { ... }
```

2. **添加说明**
```dart
Card(
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      children: [
        Icon(Icons.info_outline),
        SizedBox(height: 8),
        Text(
          '语音翻译功能暂时不可用\n'
          '请使用文本输入进行翻译',
          textAlign: TextAlign.center,
        ),
      ],
    ),
  ),
)
```

3. **专注于文本翻译**
```dart
TextField(
  controller: _sourceController,
  decoration: InputDecoration(
    hintText: '请输入要翻译的文本',
    suffixIcon: IconButton(
      icon: Icon(Icons.translate),
      onPressed: () => _viewModel.translateText(_sourceController.text),
    ),
  ),
)
```

---

## 🔍 测试验证

### 文本翻译测试

```dart
test('智谱AI文本翻译测试', () async {
  final service = ZhipuTranslationService();
  service.setApiKey('your_api_key');

  final result = await service.translateText(
    text: '你好',
    sourceLanguage: 'zh',
    targetLanguage: 'en',
  );

  expect(result, isNotEmpty);
  print('翻译结果: $result');

  await service.dispose();
});
```

### 语音翻译测试 (预期失败)

```dart
test('智谱AI语音翻译应抛出异常', () async {
  final service = ZhipuTranslationService();
  service.setApiKey('your_api_key');

  expect(
    () => service.translateAudio(
      audioFilePath: '/test/audio.wav',
      sourceLanguage: 'zh',
      targetLanguage: 'en',
    ),
    throwsA(isA<Exception>()),
  );

  await service.dispose();
});
```

---

## 📚 相关文档

- [智谱AI API文档](https://open.bigmodel.cn/dev/api)
- [GLM-4模型说明](https://open.bigmodel.cn/dev/api#glm-4)
- [OpenAI Whisper API](https://platform.openai.com/docs/guides/speech-to-text)

---

## ✨ 总结

**问题:** 智谱AI不支持语音识别API,导致404错误
**解决:**
- ✅ 移除不存在的API端点
- ✅ 禁用语音翻译功能
- ✅ 保留文本翻译功能
- ✅ 添加详细错误提示

**可用功能:**
- ✅ 文本翻译 (GLM-4-Flash)
- ❌ 语音识别
- ❌ 音频翻译

**推荐方案:**
1. 使用智谱AI进行文本翻译
2. 集成其他服务的语音识别(如OpenAI Whisper)
3. 实现混合架构

---

**更新日期:** 2025-01-13
**版本:** v2.0.0
**状态:** ✅ 已修复限制并说明
