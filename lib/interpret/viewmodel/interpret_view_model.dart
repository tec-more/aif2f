import 'dart:async';
import 'dart:convert';
import 'dart:io'; // 导入文件操作相关的包
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_f2f_sound/flutter_f2f_sound.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aif2f/interpret/model/interpret_model.dart';
import 'package:aif2f/core/services/translation_service.dart';

// 状态类
@immutable
class InterpretState {
  final TranslationResult? currentTranslation;
  final bool isProcessing;
  final bool isConnected;
  final bool isSystemSoundEnabled;
  final double onefontSize;
  final double twofontSize;
  final int panelNumber;
  final String oneContentTypes;
  final String twoContentTypes;
  final String statusMessage;
  final String inputOneText;
  final String translatedOneText;
  final String inputTwoText;
  final String translatedTwoText;
  final String sourceOneLanguage;
  final String targetOneLanguage;
  final String sourceTwoLanguage;
  final String targetTwoLanguage;

  // final StreamSubscription<List<int>>? systemSoundCaptureStreamSubscription;
  // final int systemSoundDataLength;

  const InterpretState({
    this.currentTranslation,
    this.isProcessing = false,
    this.isConnected = false,
    this.isSystemSoundEnabled = false,
    this.onefontSize = 14,
    this.twofontSize = 14,
    this.panelNumber = 2, // 默认显示第二栏(录音) , 1 显示第一栏(系统音频)
    //o2o 只显示源语言，s2s 只显示目标语言，o2s 显示源语言和目标语言，l2l 源语言和目标语言分离
    this.oneContentTypes = 'o2s',
    //o2o 只显示源语言，s2s 只显示目标语言，o2s 显示源语言和目标语言，l2l 源语言和目标语言分离
    this.twoContentTypes = 'o2s',
    this.statusMessage = '',
    this.inputOneText = '',
    this.translatedOneText = '',
    this.inputTwoText = '',
    this.translatedTwoText = '',
    this.sourceOneLanguage = '中文',
    this.targetOneLanguage = '英语',
    this.sourceTwoLanguage = '英语',
    this.targetTwoLanguage = '中文',
    // this.systemSoundCaptureStreamSubscription,
    // this.systemSoundDataLength = 0,
  });

  InterpretState copyWith({
    TranslationResult? currentTranslation,
    bool? isProcessing,
    bool? isConnected,
    bool? isSystemSoundEnabled,
    double? onefontSize,
    double? twofontSize,
    int? panelNumber,
    String? oneContentTypes,
    String? twoContentTypes,
    String? statusMessage,
    String? inputOneText,
    String? translatedOneText,
    String? inputTwoText,
    String? translatedTwoText,
    String? sourceOneLanguage,
    String? targetOneLanguage,
    String? sourceTwoLanguage,
    String? targetTwoLanguage,
    // StreamSubscription<List<int>>? systemSoundCaptureStreamSubscription,
    // int? systemSoundDataLength,
  }) {
    return InterpretState(
      currentTranslation: currentTranslation ?? this.currentTranslation,
      isProcessing: isProcessing ?? this.isProcessing,
      isConnected: isConnected ?? this.isConnected,
      isSystemSoundEnabled: isSystemSoundEnabled ?? this.isSystemSoundEnabled,
      onefontSize: onefontSize ?? this.onefontSize,
      twofontSize: twofontSize ?? this.twofontSize,
      panelNumber: panelNumber ?? this.panelNumber,
      oneContentTypes: oneContentTypes ?? this.oneContentTypes,
      twoContentTypes: twoContentTypes ?? this.twoContentTypes,
      statusMessage: statusMessage ?? this.statusMessage,
      inputOneText: inputOneText ?? this.inputOneText,
      translatedOneText: translatedTwoText ?? this.translatedOneText,
      inputTwoText: inputTwoText ?? this.inputTwoText,
      translatedTwoText: translatedTwoText ?? this.translatedTwoText,
      sourceOneLanguage: sourceOneLanguage ?? this.sourceOneLanguage,
      targetOneLanguage: targetOneLanguage ?? this.targetOneLanguage,
      sourceTwoLanguage: sourceTwoLanguage ?? this.sourceTwoLanguage,
      targetTwoLanguage: targetTwoLanguage ?? this.targetTwoLanguage,
      // systemSoundCaptureStreamSubscription:
      //     systemSoundCaptureStreamSubscription ??
      //     this.systemSoundCaptureStreamSubscription,
      // systemSoundDataLength:
      //     systemSoundDataLength ?? this.systemSoundDataLength,
    );
  }
}

