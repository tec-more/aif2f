# Flutter Sound 音频流使用指南

本文档介绍如何使用 `flutter_sound` 实现音频流监听和处理。

## 快速开始

### 1. 基本使用

```dart
import 'package:aif2f/core/services/audio_stream_service.dart';

class MyViewModel extends ChangeNotifier {
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

  /// 开始监听音频流
  Future<void> startListening() async {
    final success = await _audioService.startListening(
      sampleRate: 16000,  // 采样率：16kHz（适合语音识别）
      bufferSize: 4096,   // 缓冲区：4KB（低延迟）
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
      onDone: () {
        debugPrint('音频流结束');
      },
    );
  }

  /// 处理音频数据
  void _processAudioData(Uint8List audioData) {
    debugPrint('收到音频数据: ${audioData.length} 字节');

    // 1. 计算音量
    final volume = AudioDataProcessor.calculateAverageVolume(audioData);
    debugPrint('当前音量: $volume');

    // 2. 检测是否有声音
    final hasSound = AudioDataProcessor.hasSound(audioData, threshold: 500.0);
    if (hasSound) {
      debugPrint('检测到声音');
    }

    // 3. 发送到语音识别API
    // _speechRecognitionService.sendAudio(audioData);

    // 4. 保存到文件
    // _saveToFile(audioData);
  }

  /// 停止监听
  Future<void> stopListening() async {
    await _audioSubscription?.cancel();
    await _audioService.stopListening();
  }

  @override
  Future<void> dispose() async {
    await _audioSubscription?.cancel();
    await _audioService.dispose();
    super.dispose();
  }
}
```

### 2. 暂停和恢复

```dart
// 暂停录音（不停止流）
await _audioService.pauseListening();

// 恢复录音
await _audioService.resumeListening();

// 完全停止
await _audioService.stopListening();
```

### 3. 监控录音状态

```dart
// 获取录音器状态
final state = await _audioService.getRecorderState();
switch (state) {
  case RecorderState.isStopped:
    print('录音器已停止');
    break;
  case RecorderState.isRecording:
    print('正在录音');
    break;
  case RecorderState.isPaused:
    print('录音已暂停');
    break;
}
```

## 音频数据处理工具

### AudioDataProcessor 工具类

```dart
import 'package:aif2f/core/services/audio_stream_service.dart';

// 1. 计算平均音量
final volume = AudioDataProcessor.calculateAverageVolume(audioData);
// 返回值范围：0.0 - 32768.0

// 2. 计算 RMS 音量（更准确）
final rmsVolume = AudioDataProcessor.calculateRMSVolume(audioData);

// 3. 静音检测
final hasSound = AudioDataProcessor.hasSound(
  audioData,
  threshold: 500.0,  // 自定义阈值
);

// 4. 归一化音量到 0.0-1.0
final normalized = AudioDataProcessor.normalizeVolume(volume);

// 5. 转换为分贝
final decibels = AudioDataProcessor.volumeToDecibels(volume);
```

## 高级用法

### 1. 实时语音识别集成

```dart
class RealTimeSpeechViewModel extends ChangeNotifier {
  final AudioStreamService _audioService = AudioStreamService();
  final SpeechRecognitionService _speechService = SpeechRecognitionService();

  StreamSubscription<Uint8List>? _audioSubscription;
  final List<Uint8List> _audioChunks = [];

  Future<void> startListening() async {
    await _audioService.initialize();

    final success = await _audioService.startListening(
      sampleRate: 16000,
      bufferSize: 4096,
    );

    if (!success) return;

    _audioSubscription = _audioService.audioStream?.listen(
      (audioData) {
        // 累积音频数据
        _audioChunks.add(audioData);

        // 每累积到一定大小就发送识别
        final totalSize = _audioChunks.fold(0, (sum, chunk) => sum + chunk.length);
        if (totalSize >= 16000) {  // 约1秒的音频
          _sendToRecognition();
        }
      },
    );
  }

  void _sendToRecognition() {
    // 合并音频块
    final totalSize = _audioChunks.fold(0, (sum, chunk) => sum + chunk.length);
    final combined = Uint8List(totalSize);
    int offset = 0;
    for (final chunk in _audioChunks) {
      combined.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }

    // 发送到语音识别
    _speechService.recognizeAudio(combined);

    // 清空缓存
    _audioChunks.clear();
  }
}
```

