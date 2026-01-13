# Flutter 音频流监听实现指南

本文档介绍如何在 Flutter 中实现麦克风音频流的实时监听和处理。

## 目录
1. [方案对比](#方案对比)
2. [推荐方案：flutter_sound](#推荐方案flutter_sound)
3. [快速开始](#快速开始)
4. [使用示例](#使用示例)
5. [注意事项](#注意事项)

---

## 方案对比

### 1. flutter_sound ⭐⭐⭐⭐⭐ (推荐)

**优点：**
- ✅ 支持实时音频流
- ✅ 跨平台（iOS、Android、Web）
- ✅ 功能完整，文档详细
- ✅ 支持多种音频格式
- ✅ 社区活跃，维护良好

**缺点：**
- ❌ 包体积较大（~2MB）
- ❌ 配置相对复杂

**适用场景：** 需要实时音频流处理的应用

### 2. record

**优点：**
- ✅ 轻量级
- ✅ 简单易用
- ✅ 已经在项目依赖中

**缺点：**
- ❌ **不支持实时音频流**（只能录制到文件）
- ❌ 无法直接获取音频数据流

**适用场景：** 只需要录音保存，不需要实时处理

### 3. 原生平台代码 (MethodChannel)

**优点：**
- ✅ 完全自定义
- ✅ 性能最优
- ✅ 可以访问底层API

**缺点：**
- ❌ 需要编写原生代码（Swift/Kotlin）
- ❌ 维护成本高
- ❌ 平台差异大

**适用场景：** 有特殊性能需求或需要底层控制

---

## 推荐方案：flutter_sound

### 安装依赖

在 `pubspec.yaml` 中添加：

```yaml
dependencies:
  flutter_sound: ^9.0.0
  permission_handler: ^11.3.1  # 已存在
```

然后运行：

```bash
flutter pub get
```

### Android 配置

在 `android/app/src/main/AndroidManifest.xml` 中添加：

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

### iOS 配置

在 `ios/Runner/Info.plist` 中添加：

```xml
<key>NSMicrophoneUsageDescription</key>
<string>需要使用麦克风进行语音录制</string>
```

---

## 快速开始

### 1. 创建音频服务

创建文件 `lib/core/services/audio_stream_service.dart`：

```dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler';

class AudioStreamService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  StreamController<Uint8List>? _audioStreamController;
  bool _isRecording = false;

  bool get isRecording => _isRecording;
  Stream<Uint8List>? get audioStream => _audioStreamController?.stream;

  /// 初始化录音器
  Future<void> initialize() async {
    await _recorder.openRecorder();
  }

  /// 请求麦克风权限
  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// 开始录音流
  Future<bool> startRecording({
    int sampleRate = 16000,
    int bufferSize = 4096,
  }) async {
    if (_isRecording) return false;

    try {
      // 检查权限
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        final granted = await requestPermission();
        if (!granted) return false;
      }

      // 创建流控制器
      _audioStreamController = StreamController<Uint8List>.broadcast();

      // 开始录音到流
      await _recorder.startRecorder(
        codec: Codec.pcm16,
        toStream: _audioStreamController!.sink,
        sampleRate: sampleRate,
        numChannels: 1,
        bufferSize: bufferSize,
      );

      _isRecording = true;
      debugPrint('音频流已启动 (采样率: $sampleRate Hz)');
      return true;
    } catch (e) {
      debugPrint('启动音频流失败: $e');
      return false;
    }
  }

  /// 停止录音
  Future<void> stopRecording() async {
    if (!_isRecording) return;

    try {
      await _recorder.stopRecorder();
      await _audioStreamController?.close();
      _isRecording = false;
      debugPrint('音频流已停止');
    } catch (e) {
      debugPrint('停止音频流失败: $e');
    }
  }

  /// 释放资源
  Future<void> dispose() async {
    await stopRecording();
    await _recorder.closeRecorder();
  }
}
```

### 2. 在 ViewModel 中使用

```dart
class YourViewModel extends ChangeNotifier {
  final AudioStreamService _audioService = AudioStreamService();
  StreamSubscription<Uint8List>? _audioSubscription;

  /// 初始化
  Future<void> initialize() async {
    await _audioService.initialize();

    // 请求权限
    final hasPermission = await _audioService.requestPermission();
    if (!hasPermission) {
      debugPrint('没有麦克风权限');
      return;
    }
  }

  /// 开始监听
  Future<void> startListening() async {
    final success = await _audioService.startRecording(
      sampleRate: 16000,
      bufferSize: 4096,
    );

    if (!success) {
      debugPrint('启动音频流失败');
      return;
    }

    // 订阅音频流
    _audioSubscription = _audioService.audioStream?.listen(
      (audioData) {
        // 处理音频数据
        _processAudioData(audioData);
      },
      onError: (error) {
        debugPrint('音频流错误: $error');
      },
    );
  }

  /// 处理音频数据
  void _processAudioData(Uint8List audioData) {
    debugPrint('收到音频数据: ${audioData.length} 字节');

    // 这里可以：
    // 1. 发送到语音识别API
    // 2. 进行实时转录
    // 3. 分析音量、频率
    // 4. 保存到文件
  }

  /// 停止监听
  Future<void> stopListening() async {
    await _audioSubscription?.cancel();
    await _audioService.stopRecording();
  }

  @override
  Future<void> dispose() async {
    await _audioSubscription?.cancel();
    await _audioService.dispose();
    super.dispose();
  }
}
```

---

## 使用示例

### 示例1：实时语音识别

```dart
void _processAudioData(Uint8List audioData) {
  // 发送到语音识别API
  _speechRecognitionService.sendAudio(audioData);
}
```

### 示例2：音量检测

```dart
double _calculateVolume(Uint8List pcm16Data) {
  if (pcm16Data.isEmpty) return 0.0;

  int sum = 0;
  for (int i = 0; i < pcm16Data.length; i += 2) {
    final sample = (pcm16Data[i + 1] << 8) | pcm16Data[i];
    final signedSample = sample > 32767 ? sample - 65536 : sample;
    sum += signedSample.abs();
  }

  return sum / (pcm16Data.length ~/ 2);
}
```

### 示例3：保存音频文件

```dart
final List<Uint8List> _audioChunks = [];

void _processAudioData(Uint8List audioData) {
  _audioChunks.add(audioData);
}

Future<void> saveToFile() async {
  final output = Uint8List(_audioChunks.fold(0, (sum, chunk) => sum + chunk.length));
  int offset = 0;
  for (final chunk in _audioChunks) {
    output.setRange(offset, offset + chunk.length, chunk);
    offset += chunk.length;
  }

  final file = File('/path/to/output.pcm');
  await file.writeAsBytes(output);
}
```

---

## 注意事项

### 1. 性能优化

- ⚠️ 音频流会频繁产生数据（每秒多次）
- ⚠️ 避免在 UI 线程处理音频数据
- ⚠️ 使用 Isolate 处理大量音频数据

```dart
// 使用 Compute 在后台线程处理
final result = await compute(_processAudioInIsolate, audioData);
```

### 2. 内存管理

- ⚠️ 长时间录音会积累大量数据
- ⚠️ 定期清理不需要的音频数据
- ⚠️ 及时释放 StreamSubscription

### 3. 权限处理

- ⚠️ Android 需要动态请求权限
- ⚠️ iOS 需要在 Info.plist 中说明用途
- ⚠️ 处理权限被永久拒绝的情况

### 4. 平台差异

| 特性 | Android | iOS | Web |
|------|---------|-----|-----|
| 实时流 | ✅ | ✅ | ✅ |
| 后台录音 | ✅ 需要配置 | ✅ 需要配置 | ❌ |
| 采样率 | 自由 | 推荐 16kHz/48kHz | 受浏览器限制 |
| 音频格式 | PCM/AAC | PCM/AAC | Opus/PCM |

### 5. 调试技巧

```dart
// 记录音频流统计
class AudioStreamStats {
  int totalBytes = 0;
  int chunkCount = 0;
  DateTime? startTime;

  void addChunk(Uint8List data) {
    totalBytes += data.length;
    chunkCount++;
    startTime ??= DateTime.now();

    if (chunkCount % 100 == 0) {
      final duration = DateTime.now().difference(startTime!).inSeconds;
      final bitrate = (totalBytes * 8) / duration;
      print('音频流: $chunkCount 块, ${totalBytes ~/ 1024} KB, ${bitrate.toInt()} bps');
    }
  }
}
```

---

## 常见问题

### Q: 为什么 record 包不支持实时流？

A: `record` 包设计目标是简单的录音功能，将音频保存到文件。实时流处理需要更底层的 API 控制，这是 `flutter_sound` 的专长。

### Q: 如何选择采样率？

A:
- **8kHz**: 电话质量，适合简单语音识别
- **16kHz**: 标准语音识别（推荐）
- **44.1kHz**: CD 音质，音乐应用
- **48kHz**: 专业音频制作

### Q: 如何降低延迟？

A:
- 减小 `bufferSize`（2048 或 4096）
- 使用 PCM 格式（无需编码）
- 在独立线程处理音频数据

---

## 参考资料

- [flutter_sound 官方文档](https://pub.dev/packages/flutter_sound)
- [Flutter 音频处理指南](https://docs.flutter.dev/development/platform-integration/platform-channels)
- [AudioRecorder API 文档](https://pub.dev/packages/record)

---

## 总结

对于实时音频流监听，**强烈推荐使用 `flutter_sound`**：

1. ✅ 支持真正的音频流
2. ✅ 跨平台兼容性好
3. ✅ 文档完善，社区活跃
4. ✅ 功能丰富，扩展性强

当前项目中的 `record` 包适合简单的录音功能，但不适合实时音频流处理。
