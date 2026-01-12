# AI传译 - 音频翻译功能

## 功能概述

本项目实现了音频录制、语音识别和翻译的完整流程：

1. **音频录制**: 使用设备麦克风录制音频
2. **语音识别**: 将录制的音频转换为文本
3. **文本翻译**: 将识别的文本翻译成目标语言
4. **结果展示**: 在界面上显示原文和译文

## 使用方法

### 1. 录音翻译

1. 在主界面选择源语言和目标语言
2. 点击"录音"按钮开始录制
3. 对着麦克风说话
4. 点击"停止"按钮结束录制
5. 系统会自动进行语音识别和翻译
6. 结果会显示在文本框中

### 2. 文本翻译

1. 在源语言文本框中输入要翻译的文本
2. 系统会自动进行翻译
3. 翻译结果显示在目标语言文本框中

## 技术架构

### 服务层

#### AudioCaptureService
- 负责音频录制功能
- 支持开始、停止、暂停、恢复和取消录音
- 自动处理麦克风权限

#### SpeechRecognitionService
- 负责语音识别功能
- 支持 OpenAI Whisper API
- 提供模拟模式用于测试

#### TranslationService
- 负责文本翻译功能
- 支持 OpenAI GPT API
- 提供模拟模式用于测试

### ViewModel层

#### InterpretViewModel
- 管理翻译流程的状态
- 协调各个服务的调用
- 提供状态通知机制

## 配置说明

### API密钥设置

要在生产环境中使用真实API，需要设置API密钥：

```dart
_viewModel.setApiKey('YOUR_API_KEY');
```

### 支持的语言

- 英语 (EN)
- 中文 (ZH)
- 日语 (JA)
- 韩语 (KO)
- 法语 (FR)
- 德语 (DE)
- 西班牙语 (ES)
- 俄语 (RU)

## 依赖项

```yaml
dependencies:
  # 音频录制和处理
  record: ^5.1.0
  audioplayers: ^6.1.0

  # 权限管理
  permission_handler: ^11.3.1

  # HTTP请求
  http: ^1.2.0
  dio: ^5.4.0
```

## 权限要求

### Android
在 `android/app/src/main/AndroidManifest.xml` 中添加：

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

### iOS
在 `ios/Runner/Info.plist` 中添加：

```xml
<key>NSMicrophoneUsageDescription</key>
<string>需要使用麦克风进行录音</string>
```

## 测试模式

当前项目使用模拟模式进行测试，不需要实际的API密钥：

- `transcribeAudioMock()`: 模拟语音识别
- `translateTextMock()`: 模拟文本翻译

要启用真实API，请将方法调用从 `Mock` 版本改为实际版本。

## 未来改进

1. [ ] 添加TTS语音合成功能
2. [ ] 支持实时流式识别
3. [ ] 添加音频波形可视化
4. [ ] 支持多种翻译API提供商
5. [ ] 添加翻译历史记录
6. [ ] 支持批量翻译