// Provider
final interpretViewModelProvider =
    NotifierProvider.autoDispose<InterpretViewModel, InterpretState>(
      InterpretViewModel.new,
    );

class InterpretViewModel extends Notifier<InterpretState> {
  // 初始化语音获取服务
  final FlutterF2fSound _flutterF2fSound = FlutterF2fSound();
  StreamSubscription<List<int>>? systemSoundCaptureStreamSubscription;

  // 音频文件输出流
  IOSink? _audioFileSink;
  // 音频文件
  File? _audioFile;
  // 音频数据长度（用于更新 WAV 文件头）
  int _audioDataLength = 0;
  // 音频输出格式：true = 16-bit PCM, false = 32-bit Float
  bool _outputAsPcm16 = true;
  // 调试：音频数据块计数
  int _audioChunkCount = 0;
  // 调试：首次接收时间
  DateTime? _firstChunkTime;
  // 调试：音频数据样本分析
  List<int>? _firstChunkSamples;
  // 语言代码映射
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

  @override
  InterpretState build() {
    // 初始化状态
    return const InterpretState();
  }

  /// 设置输入文本
  void setInputText(String text, [int type = 1]) {
    if (type == 1) {
      state = state.copyWith(inputOneText: text);
    } else {
      state = state.copyWith(inputTwoText: text);
    }
  }

  /// 翻译文本
  Future<void> translateText(String text, [int type = 1]) async {
    if (text.isEmpty || state.isProcessing) return;

    if (type == 1) {
      state = state.copyWith(
        inputOneText: text,
        translatedOneText: '', // 清空之前的翻译
        isProcessing: true,
        statusMessage: '正在翻译...',
      );
    } else {
      state = state.copyWith(
        inputTwoText: text,
        translatedTwoText: '', // 清空之前的翻译
        isProcessing: true,
        statusMessage: '正在翻译...',
      );
    }

    try {
      // _translationService.sendTextMessage(text);
      // 翻译结果会通过 stream 异步返回
    } catch (e) {
      state = state.copyWith(statusMessage: '翻译失败: $e', isProcessing: false);
      debugPrint('翻译错误: $e');
    }
  }

  /// 设置源语言
  void setOneSourceLanguage(String language) {
    state = state.copyWith(sourceOneLanguage: language);
  }

  /// 设置目标语言
  void setOneTargetLanguage(String language) {
    state = state.copyWith(targetOneLanguage: language);
  }

  /// 设置源语言
  void setTwoSourceLanguage(String language) {
    state = state.copyWith(sourceTwoLanguage: language);
  }

  /// 设置目标语言
  void setTwoTargetLanguage(String language) {
    state = state.copyWith(targetTwoLanguage: language);
  }

  /// 同时设置源语言和目标语言（推荐使用）
  Future<void> setLanguages(
    String sourceLanguage,
    String targetLanguage, [
    int type = 1,
  ]) async {
    if (type == 1) {
      setOneSourceLanguage(sourceLanguage);
      setOneTargetLanguage(targetLanguage);
    } else {
      setTwoSourceLanguage(sourceLanguage);
      setTwoTargetLanguage(targetLanguage);
    }
  }

