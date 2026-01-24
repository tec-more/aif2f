# Azure 语音服务集成指南

## 目录
- [Azure vs 科大讯飞对比](#azure-vs-科大讯飞对比)
- [Azure 语音服务概述](#azure-语音服务概述)
- [配置 Azure 语音服务](#配置-azure-语音服务)
- [集成到项目](#集成到项目)
- [API 使用示例](#api-使用示例)
- [实时语音识别](#实时语音识别)
- [实时语音翻译](#实时语音翻译)
- [常见问题](#常见问题)

---

## Azure vs 科大讯飞对比

| 功能特性 | Azure Speech Services | 科大讯飞 (XFYun) |
|---------|----------------------|-----------------|
| **实时语音识别** | ✅ 支持 | ✅ 支持 |
| **实时语音翻译** | ✅ 支持 | ✅ 支持 |
| **支持语言数量** | 100+ 语言 | 30+ 语言（主要是中文） |
| **中文识别准确率** | 高 | 极高（国内第一） |
| **英文识别准确率** | 极高 | 中等 |
| **定价模式** | 按使用量付费 | 按使用量付费 |
| **免费额度** | 每月5小时音频 | 需申请试用 |
| **WebSocket支持** | ✅ | ✅ |
| **REST API** | ✅ | ✅ |
| **离线SDK** | ✅ | ❌ |
| **自定义语音模型** | ✅ | ✅ |
| **文档质量** | 高（多语言） | 中（主要是中文） |
| **国内网络访问** | 可能需要VPN | ✅ 无需VPN |

### 推荐使用场景

**选择 Azure Speech Services:**
- 需要支持多语言（英语、日语、韩语等）
- 主要识别英语或其他非中文语言
- 需要离线SDK功能
- 国际化应用

**选择科大讯飞:**
- 主要识别中文
- 需要最高的中文识别准确率
- 国内网络环境
- 对成本敏感

---

## Azure 语音服务概述

### 主要功能

1. **Speech-to-Text (STT)** - 语音转文字
2. **Text-to-Speech (TTS)** - 文字转语音
3. **Speech Translation** - 实时语音翻译
4. **Custom Speech** - 自定义语音模型
5. **Speaker Recognition** - 说话人识别

### 支持的语音识别格式

```
格式: WAV, OGG, MP3, FLAC
采样率: 8kHz - 48kHz
位深度: 16-bit PCM
声道: 单声道或立体声
```

### WebSocket 端点

```
# 实时语音识别
wss://{region}.stt.speech.microsoft.com/speech/recognition/conversation/cognitiveservices/v1

# 实时语音翻译
wss://{region}.s2s.speech.microsoft.com/speech/translation/cognitiveservices/v1
```

其中 `{region}` 是 Azure 区域，如：
- `eastasia` (东亚-香港)
- `southeastasia` (东南亚-新加坡)
- `westus` (美国西部)
- `eastus` (美国东部)

---

## 配置 Azure 语音服务

### 1. 创建 Azure 资源

1. 访问 [Azure Portal](https://portal.azure.com/)
2. 搜索 "Speech Services"
3. 点击 "创建"
4. 选择定价层（Free F0 或 Standard S0）
5. 创建资源并获取密钥

### 2. 获取密钥和区域

创建资源后：
- **密钥 (Key)**: 在 "Keys and Endpoint" 页面
- **区域 (Region)**: 在 "Overview" 页面

示例：
```
密钥: your_subscription_key_here
区域: eastasia
```

### 3. 添加到 AppConfig

在 `lib/core/config/app_config.dart` 中添加：

```dart
/// Azure 语音服务配置
static const String azureSpeechKey = String.fromEnvironment(
  'AZURE_SPEECH_KEY',
  defaultValue: '', // 在这里填入你的密钥，或使用环境变量
);

static const String azureSpeechRegion = String.fromEnvironment(
  'AZURE_SPEECH_REGION',
  defaultValue: 'eastasia', // 默认区域
);

/// Azure Speech Services WebSocket URL
static String get azureSpeechWsUrl =>
    'wss://$azureSpeechRegion.stt.speech.microsoft.com/speech/recognition/conversation/cognitiveservices/v1';

/// Azure Speech Translation WebSocket URL
static String get azureTranslationWsUrl =>
    'wss://$azureSpeechRegion.s2s.speech.microsoft.com/speech/translation/cognitiveservices/v1';
```

### 4. 环境变量配置（推荐）

**Windows:**
```cmd
set AZURE_SPEECH_KEY=your_subscription_key_here
set AZURE_SPEECH_REGION=eastasia
flutter run
```

**Linux/macOS:**
```bash
export AZURE_SPEECH_KEY=your_subscription_key_here
export AZURE_SPEECH_REGION=eastasia
flutter run
```

---

## 集成到项目

### 方法1: 使用 Azure Cognitive Services SDK

在 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  azure_cognitive_speech: ^1.22.0
```

### 方法2: 使用 WebSocket（推荐用于实时处理）

创建新的服务文件 `lib/core/services/azure_speech_service.dart`：

```dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:aif2f/core/config/app_config.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Azure 实时语音识别服务
class AzureRealtimeSpeechService {
  final String _subscriptionKey;
  final String _region;
  WebSocketChannel? _wsChannel;
  bool _isConnected = false;

  // 回调函数
  Function(String)? onRecognized;
  Function(String)? onError;
  Function()? onConnected;
  Function()? onDisconnected;

  AzureRealtimeSpeechService({
    String? subscriptionKey,
    String? region,
  })  : _subscriptionKey = subscriptionKey ?? AppConfig.azureSpeechKey,
        _region = region ?? AppConfig.azureSpeechRegion;

  /// 连接WebSocket
  Future<bool> connect() async {
    try {
      if (_isConnected) {
        debugPrint('Azure Speech: 已经连接');
        return true;
      }

      // 构建WebSocket URL
      final url = '${AppConfig.azureSpeechWsUrl}?language=zh-CN&format=detailed';
      debugPrint('连接 Azure Speech: $url');

      _wsChannel = WebSocketChannel.connect(
        Uri.parse(url),
        headers: {
          'Ocp-Apim-Subscription-Key': _subscriptionKey,
          'X-ConnectionId': _generateConnectionId(),
        },
      );

      // 监听连接状态
      _wsChannel!.ready.then((_) {
        _isConnected = true;
        debugPrint('Azure Speech: 连接成功');
        onConnected?.call();
      });

      // 监听消息
      _wsChannel!.stream.listen(
        (message) => _handleMessage(message),
        onError: (error) {
          debugPrint('Azure Speech: 错误: $error');
          _isConnected = false;
          onError?.call('连接错误: $error');
        },
        onDone: () {
          debugPrint('Azure Speech: 连接关闭');
          _isConnected = false;
          onDisconnected?.call();
        },
      );

      return true;
    } catch (e) {
      debugPrint('Azure Speech: 连接失败: $e');
      onError?.call('连接失败: $e');
      return false;
    }
  }

  /// 发送音频数据
  void sendAudioData(List<int> audioData) {
    if (!_isConnected || _wsChannel == null) {
      debugPrint('Azure Speech: 未连接');
      return;
    }

    _wsChannel!.sink.add(audioData);
  }

  /// 处理接收到的消息
  void _handleMessage(dynamic message) {
    try {
      if (message is String) {
        final data = jsonDecode(message);

        // 检查识别结果
        if (data['RecognitionStatus'] == 'Success') {
          final text = data['DisplayText'] ?? '';
          if (text.isNotEmpty) {
            debugPrint('Azure Speech: 识别到文字: $text');
            onRecognized?.call(text);
          }
        }

        // 检查错误
        if (data['RecognitionStatus'] == 'Error') {
          final error = data['ErrorDetails'] ?? '未知错误';
          debugPrint('Azure Speech: 错误: $error');
          onError?.call('识别错误: $error');
        }
      }
    } catch (e) {
      debugPrint('Azure Speech: 解析消息失败: $e');
    }
  }

  /// 断开连接
  Future<void> disconnect() async {
    if (_wsChannel != null) {
      await _wsChannel!.sink.close();
      _wsChannel = null;
      _isConnected = false;
      debugPrint('Azure Speech: 已断开连接');
    }
  }

  /// 生成连接ID
  String _generateConnectionId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// 释放资源
  void dispose() {
    disconnect();
  }
}
```

---

## API 使用示例

### 基础使用

```dart
// 1. 创建服务实例
final azureSpeech = AzureRealtimeSpeechService(
  subscriptionKey: 'your_key_here',
  region: 'eastasia',
);

// 2. 设置回调
azureSpeech.onRecognized = (text) {
  print('识别结果: $text');
};

azureSpeech.onError = (error) {
  print('错误: $error');
};

// 3. 连接服务
await azureSpeech.connect();

// 4. 发送音频数据
azureSpeech.sendAudioData(audioData);

// 5. 断开连接
await azureSpeech.disconnect();
```

### 在 ViewModel 中使用

```dart
class InterpretViewModel extends Notifier<InterpretState> {
  // 使用 Azure Speech Services
  final AzureRealtimeSpeechService _azureSpeechService =
      AzureRealtimeSpeechService();

  Future<void> startSystemSound() async {
    // 设置识别回调
    _azureSpeechService.onRecognized = (text) {
      state = state.copyWith(inputOneText: text);
    };

    // 连接服务
    await _azureSpeechService.connect();

    // 开始音频捕获
    final audioStream = _flutterF2fSound.startSystemSoundCapture();
    audioStream.listen((audioData) {
      _azureSpeechService.sendAudioData(audioData);
    });
  }

  Future<void> stopSystemSound() async {
    await _azureSpeechService.disconnect();
  }
}
```

---

## 实时语音识别

### 配置参数

```dart
// 构建WebSocket URL时可以添加参数
String buildAzureSpeechUrl({
  String language = 'zh-CN',        // 语言
  String format = 'simple',         // 返回格式: simple, detailed
  bool profanity = false,           // 是否过滤脏话
  String? channelId,                // 频道ID
  String? format = 'detailed',      // 输出格式
}) {
  final params = {
    'language': language,
    'format': format,
    if (profanity) 'profanity': 'raw',
    if (channelId != null) 'channelId': channelId,
  };

  return Uri.parse('${AppConfig.azureSpeechWsUrl}?')
    .replace(queryParameters: params)
    .toString();
}
```

### 支持的语言代码

常用语言：
- `zh-CN`: 中文（普通话）
- `en-US`: 英语（美国）
- `en-GB`: 英语（英国）
- `ja-JP`: 日语
- `ko-KR`: 韩语
- `fr-FR`: 法语
- `de-DE`: 德语
- `es-ES`: 西班牙语
- `ru-RU`: 俄语

完整列表：[Azure Speech 支持的语言](https://docs.microsoft.com/azure/cognitive-services/speech-service/language-support)

---

## 实时语音翻译

Azure 的实时语音翻译功能更强大，可以直接将语音从一种语言翻译成另一种语言。

### 创建翻译服务

```dart
/// Azure 实时语音翻译服务
class AzureSpeechTranslationService {
  final String _subscriptionKey;
  final String _region;
  WebSocketChannel? _wsChannel;
  bool _isConnected = false;

  // 回调函数
  Function(String)? onTranslated;
  Function(String)? onError;
  Function()? onConnected;
  Function()? onDisconnected;

  AzureSpeechTranslationService({
    String? subscriptionKey,
    String? region,
  })  : _subscriptionKey = subscriptionKey ?? AppConfig.azureSpeechKey,
        _region = region ?? AppConfig.azureSpeechRegion;

  /// 连接WebSocket
  Future<bool> connect({
    String fromLanguage = 'zh-CN',
    String toLanguage = 'en',
  }) async {
    try {
      if (_isConnected) {
        debugPrint('Azure Translation: 已经连接');
        return true;
      }

      // 构建WebSocket URL
      final url = Uri.parse('${AppConfig.azureTranslationWsUrl}?'
          'from=$fromLanguage&to=$toLanguage&api-version=1.0');

      debugPrint('连接 Azure Translation: $url');

      _wsChannel = WebSocketChannel.connect(
        url,
        headers: {
          'Ocp-Apim-Subscription-Key': _subscriptionKey,
          'X-ConnectionId': _generateConnectionId(),
        },
      );

      // 监听连接状态
      _wsChannel!.ready.then((_) {
        _isConnected = true;
        debugPrint('Azure Translation: 连接成功');
        onConnected?.call();
      });

      // 监听消息
      _wsChannel!.stream.listen(
        (message) => _handleMessage(message),
        onError: (error) {
          debugPrint('Azure Translation: 错误: $error');
          _isConnected = false;
          onError?.call('连接错误: $error');
        },
        onDone: () {
          debugPrint('Azure Translation: 连接关闭');
          _isConnected = false;
          onDisconnected?.call();
        },
      );

      return true;
    } catch (e) {
      debugPrint('Azure Translation: 连接失败: $e');
      onError?.call('连接失败: $e');
      return false;
    }
  }

  /// 发送音频数据
  void sendAudioData(List<int> audioData) {
    if (!_isConnected || _wsChannel == null) {
      debugPrint('Azure Translation: 未连接');
      return;
    }

    _wsChannel!.sink.add(audioData);
  }

  /// 处理接收到的消息
  void _handleMessage(dynamic message) {
    try {
      if (message is String) {
        final data = jsonDecode(message);

        // 检查翻译结果
        if (data['type'] == 'final') {
          final translations = data['translations'] as List?;
          if (translations != null && translations.isNotEmpty) {
            final text = translations[0]['text'] ?? '';
            if (text.isNotEmpty) {
              debugPrint('Azure Translation: 翻译结果: $text');
              onTranslated?.call(text);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Azure Translation: 解析消息失败: $e');
    }
  }

  /// 断开连接
  Future<void> disconnect() async {
    if (_wsChannel != null) {
      await _wsChannel!.sink.close();
      _wsChannel = null;
      _isConnected = false;
      debugPrint('Azure Translation: 已断开连接');
    }
  }

  /// 生成连接ID
  String _generateConnectionId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// 释放资源
  void dispose() {
    disconnect();
  }
}
```

### 使用翻译服务

```dart
// 创建翻译服务
final translationService = AzureSpeechTranslationService();

// 设置回调
translationService.onTranslated = (translatedText) {
  print('翻译结果: $translatedText');
  state = state.copyWith(translatedOneText: translatedText);
};

// 连接服务（从中文翻译到英文）
await translationService.connect(
  fromLanguage: 'zh-CN',
  toLanguage: 'en',
);

// 发送音频
audioStream.listen((audioData) {
  translationService.sendAudioData(audioData);
});
```

---

## 常见问题

### Q1: Azure Speech Services 支持离线使用吗？

**A:** Azure Speech Services 需要网络连接。如果需要离线功能，可以使用 Azure Speech Devices SDK 或 Embedded Speech SDK。

### Q2: 如何选择合适的区域？

**A:** 根据你的地理位置选择最近的区域以降低延迟：
- 中国用户: `eastasia` (香港) 或 `southeastasia` (新加坡)
- 美国用户: `eastus` 或 `westus`
- 欧洲用户: `westeurope` 或 `northeurope`

### Q3: 免费层有什么限制？

**A:** Free F0 层限制：
- 每月最多 5 小时音频
- 每秒最多 10 个请求
- 不支持自定义模型

### Q4: 如何提高识别准确率？

**A:**
1. 使用高质量的音频（16kHz+ 采样率）
2. 减少背景噪音
3. 使用正确的语言代码
4. 提供领域相关的词汇表
5. 使用自定义语音模型（需要标准层）

### Q5: 如何处理网络中断？

**A:** 实现自动重连机制：

```dart
class ReconnectableAzureSpeech {
  Timer? _reconnectTimer;
  int _retryCount = 0;
  static const int _maxRetries = 5;

  Future<void> connectWithRetry() async {
    while (_retryCount < _maxRetries) {
      final connected = await _azureSpeech.connect();
      if (connected) {
        _retryCount = 0;
        return;
      }

      _retryCount++;
      final delay = Duration(seconds: _retryCount * 2);
      debugPrint('重连 $_retryCount 次，等待 ${delay.inSeconds} 秒...');
      await Future.delayed(delay);
    }

    debugPrint('达到最大重连次数');
  }

  void setupReconnect() {
    _azureSpeech.onDisconnected = () {
      debugPrint('连接断开，尝试重连...');
      connectWithRetry();
    };
  }
}
```

---

## 成本估算

### 定价示例（标准层 S0）

| 功能 | 价格 | 说明 |
|-----|------|------|
| 实时语音识别 | $1.00/小时 | 按音频时长计费 |
| 语音翻译 | $10.00/百万字符 | 按翻译字符数计费 |
| 文字转语音 | $4.00/百万字符 | 按输出字符数计费 |

### 与科大讯飞对比

假设每月使用 100 小时：

- **Azure**: 100 × $1 = $100/月
- **科大讯飞**: 约¥500-1000/月（取决于套餐）

---

## 迁移指南

### 从科大讯飞迁移到 Azure

1. **修改 WebSocket URL**
   ```dart
   // 从
   'wss://ws-api.xf-yun.com/v1/private/simult_interpretation'
   // 到
   'wss://eastasia.stt.speech.microsoft.com/speech/recognition/conversation/cognitiveservices/v1'
   ```

2. **修改认证方式**
   ```dart
   // 从（URL参数）
   '?appid=$appId&timestamp=$timestamp&signature=$signature'
   // 到（HTTP Header）
   headers: {'Ocp-Apim-Subscription-Key': subscriptionKey}
   ```

3. **修改消息格式**
   ```dart
   // 科大讯飞返回格式
   {'text': '识别文本', 'status': 0}
   // Azure 返回格式
   {'RecognitionStatus': 'Success', 'DisplayText': '识别文本'}
   ```

### 同时支持两个服务

```dart
enum SpeechServiceProvider {
  xfyun,
  azure,
}

class UnifiedSpeechService {
  SpeechServiceProvider provider = SpeechServiceProvider.xfyun;

  Future<void> connect() async {
    switch (provider) {
      case SpeechServiceProvider.xfyun:
        await _xfyunService.connect();
        break;
      case SpeechServiceProvider.azure:
        await _azureService.connect();
        break;
    }
  }

  void switchProvider(SpeechServiceProvider newProvider) {
    disconnect();
    provider = newProvider;
    connect();
  }
}
```

---

## 相关资源

- [Azure Speech Services 官方文档](https://docs.microsoft.com/azure/cognitive-services/speech-service/)
- [Azure Speech SDK](https://docs.microsoft.com/azure/cognitive-services/speech-service/speech-sdk-reference)
- [定价详情](https://azure.microsoft.com/pricing/details/cognitive-services/speech-services/)
- [支持的语言](https://docs.microsoft.com/azure/cognitive-services/speech-service/language-support)
- [快速入门](https://docs.microsoft.com/azure/cognitive-services/speech-service/get-started-speech-to-text)
