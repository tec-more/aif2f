# 科大讯飞实时语音识别 (ASR) 使用文档

## 目录
- [功能概述](#功能概述)
- [配置说明](#配置说明)
- [快速开始](#快速开始)
- [API参考](#api参考)
- [使用示例](#使用示例)
- [故障排除](#故障排除)

---

## 功能概述

科大讯飞实时语音识别服务提供基于WebSocket的实时语音转文字功能，支持：

- **实时识别**: 边录边转，低延迟
- **流式传输**: 通过WebSocket持续发送音频数据
- **自动格式转换**: 支持16-bit PCM音频格式
- **状态回调**: 连接状态、识别结果、错误处理
- **断线重连**: 支持自动重连机制

---

## 配置说明

### 1. API密钥配置

在 `lib/core/config/app_config.dart` 中配置科大讯飞API密钥：

```dart
static const String xFAPPID = String.fromEnvironment(
  'XF_APPID',
  defaultValue: '45f8b6dc', // 替换为你的APPID
);

static const String xFAPIKey = String.fromEnvironment(
  'XF_APIKey',
  defaultValue: 'd1e278fccac15457aaf4c98d85a65236', // 替换为你的APIKey
);

static const String xFAPISecret = String.fromEnvironment(
  'XF_APISecret',
  defaultValue: 'NzhiOWNjZTA5YmJmMWU5MGIwYmM4YTIw', // 替换为你的APISecret
);
```

### 2. 通过环境变量配置（推荐）

在运行应用时设置环境变量：

**Windows:**
```cmd
set XF_APPID=your_app_id
set XF_APIKey=your_api_key
set XF_APISecret=your_api_secret
flutter run
```

**Linux/macOS:**
```bash
export XF_APPID=your_app_id
export XF_APIKey=your_api_key
export XF_APISecret=your_api_secret
flutter run
```

### 3. 音频格式要求

科大讯飞ASR服务要求音频格式：
- **采样率**: 16000 Hz (16kHz)
- **位深度**: 16-bit PCM
- **声道**: 单声道 (mono)
- **编码**: raw

当前实现自动将系统音频（48kHz立体声）转换为16kHz单声道PCM。

---

## 快速开始

### 基础使用

```dart
import 'package:aif2f/core/services/ai_asr.dart';

// 1. 创建服务实例
final asrService = XfyunRealtimeAsrService();

// 2. 设置回调
asrService.onTextRecognized = (text) {
  print('识别结果: $text');
};

asrService.onError = (error) {
  print('识别错误: $error');
};

asrService.onConnected = () {
  print('已连接到ASR服务');
};

// 3. 连接服务
await asrService.connect();

// 4. 发送音频数据
List<int> audioData = getAudioData(); // 获取音频数据
asrService.sendAudioData(audioData);

// 5. 断开连接
await asrService.disconnect();
```

### 在ViewModel中使用

```dart
class InterpretViewModel extends Notifier<InterpretState> {
  final XfyunRealtimeAsrService _xfyunAsrService = XfyunRealtimeAsrService();

  Future<void> startSystemSound() async {
    // 设置识别回调
    _xfyunAsrService.onTextRecognized = (text) {
      state = state.copyWith(inputOneText: text);
    };

    // 连接ASR服务
    await _xfyunAsrService.connect();

    // 开始音频捕获
    final audioStream = _flutterF2fSound.startSystemSoundCapture();
    audioStream.listen((audioData) {
      // 发送音频到ASR服务
      _xfyunAsrService.sendAudioData(audioData);
    });
  }

  Future<void> stopSystemSound() async {
    await _xfyunAsrService.disconnect();
  }
}
```

---

## API参考

### XfyunRealtimeAsrService

#### 构造函数

```dart
XfyunRealtimeAsrService({
  String? appId,
  String? apiKey,
  String? apiSecret,
  String? wsUrl,
})
```

**参数说明:**
- `appId`: 科大讯飞应用ID（默认从AppConfig读取）
- `apiKey`: 科大讯飞API密钥（默认从AppConfig读取）
- `apiSecret`: 科大讯飞API密钥（默认从AppConfig读取）
- `wsUrl`: WebSocket服务器地址（默认值见下）

**默认WebSocket URL:**
```
wss://ws-api.xf-yun.com/v1/private/simult_interpretation
```

#### 方法

##### connect()

连接到科大讯飞ASR服务。

```dart
Future<bool> connect()
```

**返回值:**
- `bool`: 连接成功返回true，失败返回false

**示例:**
```dart
final connected = await asrService.connect();
if (connected) {
  print('连接成功');
}
```

##### sendAudioData()

发送音频数据到ASR服务。

```dart
void sendAudioData(List<int> audioData)
```

**参数说明:**
- `audioData`: 音频数据字节数组（16-bit PCM格式）

**示例:**
```dart
// 发送音频数据
asrService.sendAudioData(pcm16AudioData);
```

##### disconnect()

断开ASR服务连接。

```dart
Future<void> disconnect()
```

**示例:**
```dart
await asrService.disconnect();
```

##### dispose()

释放资源。

```dart
void dispose()
```

**示例:**
```dart
asrService.dispose();
```

#### 回调函数

##### onTextRecognized

识别到文本时触发。

```dart
Function(String)? onTextRecognized
```

**参数:**
- `text`: 识别的文本内容

**示例:**
```dart
asrService.onTextRecognized = (text) {
  print('识别: $text');
  // 更新UI或处理文本
};
```

##### onError

发生错误时触发。

```dart
Function(String)? onError
```

**参数:**
- `error`: 错误信息

**示例:**
```dart
asrService.onError = (error) {
  print('错误: $error');
  // 显示错误提示
};
```

##### onConnected

连接成功时触发。

```dart
Function()? onConnected
```

**示例:**
```dart
asrService.onConnected = () {
  print('已连接');
  // 更新连接状态UI
};
```

##### onDisconnected

连接断开时触发。

```dart
Function()? onDisconnected
```

**示例:**
```dart
asrService.onDisconnected = () {
  print('已断开');
  // 更新连接状态UI
};
```

---

## 使用示例

### 示例1: 实时系统语音识别

```dart
class RealtimeAsrExample {
  final XfyunRealtimeAsrService _asrService = XfyunRealtimeAsrService();

  Future<void> startRealtimeAsr() async {
    // 设置回调
    _asrService.onTextRecognized = (text) {
      print('实时识别: $text');
    };

    _asrService.onError = (error) {
      print('识别错误: $error');
    };

    // 连接服务
    final connected = await _asrService.connect();
    if (!connected) {
      print('连接失败');
      return;
    }

    // 模拟音频数据流
    Timer.periodic(Duration(milliseconds: 100), (timer) async {
      final audioData = await getAudioChunk();
      _asrService.sendAudioData(audioData);
    });
  }

  Future<void> stopRealtimeAsr() async {
    await _asrService.disconnect();
  }
}
```

### 示例2: 带UI状态更新

```dart
class AsrViewModel extends ChangeNotifier {
  final XfyunRealtimeAsrService _asrService = XfyunRealtimeAsrService();
  String _recognizedText = '';
  bool _isConnected = false;
  String _statusMessage = '';

  String get recognizedText => _recognizedText;
  bool get isConnected => _isConnected;
  String get statusMessage => _statusMessage;

  Future<void> startAsr() async {
    _asrService.onTextRecognized = (text) {
      _recognizedText = text;
      notifyListeners();
    };

    _asrService.onConnected = () {
      _isConnected = true;
      _statusMessage = '已连接，正在识别...';
      notifyListeners();
    };

    _asrService.onError = (error) {
      _statusMessage = '错误: $error';
      notifyListeners();
    };

    await _asrService.connect();
  }

  Future<void> stopAsr() async {
    await _asrService.disconnect();
    _isConnected = false;
    _statusMessage = '已断开';
    notifyListeners();
  }
}
```

### 示例3: 音频文件识别

```dart
class FileAsrExample {
  final XfyunRealtimeAsrService _asrService = XfyunRealtimeAsrService();

  Future<void> recognizeFile(String filePath) async {
    final file = File(filePath);
    final audioBytes = await file.readAsBytes();

    _asrService.onTextRecognized = (text) {
      print('文件识别: $text');
    };

    await _asrService.connect();

    // 分块发送音频数据
    const chunkSize = 3200; // 每块约100ms的音频
    for (int i = 0; i < audioBytes.length; i += chunkSize) {
      final end = (i + chunkSize < audioBytes.length)
          ? i + chunkSize
          : audioBytes.length;
      final chunk = audioBytes.sublist(i, end);
      _asrService.sendAudioData(chunk);

      // 延迟发送，模拟实时音频
      await Future.delayed(Duration(milliseconds: 100));
    }

    await _asrService.disconnect();
  }
}
```

---

## 故障排除

### 常见问题

#### 1. 连接失败

**问题**: ASR服务连接失败

**可能原因**:
- API密钥配置错误
- 网络连接问题
- WebSocket URL不正确

**解决方法**:
```dart
// 检查配置
debugPrint('APPID: ${AppConfig.xFAPPID}');
debugPrint('APIKey: ${AppConfig.xFAPIKey}');

// 检查网络连接
// 尝试ping服务器

// 检查WebSocket URL
final service = XfyunRealtimeAsrService(
  wsUrl: 'wss://ws-api.xf-yun.com/v1/private/simult_interpretation'
);
```

#### 2. 识别结果为空

**问题**: 音频已发送，但没有识别结果

**可能原因**:
- 音频格式不正确（需要16kHz PCM-16）
- 音频数据太小
- 音频质量太差（噪音、静音）

**解决方法**:
```dart
// 确保音频格式正确
// 检查音频数据长度
if (audioData.length < 1000) {
  debugPrint('音频数据太小');
  return;
}

// 测试音频数据
debugPrint('音频数据长度: ${audioData.length}');
debugPrint('前10字节: ${audioData.sublist(0, 10)}');
```

#### 3. 识别延迟高

**问题**: 识别结果返回很慢

**可能原因**:
- 网络延迟
- 发送音频块太大
- 服务器负载高

**解决方法**:
```dart
// 减小音频块大小
const chunkSize = 3200; // 约100ms

// 添加发送间隔
await Future.delayed(Duration(milliseconds: 50));
```

#### 4. WebSocket连接断开

**问题**: 连接经常断开

**可能原因**:
- 网络不稳定
- 长时间没有发送数据
- 服务器超时

**解决方法**:
```dart
// 添加心跳机制
Timer? heartbeatTimer;

void startHeartbeat() {
  heartbeatTimer = Timer.periodic(Duration(seconds: 30), (timer) {
    // 发送空数据保持连接
    asrService.sendAudioData([]);
  });
}

void stopHeartbeat() {
  heartbeatTimer?.cancel();
}
```

### 调试技巧

#### 1. 启用详细日志

```dart
// 在应用启动时设置
import 'package:flutter/foundation.dart';

void main() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('ASR Error: ${details.exception}');
  };
  runApp(MyApp());
}
```

#### 2. 测试音频格式

```dart
void testAudioFormat(List<int> audioData) {
  debugPrint('音频格式测试:');
  debugPrint('数据长度: ${audioData.length} 字节');
  debugPrint('时长: ${audioData.length / 32000} 秒 (16kHz 单声道 16-bit)');

  // 检查前几个字节
  if (audioData.length >= 10) {
    debugPrint('前10字节: ${audioData.sublist(0, 10)}');
  }
}
```

#### 3. 监控连接状态

```dart
_asrService.onConnected = () {
  debugPrint('✓ ASR已连接');
  setState(() => _status = 'connected');
};

_asrService.onDisconnected = () {
  debugPrint('✗ ASR已断开');
  setState(() => _status = 'disconnected');
};

_asrService.onError = (error) {
  debugPrint('! ASR错误: $error');
  setState(() => _status = 'error: $error');
};
```

### 性能优化

#### 1. 音频缓冲

```dart
class BufferedAsrSender {
  final XfyunRealtimeAsrService _asrService;
  final List<List<int>> _buffer = [];
  Timer? _sendTimer;

  BufferedAsrSender(this._asrService);

  void addAudio(List<int> audioData) {
    _buffer.add(audioData);

    // 当缓冲区达到一定大小时发送
    if (_buffer.length >= 5) {
      flush();
    }
  }

  void flush() {
    if (_buffer.isEmpty) return;

    final combined = _buffer.expand((e) => e).toList();
    _asrService.sendAudioData(combined);
    _buffer.clear();
  }
}
```

#### 2. 限制发送频率

```dart
class RateLimitedAsrSender {
  final XfyunRealtimeAsrService _asrService;
  DateTime? _lastSend;
  static const _minInterval = Duration(milliseconds: 50);

  RateLimitedAsrSender(this._asrService);

  void sendAudio(List<int> audioData) {
    final now = DateTime.now();
    if (_lastSend != null &&
        now.difference(_lastSend!) < _minInterval) {
      return; // 跳过此次发送
    }

    _asrService.sendAudioData(audioData);
    _lastSend = now;
  }
}
```

---

## 附录

### 音频格式转换

如果需要从其他格式转换为16kHz PCM-16：

```dart
List<int> convertToPcm16(List<int> rawAudio) {
  // 实现音频格式转换
  // 例如：从48kHz转换为16kHz
  // 从立体声转换为单声道
  // 从Float转换为PCM-16
  return convertedAudio;
}
```

### 相关资源

- [科大讯飞开放平台](https://www.xfyun.cn/)
- [科大讯飞实时语音转写API文档](https://www.xfyun.cn/doc/asr/voicedictation/API.html)
- [WebSocket协议说明](https://www.xfyun.cn/doc/asr/voicedictation/API.html)

### 版本历史

- **v1.0.0** (2024-01-23)
  - 初始版本
  - 支持实时语音识别
  - WebSocket连接
  - 回调机制

---

## 联系支持

如有问题或建议，请联系开发团队或提交Issue。