  /// 切换语言
  void swapLanguages([int type = 1]) async {
    final newSourceLanguage = type == 1
        ? state.sourceOneLanguage
        : state.sourceTwoLanguage;
    final newTargetLanguage = type == 1
        ? state.targetOneLanguage
        : state.targetTwoLanguage;
    final newInputOneText = state.translatedOneText;
    final newTranslatedOneText = state.inputOneText;
    debugPrint('切换语言: $newSourceLanguage -> $newTargetLanguage');
    if (type == 1) {
      setOneSourceLanguage(newTargetLanguage);
      setOneTargetLanguage(newSourceLanguage);
    } else {
      setTwoSourceLanguage(newTargetLanguage);
      setTwoTargetLanguage(newSourceLanguage);
    }
    state = state.copyWith(
      // sourceOneLanguage: type == 1
      //     ? newSourceLanguage
      //     : state.sourceOneLanguage,
      // targetOneLanguage: type == 1
      //     ? newTargetLanguage
      //     : state.targetOneLanguage,
      // sourceTwoLanguage: type == 2
      //     ? newSourceLanguage
      //     : state.sourceTwoLanguage,
      // targetTwoLanguage: type == 2
      //     ? newTargetLanguage
      //     : state.targetTwoLanguage,
      inputOneText: newInputOneText,
      translatedOneText: newTranslatedOneText,
    );

    // 更新翻译结果
    final newTranslation = TranslationResult(
      sourceText: newInputOneText,
      targetText: newTranslatedOneText,
      sourceLanguage: newSourceLanguage,
      targetLanguage: newTargetLanguage,
    );
    state = state.copyWith(currentTranslation: newTranslation);
  }

  /// 切换自动播放
  void toggleAutoPlay() {
    // TODO: 实现自动播放功能
  }

  /// 设置API密钥
  void setApiKey(String apiKey) {
    // TODO: 实现 API 密钥设置
  }

  /// 清空翻译结果
  void clearTranslation() {
    state = state.copyWith(
      inputOneText: '',
      translatedOneText: '',
      currentTranslation: null,
    );
  }

  /// 开始获取系统声音
  /// 开启后，会将系统声音发送到服务器进行翻译
  /// 开始获取系统声音并保存为标准 WAV 文件
  Future<void> startSystemSound() async {
    if (!state.isSystemSoundEnabled) return;

    try {
      // 取消之前的订阅（如果有）
      await systemSoundCaptureStreamSubscription?.cancel();
      await _audioFileSink?.close();

      // 创建音频文件
      _audioFile = File('a.wav');
      _audioFileSink = _audioFile!.openWrite();

      // 写入 WAV 文件头
      // 注意：这里需要根据实际捕获的音频格式调整参数
      await _writeWavHeader(_audioFileSink!);

      // 重置音频数据长度和调试变量
      _audioDataLength = 0;
      _audioChunkCount = 0;
      _firstChunkTime = null;
      _firstChunkSamples = null;

      // Get system sound capture stream
      final systemSoundStream = _flutterF2fSound!.startSystemSoundCapture();

      debugPrint('=== 开始系统声音捕获调试 ===');

      // Listen to system sound capture stream
      systemSoundCaptureStreamSubscription = systemSoundStream.listen(
        (audioData) {
          // 调试：记录首次接收时间
          if (_firstChunkTime == null) {
            _firstChunkTime = DateTime.now();
          }
          _audioChunkCount++;

          // 调试：保存第一个数据块的前16字节用于分析
          if (_firstChunkSamples == null && audioData.length >= 16) {
            _firstChunkSamples = audioData.sublist(0, 16);
            debugPrint('首个数据块前16字节: $_firstChunkSamples');
            debugPrint('首个数据块长度: ${audioData.length} 字节');
          }

          // 每100个数据块打印一次统计信息
          if (_audioChunkCount % 100 == 0) {
            final elapsed = DateTime.now()
                .difference(_firstChunkTime!)
                .inMilliseconds;
            final avgBytesPerSec = elapsed > 0
                ? (_audioDataLength * 1000 / elapsed).toInt()
                : 0;
            debugPrint(
              '[$_audioChunkCount] 数据长度: $_audioDataLength 字节, '
              '平均字节率: $avgBytesPerSec bytes/s, '
              '最后块大小: ${audioData.length} 字节',
            );
          }

          // 处理音频数据
          List<int> dataToWrite = audioData;

          // 如果需要转换为 PCM-16
          if (_outputAsPcm16) {
            dataToWrite = _convertFloatToPcm16(audioData);
          }

          _audioDataLength += dataToWrite.length;
          // 保存音频数据到文件
          if (_audioFileSink != null) {
            _audioFileSink!.add(dataToWrite);
          }
        },
        onError: (error) async {
          debugPrint('System sound capture error: $error');
          state = state.copyWith(statusMessage: '系统声音捕获错误: $error');
          await _audioFileSink?.close();
          _audioFileSink = null;
        },
        onDone: () async {
          debugPrint('System sound capture done');
          // 关闭写入流并更新文件头
          await _finalizeAudioFile();
        },
      );

      state = state.copyWith(statusMessage: '正在获取系统声音...');
    } catch (e) {
      state = state.copyWith(statusMessage: '开始获取系统声音失败: $e');
      debugPrint('开始获取系统声音错误: $e');
      await _audioFileSink?.close();
      _audioFileSink = null;
    }
  }

