# 智谱AI语音翻译集成指南

## 概述

本项目已成功集成智谱AI(Zhipu AI)的语音翻译服务,提供语音识别和文本翻译功能。

## 服务特性

### 1. 语音识别
- 支持将音频文件转换为文本
- 使用智谱AI Whisper模型
- 支持多种语言(中文、英文、日文、韩文等)

### 2. 文本翻译
- 使用GLM-4模型进行翻译
- 支持多语言互译
- 高质量翻译结果

### 3. 一体化语音翻译
- 自动完成语音识别→文本翻译
- 返回识别文本和翻译结果
- 简化使用流程

## 文件结构

```
lib/core/services/
├── zhipu_translation_service.dart    # 智谱AI翻译服务
├── audio_capture_service.dart         # 音频捕获服务
└── speech_recognition_service.dart    # 语音识别服务(兼容)

lib/interpret/viewmodel/
└── interpret_view_model.dart          # 已集成智谱AI服务
```

## 使用方法

### 1. 基础配置

在应用启动时配置API密钥:

```dart
// 在初始化时设置
final viewModel = InterpretViewModel();

// 设置智谱AI配置
viewModel.setZhipuConfig(
  apiKey: 'your_api_key_here',  // 从智谱AI平台获取
  baseUrl: 'https://open.bigmodel.cn/api/paas/v4', // 可选,默认值
);
```

### 2. 语音翻译

在InterpretView中使用:

```dart
// 开始录音并翻译
await viewModel.startRecordingAndTranslate();

// 停止录音并获取翻译结果
await viewModel.stopRecordingAndTranslate();

// 获取翻译结果
final result = viewModel.currentTranslation;
print('识别文本: ${result?.sourceText}');
print('翻译文本: ${result?.targetText}');
```

### 3. 直接使用ZhipuTranslationService

如果需要在其他地方使用:

```dart
import 'package:aif2f/core/services/zhipu_translation_service.dart';

final service = ZhipuTranslationService();
service.setApiKey('your_api_key');

// 方式1: 仅语音识别
final text = await service.transcribeAudio(
  audioFilePath: '/path/to/audio.wav',
  language: 'zh',
);

// 方式2: 仅文本翻译
final translated = await service.translateText(
  text: '你好世界',
  sourceLanguage: 'zh',
  targetLanguage: 'en',
);

// 方式3: 完整语音翻译(推荐)
final result = await service.translateAudio(
  audioFilePath: '/path/to/audio.wav',
  sourceLanguage: 'zh',
  targetLanguage: 'en',
);

print('识别: ${result.recognizedText}');
print('翻译: ${result.translatedText}');
```

## API密钥获取

1. 访问 [智谱AI开放平台](https://open.bigmodel.cn/)
2. 注册/登录账号
3. 进入控制台
4. 创建API密钥
5. 格式: `{id}.{secret}`

## 支持的语言

| 语言 | 代码 |
|------|------|
| 中文 | zh, ZH, 中文 |
| 英语 | en, EN, 英语 |
| 日语 | ja, JA, 日语 |
| 韩语 | ko, KO, 韩语 |
| 法语 | fr, FR, 法语 |
| 德语 | de, DE, 德语 |
| 西班牙语 | es, ES, 西班牙语 |
| 俄语 | ru, RU, 俄语 |

## API端点

### 语音识别
- 端点: `/audio/transcriptions`
- 模型: `whisper-1`
- 支持格式: WAV, MP3, M4A等

### 文本翻译
- 端点: `/chat/completions`
- 模型: `glm-4-flash`
- 温度: 0.3(保证翻译准确性)

## 音频配置建议

为了获得最佳识别效果,建议使用以下音频配置:

```dart
RecordConfig(
  encoder: AudioEncoder.wav,      // WAV格式
  sampleRate: 16000,              // 16kHz采样率
  bitRate: 128000,                // 128kbps比特率
  numChannels: 1,                 // 单声道
)
```

## 测试模式

服务提供了模拟测试模式,无需API密钥即可测试:

```dart
// 使用测试数据
final result = await service.translateAudioMock(
  audioFilePath: '/path/to/audio.wav',
  sourceLanguage: 'zh',
  targetLanguage: 'en',
);
```

## 错误处理

服务已内置错误处理,常见错误包括:

- `音频文件不存在`: 检查文件路径
- `API Key未设置`: 调用`setApiKey()`
- `无效的API Key格式`: 检查格式是否为`{id}.{secret}`
- `网络错误`: 检查网络连接
- `翻译失败`: 检查API配额

## 性能优化

1. **并发请求**: 避免同时发送多个请求
2. **音频大小**: 建议单段音频不超过10MB
3. **缓存结果**: 可考虑缓存翻译结果
4. **流式处理**: 实时翻译使用分段处理

## 注意事项

1. API Key包含敏感信息,请妥善保管
2. 不要将API Key提交到版本控制系统
3. 建议使用环境变量或配置文件管理
4. 注意API调用配额限制
5. 生产环境建议实现完整的JWT签名认证

## 更新日志

### 2025-01-13
- ✅ 创建ZhipuTranslationService
- ✅ 集成语音识别功能
- ✅ 集成文本翻译功能
- ✅ 集成到InterpretViewModel
- ✅ 添加API密钥配置方法
- ✅ 添加多语言支持
- ✅ 添加错误处理

## 技术支持

- 智谱AI文档: https://open.bigmodel.cn/dev/api
- GLM-4模型: https://open.bigmodel.cn/dev/api#glm-4
- Whisper模型: https://open.bigmodel.cn/dev/api#audio

## 许可证

本服务遵循项目许可证。