### 2. 音频可视化

```dart
class AudioVisualizerViewModel extends ChangeNotifier {
  final AudioStreamService _audioService = AudioStreamService();
  StreamSubscription<Uint8List>? _audioSubscription;

  double _currentVolume = 0.0;
  List<double> _waveformData = [];

  double get currentVolume => _currentVolume;
  List<double> get waveformData => _waveformData;

  Future<void> startMonitoring() async {
    await _audioService.initialize();
    await _audioService.startListening();

    _audioSubscription = _audioService.audioStream?.listen(
      (audioData) {
        // 计算音量
        _currentVolume = AudioDataProcessor.calculateAverageVolume(audioData);

        // 生成波形数据（降采样）
        _waveformData = _generateWaveform(audioData);

        notifyListeners();
      },
    );
  }

  /// 生成波形数据（用于UI显示）
  List<double> _generateWaveform(Uint8List audioData) {
    const int displayPoints = 100;  // 显示100个点
    final List<double> waveform = [];

    final int samplesPerPoint = audioData.length ~/ (displayPoints * 2);

    for (int i = 0; i < displayPoints; i++) {
      int sum = 0;
      int count = 0;

      for (int j = 0; j < samplesPerPoint && (i * samplesPerPoint * 2 + j * 2) < audioData.length; j++) {
        final index = i * samplesPerPoint * 2 + j * 2;
        if (index + 1 < audioData.length) {
          final sample = (audioData[index + 1] << 8) | audioData[index];
          final signedSample = sample > 32767 ? sample - 65536 : sample;
          sum += signedSample.abs();
          count++;
        }
      }

      if (count > 0) {
        waveform.add(sum / count);
      } else {
        waveform.add(0.0);
      }
    }

    return waveform;
  }
}
```

### 3. 录音到文件

```dart
class AudioRecorderViewModel extends ChangeNotifier {
  final AudioStreamService _audioService = AudioStreamService();
  StreamSubscription<Uint8List>? _audioSubscription;

  final List<Uint8List> _audioChunks = [];
  bool _isRecording = false;

  Future<void> startRecording() async {
    await _audioService.initialize();

    final success = await _audioService.startListening(
      sampleRate: 16000,
      bufferSize: 8192,
    );

    if (!success) return;

    _isRecording = true;
    _audioChunks.clear();

    _audioSubscription = _audioService.audioStream?.listen(
      (audioData) {
        _audioChunks.add(audioData);
      },
    );
  }

  Future<void> stopRecording() async {
    await _audioSubscription?.cancel();
    await _audioService.stopListening();
    _isRecording = false;

    // 合并所有音频块
    final totalSize = _audioChunks.fold(0, (sum, chunk) => sum + chunk.length);
    final combined = Uint8List(totalSize);
    int offset = 0;
    for (final chunk in _audioChunks) {
      combined.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }

    // 保存到文件
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.pcm');
    await file.writeAsBytes(combined);

    debugPrint('录音已保存: ${file.path}');
  }
}
```

## 参数配置建议

### 采样率 (sampleRate)

| 采样率 | 质量 | 用途 |
|--------|------|------|
| 8000 Hz | 电话质量 | 简单语音识别 |
| 16000 Hz | 标准语音 | **语音识别（推荐）** |
| 22050 Hz | 音乐质量 | 音乐应用 |
| 44100 Hz | CD 音质 | 高质量音频 |
| 48000 Hz | 专业音频 | 专业制作 |