  /// 写入 WAV 文件头
  Future<void> _writeWavHeader(IOSink sink) async {
    // WAV 文件头结构
    // 根据调试结果：48000 Hz, 2 声道
    final sampleRate = 48000; // 采样率
    final numChannels = 2; // 声道数
    final bitsPerSample = _outputAsPcm16 ? 16 : 32; // 位深度
    final audioFormat = _outputAsPcm16 ? 1 : 3; // 1 = PCM, 3 = IEEE Float

    // RIFF 标识
    sink.add(ascii.encode('RIFF'));
    // 文件长度（稍后更新）
    sink.add([0, 0, 0, 0]);
    // WAVE 标识
    sink.add(ascii.encode('WAVE'));
    // fmt 标识
    sink.add(ascii.encode('fmt '));
    // 子块大小（PCM 是 16，Float 也是 16）
    sink.add([16, 0, 0, 0]);
    // 音频格式（1 = PCM, 3 = IEEE Float）
    sink.add([audioFormat, 0]);
    // 声道数
    sink.add([numChannels, 0]);
    // 采样率
    sink.add(intToBytes(sampleRate, 4));
    // 字节率
    final byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
    sink.add(intToBytes(byteRate, 4));
    // 块对齐
    final blockAlign = numChannels * bitsPerSample ~/ 8;
    sink.add(intToBytes(blockAlign, 2));
    // 位深度
    sink.add(intToBytes(bitsPerSample, 2));
    // data 标识
    sink.add(ascii.encode('data'));
    // 数据长度（稍后更新）
    sink.add([0, 0, 0, 0]);
  }

  /// 将 IEEE Float 32-bit 转换为 PCM-16
  /// 输入: 32-bit float 字节数组（小端序，立体声）
  /// 输出: 16-bit PCM 字节数组（小端序，立体声）
  List<int> _convertFloatToPcm16(List<int> floatData) {
    // 每个样本 4 字节，2 个声道 = 8 字节一个帧
    final sampleCount = floatData.length ~/ 4;
    final pcmData = <int>[];

    for (int i = 0; i < sampleCount; i++) {
      // 读取 32-bit float（小端序）
      final byte0 = floatData[i * 4];
      final byte1 = floatData[i * 4 + 1];
      final byte2 = floatData[i * 4 + 2];
      final byte3 = floatData[i * 4 + 3];

      // 转换为 IEEE 754 float
      final bits = (byte3 << 24) | (byte2 << 16) | (byte1 << 8) | byte0;
      final floatValue = _ieee754BitsToFloat(bits);

      // 限制在 [-1.0, 1.0] 范围内并转换为 PCM-16
      final clampedValue = floatValue.clamp(-1.0, 1.0);
      final pcmValue = (clampedValue * 32767).toInt();

      // 转换为小端序字节
      pcmData.add(pcmValue & 0xFF);
      pcmData.add((pcmValue >> 8) & 0xFF);
    }

    return pcmData;
  }

  /// 将 IEEE 754 bits 转换为 float 值
  double _ieee754BitsToFloat(int bits) {
    final sign = (bits >> 31) == 1 ? -1.0 : 1.0;
    final exponent = ((bits >> 23) & 0xFF) - 127;
    final mantissa = bits & 0x7FFFFF;

    if (exponent == -127 && mantissa == 0) {
      return 0.0 * sign; // 零
    } else if (exponent == 128) {
      return mantissa == 0 ? double.infinity * sign : double.nan;
    }

    // 使用 pow 来处理负指数
    final significand = 1.0 + mantissa / 0x800000;
    final powerOfTwo = exponent >= 0
        ? (1 << exponent).toDouble()
        : 1.0 / (1 << (-exponent));

    return sign * significand * powerOfTwo;
  }

  /// 更新 WAV 文件头
  Future<void> _updateWavHeader(File file, int dataLength) async {
    // 读取整个文件到内存
    final bytes = await file.readAsBytes();

    // 计算文件长度（从文件开始到数据结束）
    final fileLength = 36 + dataLength;
    final fileLengthBytes = intToBytes(fileLength, 4);
    final dataLengthBytes = intToBytes(dataLength, 4);

    // 更新文件长度（位置 4-7）
    bytes[4] = fileLengthBytes[0];
    bytes[5] = fileLengthBytes[1];
    bytes[6] = fileLengthBytes[2];
    bytes[7] = fileLengthBytes[3];

    // 更新数据长度（位置 40-43）
    bytes[40] = dataLengthBytes[0];
    bytes[41] = dataLengthBytes[1];
    bytes[42] = dataLengthBytes[2];
    bytes[43] = dataLengthBytes[3];

    // 写回整个文件
    await file.writeAsBytes(bytes);
  }

  /// 完成音频文件写入（关闭流并更新文件头）
  Future<void> _finalizeAudioFile() async {
    // 关闭写入流
    await _audioFileSink?.close();
    _audioFileSink = null;

    // 更新 WAV 文件头（设置正确的音频数据长度）
    if (_audioFile != null && _audioDataLength > 0) {
      // 调试：分析音频格式
      _analyzeAudioFormat();

      await _updateWavHeader(_audioFile!, _audioDataLength);
      debugPrint('音频文件已保存: ${_audioFile!.path}, 数据长度: $_audioDataLength 字节');
      state = state.copyWith(statusMessage: '音频文件已保存: ${_audioFile!.path}');
    }
  }

  /// 分析音频格式（调试用）
  void _analyzeAudioFormat() {
    if (_firstChunkTime == null || _audioDataLength == 0) {
      debugPrint('无音频数据可分析');
      return;
    }

    final elapsed = DateTime.now().difference(_firstChunkTime!).inMilliseconds;
    if (elapsed == 0) return;

    final avgBytesPerSec = _audioDataLength * 1000 / elapsed;

    debugPrint('=== 音频格式分析 ===');
    debugPrint('总数据长度: $_audioDataLength 字节');
    debugPrint('录制时长: ${elapsed / 1000} 秒');
    debugPrint('平均字节率: ${avgBytesPerSec.toInt()} bytes/s');

    // 分析可能的格式组合
    debugPrint('\n可能的格式分析：');

    // 16-bit PCM 格式
    final sampleRates = [44100, 48000];
    final channelCounts = [1, 2];

    for (final sampleRate in sampleRates) {
      for (final channels in channelCounts) {
        final bytesPerSample = 2; // 16-bit
        final expectedBytesPerSec = sampleRate * channels * bytesPerSample;
        final diff =
            (avgBytesPerSec - expectedBytesPerSec).abs() / expectedBytesPerSec;

        if (diff < 0.1) {
          debugPrint(
            '✓ 匹配: $sampleRate Hz, $channels 声道, 16-bit PCM '
            '(预期字节率: $expectedBytesPerSec, 实际: ${avgBytesPerSec.toInt()})',
          );
        }
      }
    }

    // 32-bit float 格式
    for (final sampleRate in sampleRates) {
      for (final channels in channelCounts) {
        final bytesPerSample = 4; // 32-bit float
        final expectedBytesPerSec = sampleRate * channels * bytesPerSample;
        final diff =
            (avgBytesPerSec - expectedBytesPerSec).abs() / expectedBytesPerSec;

        if (diff < 0.1) {
          debugPrint(
            '✓ 匹配: $sampleRate Hz, $channels 声道, 32-bit Float '
            '(预期字节率: $expectedBytesPerSec, 实际: ${avgBytesPerSec.toInt()})',
          );
        }
      }
    }

    // 分析首个数据块
    if (_firstChunkSamples != null && _firstChunkSamples!.isNotEmpty) {
      debugPrint('\n首个数据块字节值: $_firstChunkSamples');
      _checkAudioDataType();
    }

    debugPrint('===================');
  }