### 缓冲区大小 (bufferSize)

| 大小 | 延迟 | CPU占用 | 用途 |
|------|------|---------|------|
| 2048 | 很低 | 很高 | 实时处理 |
| 4096 | 低 | 高 | **推荐（平衡）** |
| 8192 | 中 | 中 | 一般应用 |
| 16384 | 高 | 低 | 后台录音 |

### 编码格式

```dart
// PCM16 - 无损，适合语音识别
codec: Codec.pcm16

// PCM8 - 8位，文件小但有损失
codec: Codec.pcm8

// PCMFloat32 - 32位浮点，专业音频
codec: Codec.pcmFloat32
```

## 平台配置

### Android

在 `android/app/src/main/AndroidManifest.xml` 添加：

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
```

### iOS

在 `ios/Runner/Info.plist` 添加：

```xml
<key>NSMicrophoneUsageDescription</key>
<string>需要使用麦克风进行语音录制和识别</string>

<key>NSSpeechRecognitionUsageDescription</key>
<string>需要使用语音识别功能</string>
```

### Web

无需额外配置，但用户需要授权麦克风访问。

## 性能优化

### 1. 使用 Isolate 处理音频

```dart
// 在后台线程处理音频数据
_audioSubscription = _audioService.audioStream?.listen(
  (audioData) async {
    final result = await compute(_processAudioInBackground, audioData);
    // 处理结果
  },
);

// 静态函数（在 Isolate 中运行）
static Map<String, dynamic> _processAudioInBackground(Uint8List audioData) {
  final volume = AudioDataProcessor.calculateAverageVolume(audioData);
  final hasSound = AudioDataProcessor.hasSound(audioData);

  return {
    'volume': volume,
    'hasSound': hasSound,
    'size': audioData.length,
  };
}
```

### 2. 控制处理频率

```dart
int _chunkCount = 0;

_audioSubscription = _audioService.audioStream?.listen(
  (audioData) {
    _chunkCount++;

    // 每10个音频块处理一次，减少CPU占用
    if (_chunkCount % 10 == 0) {
      _processAudioData(audioData);
    }
  },
);
```

### 3. 内存管理

```dart
// 定期清理音频数据
if (_audioChunks.length > 1000) {
  _audioChunks.removeRange(0, 500);  // 保留最新的500个
}

// 或者限制总大小
final totalSize = _audioChunks.fold(0, (sum, chunk) => sum + chunk.length);
if (totalSize > 16 * 1024 * 1024) {  // 超过16MB
  _audioChunks.clear();  // 清空
}
```

## 故障排查

### 问题1: 权限被拒绝

```dart
final hasPermission = await _audioService.requestPermission();
if (!hasPermission) {
  // 打开应用设置
  await openAppSettings();
}
```

### 问题2: 音频流没有数据

检查采样率和缓冲区设置：
```dart
await _audioService.startListening(
  sampleRate: 16000,  // 确保采样率正确
  bufferSize: 4096,   // 缓冲区不能太小
);
```

### 问题3: 音频质量差

尝试提高采样率：
```dart
sampleRate: 44100,  // 使用CD音质
```

## 注意事项

1. **⚠️ Windows 平台不支持**: flutter_sound 不支持 Windows、macOS、Linux
2. **⚠️ 内存管理**: 长时间录音会累积大量数据，需要定期清理
3. **⚠️ 线程安全**: 大量音频处理建议使用 Isolate
4. **⚠️ 权限处理**: 必须先请求权限才能开始录音
5. **⚠️ 资源释放**: 使用完毕后必须调用 `dispose()`

## 参考资料

- [flutter_sound 官方文档](https://pub.dev/packages/flutter_sound)
- [flutter_sound 示例代码](https://github.com/dooboolab/flutter_sound)
- [音频格式详解](https://en.wikipedia.org/wiki/Pulse-code_modulation)