  /// 检查音频数据类型（16-bit PCM 还是 32-bit Float）
  void _checkAudioDataType() {
    if (_firstChunkSamples == null || _firstChunkSamples!.length < 8) return;

    final samples = _firstChunkSamples!;

    debugPrint('\n数据类型分析（前4个16-bit样本，小端序）：');
    for (int i = 0; i < 8; i += 2) {
      final sample16 = (samples[i + 1] << 8) | samples[i];
      // 转换为有符号整数
      final signedSample = sample16 > 32767 ? sample16 - 65536 : sample16;
      debugPrint(
        '  样本 ${i ~/ 2}: $signedSample (0x${sample16.toRadixString(16).padLeft(4, '0')})',
      );
    }

    debugPrint('\n提示: 如果值都在很小的范围内（如 -1000 到 1000），可能是静音');
    debugPrint('提示: 如果值是随机分布的，说明是有效的音频数据');
    debugPrint('建议: 用十六进制编辑器或音频分析工具检查生成的 a.wav 文件');
  }

  /// 将整数转换为字节数组
  List<int> intToBytes(int value, int length) {
    final bytes = List<int>.filled(length, 0);
    for (int i = 0; i < length; i++) {
      bytes[i] = value & 0xFF;
      value >>= 8;
    }
    return bytes;
  }

  Future<void> stopSystemSound() async {
    try {
      // 取消系统声音捕获订阅
      await systemSoundCaptureStreamSubscription?.cancel();
      systemSoundCaptureStreamSubscription = null;

      // 完成音频文件（关闭流并更新 WAV 文件头）
      await _finalizeAudioFile();

      state = state.copyWith(statusMessage: '系统声音获取已停止');
    } catch (e) {
      debugPrint('停止系统声音错误: $e');
    }
  }

  /// 开始录音和实时翻译
  Future<void> startRecording() async {
    if (state.isProcessing) return;

    state = state.copyWith(
      inputOneText: '',
      translatedOneText: '',
      isProcessing: true,
      statusMessage: '正在录音...',
    );

    try {
      // final success = await _translationService.startStreaming();
      // if (!success) {
      //   state = state.copyWith(isProcessing: false, statusMessage: '开始录音失败');
      // }
    } catch (e) {
      state = state.copyWith(statusMessage: '录音失败: $e', isProcessing: false);
      debugPrint('录音错误: $e');
    }
  }

  /// 停止录音和翻译
  Future<void> stopRecording() async {
    if (!state.isProcessing) return;

    try {
      // await _translationService.stopStreaming();
      state = state.copyWith(isProcessing: false, statusMessage: '录音已停止');
    } catch (e) {
      state = state.copyWith(statusMessage: '停止录音失败: $e');
      debugPrint('停止录音错误: $e');
    }
  }

  /// 切换录音状态
  Future<void> toggleRecording() async {
    if (state.isProcessing) {
      await stopRecording();
    } else {
      await startRecording();
    }
  }

  /// 设置文本布局类型
  /// 1 - 单行文本

  void setOneContentTypes(String srcContentTypes) {
    state = state.copyWith(oneContentTypes: srcContentTypes);
  }

  /// 2 - 多行文本
  void setTwoContentTypes(String twoContentTypes) {
    state = state.copyWith(twoContentTypes: twoContentTypes);
  }

  /// 切换系统声音状态
  void toggleSystemSound() {
    state = state.copyWith(isSystemSoundEnabled: !state.isSystemSoundEnabled);
  }

  void setSrcContentTypes(String srcContentTypes) {
    state = state.copyWith(oneContentTypes: srcContentTypes);
  }

  void setTartgetContentTypes(String tartgetContentTypes) {
    state = state.copyWith(twoContentTypes: tartgetContentTypes);
  }

  void setPanelNumber(int panelNumber) {
    state = state.copyWith(panelNumber: panelNumber);
  }

  void setOnefontSize(double onefontSize) {
    state = state.copyWith(onefontSize: onefontSize);
  }

  void setTwofontSize(double twofontSize) {
    state = state.copyWith(twofontSize: twofontSize);
  }

  /// 设置音频输出格式
  /// true = 16-bit PCM (更通用，文件小)
  /// false = 32-bit Float (高质量，专业格式)
  void setAudioFormat(bool usePcm16) {
    _outputAsPcm16 = usePcm16;
    debugPrint('音频输出格式已设置为: ${usePcm16 ? "16-bit PCM" : "32-bit Float"}');
  }
}
