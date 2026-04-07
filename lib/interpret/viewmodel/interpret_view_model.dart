import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'dart:io'; // 导入文件操作相关的包
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aif2f/interpret/model/interpret_model.dart';
import 'package:aif2f/core/services/server_asr_service.dart';
import 'package:aif2f/data/services/token_storage_service.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_f2f_sound/flutter_f2f_sound.dart';

// 条件日志函数 - 只在调试模式下打印
void _log(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}

// 状态类
@immutable
class InterpretState {
  final TranslationResult? currentTranslation;
  final bool isProcessing;
  final bool isConnected;
  final bool isSystemSoundEnabled;
  final bool isOneTtsEnabled; // 一栏 TTS 播报状态
  final bool isTwoTtsEnabled; // 二栏 TTS 播报状态
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

  final String inputOneTextOld;
  final String translatedOneTextOld;
  final String inputTwoTextOld;
  final String translatedTwoTextOld;

  final String jsonDebug; // 新增：JSON调试信息
  final bool showJsonDebug; // 新增：是否显示JSON调试信息

  final String sourceOneLanguage;
  final String targetOneLanguage;
  final String sourceTwoLanguage;
  final String targetTwoLanguage;
  final String asrServiceType; // 'xfyun' 或 'volcano'

  // final StreamSubscription<List<int>>? systemSoundCaptureStreamSubscription;
  // final int systemSoundDataLength;

  const InterpretState({
    this.currentTranslation,
    this.isProcessing = false,
    this.isConnected = false,
    this.isSystemSoundEnabled = false,
    this.isOneTtsEnabled = false, // 默认关闭一栏 TTS
    this.isTwoTtsEnabled = false, // 默认关闭二栏 TTS
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

    this.inputOneTextOld = '',
    this.translatedOneTextOld = '',
    this.inputTwoTextOld = '',
    this.translatedTwoTextOld = '',

    this.jsonDebug = '', // 默认为空
    this.showJsonDebug = false, // 默认不显示

    this.sourceOneLanguage = '中文',
    this.targetOneLanguage = '英语',
    this.sourceTwoLanguage = '英语',
    this.targetTwoLanguage = '中文',
    this.asrServiceType = 'xfyun', // 默认使用科大讯飞
    // this.systemSoundCaptureStreamSubscription,
    // this.systemSoundDataLength = 0,
  });

  InterpretState copyWith({
    TranslationResult? currentTranslation,
    bool? isProcessing,
    bool? isConnected,
    bool? isSystemSoundEnabled,
    bool? isOneTtsEnabled,
    bool? isTwoTtsEnabled,
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

    String? inputOneTextOld,
    String? translatedOneTextOld,
    String? inputTwoTextOld,
    String? translatedTwoTextOld,

    String? jsonDebug,
    bool? showJsonDebug,

    String? sourceOneLanguage,
    String? targetOneLanguage,
    String? sourceTwoLanguage,
    String? targetTwoLanguage,
    String? asrServiceType,
    // StreamSubscription<List<int>>? systemSoundCaptureStreamSubscription,
    // int? systemSoundDataLength,
  }) {
    return InterpretState(
      currentTranslation: currentTranslation ?? this.currentTranslation,
      isProcessing: isProcessing ?? this.isProcessing,
      isConnected: isConnected ?? this.isConnected,
      isSystemSoundEnabled: isSystemSoundEnabled ?? this.isSystemSoundEnabled,
      isOneTtsEnabled: isOneTtsEnabled ?? this.isOneTtsEnabled,
      isTwoTtsEnabled: isTwoTtsEnabled ?? this.isTwoTtsEnabled,
      onefontSize: onefontSize ?? this.onefontSize,
      twofontSize: twofontSize ?? this.twofontSize,
      panelNumber: panelNumber ?? this.panelNumber,
      oneContentTypes: oneContentTypes ?? this.oneContentTypes,
      twoContentTypes: twoContentTypes ?? this.twoContentTypes,
      statusMessage: statusMessage ?? this.statusMessage,
      inputOneText: inputOneText ?? this.inputOneText,
      translatedOneText: translatedOneText ?? this.translatedOneText,
      inputTwoText: inputTwoText ?? this.inputTwoText,
      translatedTwoText: translatedTwoText ?? this.translatedTwoText,

      inputOneTextOld: inputOneTextOld ?? this.inputOneTextOld,
      translatedOneTextOld: translatedOneTextOld ?? this.translatedOneTextOld,
      inputTwoTextOld: inputTwoTextOld ?? this.inputTwoTextOld,
      translatedTwoTextOld: translatedTwoTextOld ?? this.translatedTwoTextOld,

      jsonDebug: jsonDebug ?? this.jsonDebug,
      showJsonDebug: showJsonDebug ?? this.showJsonDebug,

      sourceOneLanguage: sourceOneLanguage ?? this.sourceOneLanguage,
      targetOneLanguage: targetOneLanguage ?? this.targetOneLanguage,
      sourceTwoLanguage: sourceTwoLanguage ?? this.sourceTwoLanguage,
      targetTwoLanguage: targetTwoLanguage ?? this.targetTwoLanguage,
      asrServiceType: asrServiceType ?? this.asrServiceType,
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
  // 服务器ASR服务（使用豆包同传）
  final ServerAsrService _serverAsrService = ServerAsrService();
  StreamSubscription<List<int>>? systemSoundCaptureStreamSubscription;

  // 音频文件输出流
  IOSink? _audioFileSink;
  // 音频文件
  File? _audioFile;
  // 音频数据长度（用于更新 WAV 文件头）
  int _audioDataLength = 0;
  // 音频输出格式：true = 16-bit PCM, false = 32-bit Float
  bool _outputAsPcm16 = true; // 🔧 改回true，启用PCM转换并应用音量增益
  // 是否启用实时 ASR 识别
  bool _enableRealtimeAsr = true;
  // ASR 连接状态标志
  bool _isAsrConnected = false;
  // 是否在录音完成后自动进行完整 ASR 识别
  bool _enableAutoAsr = false;
  // 调试：音频数据块计数
  int _audioChunkCount = 0;
  // 调试：首次接收时间
  DateTime? _firstChunkTime;
  // 调试：音频数据样本分析
  List<int>? _firstChunkSamples;

  // 🔧 ASR音频缓冲区（用于按固定大小发送）
  final List<int> _asrAudioBuffer = [];
  // 🔧 科大讯飞要求：16kHz单声道，1280字节/40ms
  static const int _asrChunkSize = 1280;
  // 上次发送时间（用于控制发送频率）
  DateTime? _lastAsrSendTime;
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
    // 初始化状态，使用服务器ASR服务
    _log('🎯 ASR服务初始化: 使用服务器API（豆包同传）');

    return InterpretState(asrServiceType: 'server');
  }

  /// 获取当前 ASR 服务
  ServerAsrService _getCurrentAsrService() {
    return _serverAsrService;
  }

  /// 切换 ASR 服务（已废弃，现在只使用服务器API）
  void switchAsrService(String serviceType) {
    _log('⚠️ ASR服务切换已废弃，现在统一使用服务器API（豆包同传）');
    state = state.copyWith(statusMessage: '统一使用服务器API（豆包同传）');
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
    try {
      // 取消之前的订阅（如果有）
      await systemSoundCaptureStreamSubscription?.cancel();
      await _audioFileSink?.close();

      // 取当前时间作为声音文件名称（移除冒号以兼容 Windows）
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '_');
      final fileName = 'system_sound_$timestamp.wav';

      // 文件保存路径为当前程序根目录的 sound 文件目录
      final soundDir = await _getAudioSaveDirectory();
      if (!await soundDir.exists()) {
        await soundDir.create(recursive: true);
      }
      _audioFile = File(path.join(soundDir.path, fileName));
      _audioFileSink = _audioFile!.openWrite();

      _log('音频文件保存路径: ${_audioFile!.path}');

      // 清空之前的识别文本，准备新的识别会话
      state = state.copyWith(inputOneText: '');
      _log('✂️ 已清空之前的识别文本');

      // 写入 WAV 文件头
      // 注意：这里需要根据实际捕获的音频格式调整参数
      await _writeWavHeader(_audioFileSink!);

      // 重置音频数据长度和调试变量
      _audioDataLength = 0;
      _audioChunkCount = 0;
      _firstChunkTime = null;
      _firstChunkSamples = null;

      // 🔧 清空ASR缓冲区（防止上次录音的残留数据）
      _asrAudioBuffer.clear();
      _lastAsrSendTime = null;

      // 连接ASR服务（如果启用实时识别）
      if (_enableRealtimeAsr) {
        final asrService = _getCurrentAsrService();
        final serviceName = '服务器API（豆包同传）';

        // 获取用户认证Token
        final tokenStorage = TokenStorageService();
        final token = await tokenStorage.getToken();

        if (token == null || token.isEmpty) {
          _log('❌ 未找到认证Token，请先登录');
          state = state.copyWith(statusMessage: '请先登录后再使用语音识别');
          return;
        }

        asrService.setAuthToken(token);
        _log('✅ 已设置认证Token');

        // 设置语言配置
        asrService.setLanguageConfig(
          sourceLanguage: state.sourceOneLanguage,
          targetLanguage: state.targetOneLanguage,
          type: 1, // 一栏
        );

        // 添加一个标志来表示翻译是否已经完成
        bool isTranslationComplete = false;

        // 先设置所有回调
        asrService.onTextSrcRecognized = (text, is_final) {
          // 调试日志
          _log(' 📝 原文识别 - is_final: $is_final, text: "$text"');

          // 不再在实时翻译过程中更新UI，只在收到最终结果时更新
          // 这样可以避免实时翻译时显示单独的片段
          // if (!isTranslationComplete) {
          //   // 更新 UI 状态，显示实时原文
          //   state = state.copyWith(inputOneText: text);
          // }
        };

        asrService.onTextDstRecognized = (text, is_final) {
          // 调试日志
          _log(' 📝 译文识别 - is_final: $is_final, text: "$text"');

          // 不再在实时翻译过程中更新UI，只在收到最终结果时更新
          // 这样可以避免实时翻译时显示单独的片段
          // if (!isTranslationComplete) {
          //   // 更新 UI 状态，显示实时译文
          //   state = state.copyWith(translatedOneText: text);
          // }
        };

        // 新增：配对翻译回调（格式化后的原文, 译文）
        asrService.onPairTranslationReceived =
            (formattedSourceText, formattedTargetText) {
              _log('📝 ========== 配对翻译回调已触发 ==========');
              _log('📝 格式化后的累积原文: "$formattedSourceText"');
              _log('📝 格式化后的累积译文: "$formattedTargetText"');
              _log('📝 更新前 - inputOneText: "${state.inputOneText}"');
              _log('📝 更新前 - translatedOneText: "${state.translatedOneText}"');

              // 不要标记翻译已完成，实时翻译过程中需要继续更新
              // isTranslationComplete = true;

              // 将带有特殊分隔符的原文和译文分别设置到对应区域
              // 这样 AutoScrollTranslationView 组件就能正确地将文本分割成句子列表
              state = state.copyWith(
                inputOneText: formattedSourceText,
                translatedOneText: formattedTargetText,
                inputOneTextOld: formattedSourceText,
                translatedOneTextOld: formattedTargetText,
              );

              _log('📝 更新后 - inputOneText: "${state.inputOneText}"');
              _log('📝 更新后 - translatedOneText: "${state.translatedOneText}"');
              _log('✅ 翻译内容已更新到UI');
              _log('📝 =====================================');
            };

        // 新增：JSON调试回调（显示原始JSON）
        asrService.onJsonReceived = (formattedJson) {
          _log('📋 ========== JSON调试信息 ==========');
          _log('📋 JSON内容:');
          _log(formattedJson);
          _log('📋 ===================================');

          // 更新状态，保存JSON（限制长度避免内存溢出）
          final maxLength = 5000; // 最多保留5000字符
          final truncatedJson = formattedJson.length > maxLength
              ? formattedJson.substring(formattedJson.length - maxLength)
              : formattedJson;

          state = state.copyWith(jsonDebug: truncatedJson);
        };

        asrService.onError = (error) {
          _log('$serviceName ASR错误: $error');
          state = state.copyWith(statusMessage: 'ASR错误: $error');
          _isAsrConnected = false; // 标记为未连接
        };
        asrService.onConnected = () {
          _log('✅ $serviceName ASR已连接');
          _isAsrConnected = true; // 标记为已连接
          state = state.copyWith(statusMessage: 'ASR已连接，正在识别...');
        };
        asrService.onDisconnected = () {
          _log('$serviceName ASR已断开');
          _isAsrConnected = false; // 标记为未连接
        };

        // 等待连接成功
        final connected = await asrService.connect();
        if (!connected) {
          _log('❌ $serviceName ASR连接失败');
          state = state.copyWith(statusMessage: 'ASR连接失败，仅保存音频文件');
          _isAsrConnected = false;
        } else {
          _log('✅ $serviceName ASR连接成功');
          _isAsrConnected = true;
        }
      }

      // Get system sound capture stream
      final systemSoundStream = _flutterF2fSound.startSystemSoundCapture();

      _log('=== 开始系统声音捕获调试 ===');

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
            _log('首个数据块前16字节: $_firstChunkSamples');
            _log('首个数据块长度: ${audioData.length} 字节');
          }

          // 每100个数据块打印一次统计信息
          if (_audioChunkCount % 100 == 0) {
            final elapsed = DateTime.now()
                .difference(_firstChunkTime!)
                .inMilliseconds;
            final avgBytesPerSec = elapsed > 0
                ? (_audioDataLength * 1000 / elapsed).toInt()
                : 0;
            _log(
              '[$_audioChunkCount] 数据长度: $_audioDataLength 字节, '
              '平均字节率: $avgBytesPerSec bytes/s, '
              '最后块大小: ${audioData.length} 字节',
            );
          }

          // 处理音频数据
          List<int> dataToWrite = audioData;

          // 🔍 诊断：检查原始音频数据（第1次和第10次）
          if (_audioChunkCount == 0 && audioData.length >= 16) {
            _log('🎵 音频诊断 - 数据块大小:');
            _log('   输入数据: ${audioData.length} 字节');
            _log('   输入帧数: ${audioData.length ~/ 8} 帧');

            final leftBits =
                (audioData[3] << 24) |
                (audioData[2] << 16) |
                (audioData[1] << 8) |
                audioData[0];
            final rightBits =
                (audioData[7] << 24) |
                (audioData[6] << 16) |
                (audioData[5] << 8) |
                audioData[4];
            final leftValue = _ieee754BitsToFloat(leftBits);
            final rightValue = _ieee754BitsToFloat(rightBits);

            _log('🎵 原始音频值 (48kHz Float):');
            _log('   左声道: $leftValue');
            _log('   右声道: $rightValue');
            _log('   混合后: ${(leftValue + rightValue) / 2.0}');
          }

          // 🔍 诊断2：统计音频范围（第10个数据块）
          if (_audioChunkCount == 10) {
            double maxValue = 0.0;
            double minValue = 0.0;
            int sampleCount = 0;
            int zeroCount = 0;

            for (int i = 0; i < audioData.length && i < 4800; i += 8) {
              final leftBits =
                  (audioData[i + 3] << 24) |
                  (audioData[i + 2] << 16) |
                  (audioData[i + 1] << 8) |
                  audioData[i];
              final leftValue = _ieee754BitsToFloat(leftBits);

              final rightBits =
                  (audioData[i + 7] << 24) |
                  (audioData[i + 6] << 16) |
                  (audioData[i + 5] << 8) |
                  audioData[i + 4];
              final rightValue = _ieee754BitsToFloat(rightBits);

              final mixedValue = (leftValue + rightValue) / 2.0;

              if (mixedValue > maxValue) maxValue = mixedValue;
              if (mixedValue < minValue) minValue = mixedValue;
              if (mixedValue.abs() < 0.001) zeroCount++;
              sampleCount++;
            }

            final zeroRatio = zeroCount / sampleCount * 100;

            _log('🎊 音频范围统计 (基于 $sampleCount 个样本):');
            _log('   最大值: $maxValue');
            _log('   最小值: $minValue');
            _log(
              '   峰值幅度: ${maxValue.abs() > minValue.abs() ? maxValue.abs() : minValue.abs()}',
            );
            _log(
              '   静音比例: ${zeroRatio.toStringAsFixed(1)}% ($zeroCount/$sampleCount)',
            );

            if (zeroRatio > 90) {
              _log('   ⚠️ 警告：音频几乎是静音！');
            } else if (maxValue.abs() < 0.01) {
              _log('   ⚠️ 警告：音频幅度太小！');
            } else {
              _log('   ✅ 音频幅度正常');
            }
          }

          // 如果需要转换为 PCM-16
          if (_outputAsPcm16) {
            dataToWrite = _convertFloatToPcm16(audioData);
          }

          _audioDataLength += dataToWrite.length;

          // 保存音频数据到文件
          if (_audioFileSink != null) {
            _audioFileSink!.add(dataToWrite);
          }

          // 🔧 改进：使用缓冲区按固定大小发送到ASR
          if (_enableRealtimeAsr && _isAsrConnected) {
            // 将转换后的数据添加到缓冲区
            _asrAudioBuffer.addAll(dataToWrite);

            // 当缓冲区达到或超过1280字节时，发送数据
            while (_asrAudioBuffer.length >= _asrChunkSize) {
              // 取出1280字节
              final chunkToSend = _asrAudioBuffer.sublist(0, _asrChunkSize);
              // 从缓冲区移除已发送的数据
              _asrAudioBuffer.removeRange(0, _asrChunkSize);

              // 发送到ASR服务（一栏 = 系统声音）
              _getCurrentAsrService().sendAudioData(chunkToSend, type: 1);

              // 🔍 调试：打印发送信息（每50次打印一次）
              // final now = DateTime.now();
              // if (_lastAsrSendTime != null) {
              //   final interval = now
              //       .difference(_lastAsrSendTime!)
              //       .inMilliseconds;
              //   debugPrint('🎤 ASR发送统计:');
              //   debugPrint('   本次发送: ${chunkToSend.length}字节 (目标=1280字节)');
              //   debugPrint('   发送间隔: ${interval}ms (目标=40ms)');
              //   debugPrint('   缓冲区剩余: ${_asrAudioBuffer.length}字节');
              // }
              // _lastAsrSendTime = now;
            }
          } else if (_enableRealtimeAsr && !_isAsrConnected) {
            // 每50次打印一次警告
            if (_audioChunkCount % 50 == 0) {
              _log('⚠️ ASR未连接，跳过音频发送 (chunk #$_audioChunkCount)');
            }
          }
        },
        onError: (error) async {
          _log('System sound capture error: $error');
          state = state.copyWith(statusMessage: '系统声音捕获错误: $error');
          await _audioFileSink?.close();
          _audioFileSink = null;
          if (_enableRealtimeAsr) {
            await _getCurrentAsrService().disconnect();
          }
        },
        onDone: () async {
          _log('System sound capture done');
          if (_enableRealtimeAsr) {
            await _getCurrentAsrService().disconnect();
          }
          // 关闭写入流并更新文件头
          await _finalizeAudioFile();
        },
      );

      state = state.copyWith(statusMessage: '正在获取系统声音...');
    } catch (e) {
      state = state.copyWith(statusMessage: '开始获取系统声音失败: $e');
      _log('开始获取系统声音错误: $e');
      await _audioFileSink?.close();
      _audioFileSink = null;
    }
  }

  /// 写入 WAV 文件头
  Future<void> _writeWavHeader(IOSink sink) async {
    // WAV 文件头结构
    // 🔧 科大讯飞要求：16kHz单声道，不损失质量
    final sampleRate = _outputAsPcm16
        ? 16000
        : 48000; // PCM-16用16kHz，Float保持48kHz
    final numChannels = _outputAsPcm16 ? 1 : 2; // PCM-16用单声道，Float用立体声
    final bitsPerSample = _outputAsPcm16 ? 16 : 32; // 位深度
    final audioFormat = _outputAsPcm16 ? 1 : 3; // 1 = PCM, 3 = IEEE Float

    _log('📝 WAV文件头参数:');
    _log('   采样率: $sampleRate Hz');
    _log('   声道数: $numChannels ${numChannels == 1 ? "(单声道)" : "(立体声)"}');
    _log('   位深度: $bitsPerSample bit');
    _log('   格式: ${audioFormat == 1 ? "PCM" : "IEEE Float"}');

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

  /// 将 IEEE Float 32-bit 转换为 PCM-16（SOXR级品质重采样 + 动态范围控制）
  /// 输入: 32-bit float 字节数组（小端序，立体声，48kHz）
  /// 输出: 16-bit PCM 字节数组（小端序，单声道，16kHz)
  ///
  /// 转换步骤：
  /// 1. 立体声 → 单声道 (功率守恒混合)
  /// 2. 动态电平检测和自适应增益控制
  /// 3. SOXR级品质重采样（48kHz → 16kHz，使用Kaiser窗+多相位滤波）
  /// 4. 软限幅（防止削波失真）
  /// 5. 32-bit Float → 16-bit PCM（带TPDF抖动）
  List<int> _convertFloatToPcm16(List<int> floatData) {
    // 输入格式: 48kHz, 2声道, 32-bit float
    // 每帧 = 2声道 × 4字节 = 8字节
    // 每秒帧数 = 48000

    // 输出格式: 16kHz, 1声道, 16-bit PCM
    // 每帧 = 1声道 × 2字节 = 2字节
    // 每秒帧数 = 16000

    // 🔧 科大讯飞要求：16kHz单声道，不损失质量
    // 🔧 降采样比例: 48kHz / 16kHz = 3
    const downsampleFactor = 3;

    // 计算输入帧数
    final inputFrameCount = floatData.length ~/ 8;

    // 计算输出帧数 (降采样后)
    final outputFrameCount = inputFrameCount ~/ downsampleFactor;

    // 步骤1: 先将立体声转换为单声道并检测峰值
    // 🔧 改进：使用功率守恒的声道混合方式
    // 简单平均 ((L+R)/2) 会导致功率下降 3dB
    // 改进方式：((L+R)/2) * √2 补偿功率损失
    final monoData = <double>[];
    double peakAmplitude = 0.0;
    double rmsSum = 0.0;

    // 功率补偿系数：√2 ≈ 1.414，用于补偿立体声转单声道的3dB功率损失
    const stereoToMonoCompensation = 1.4142135623730951;

    for (int i = 0; i < inputFrameCount; i++) {
      final sampleStartIndex = i * 8;
      if (sampleStartIndex + 7 < floatData.length) {
        // 左声道
        final leftBits =
            (floatData[sampleStartIndex + 3] << 24) |
            (floatData[sampleStartIndex + 2] << 16) |
            (floatData[sampleStartIndex + 1] << 8) |
            floatData[sampleStartIndex];
        final leftValue = _ieee754BitsToFloat(leftBits);

        // 右声道
        final rightBits =
            (floatData[sampleStartIndex + 7] << 24) |
            (floatData[sampleStartIndex + 6] << 16) |
            (floatData[sampleStartIndex + 5] << 8) |
            floatData[sampleStartIndex + 4];
        final rightValue = _ieee754BitsToFloat(rightBits);

        // 🔧 功率守恒的立体声转单声道混合
        final mixedValue =
            (leftValue + rightValue) / 2.0 * stereoToMonoCompensation;

        monoData.add(mixedValue);

        // 统计峰值和RMS
        if (mixedValue.abs() > peakAmplitude) {
          peakAmplitude = mixedValue.abs();
        }
        rmsSum += mixedValue * mixedValue;
      }
    }

    // 计算RMS（均方根）
    final rmsAmplitude = sqrt(rmsSum / monoData.length);

    // 步骤2: 自适应增益控制
    // 🔧 针对弱信号优化：提高最大增益到 20.0，以应对系统声音捕获电平低的情况
    // 目标：使峰值达到 PCM-16 的 90% 量程（0.9），避免削波
    // 同时考虑 RMS 电平，避免过度放大噪音
    const targetPeak = 0.9; // 目标峰值（留10%余量）
    const minGain = 1.0; // 最小增益（不衰减）
    const maxGain = 20.0; // 最大增益（提高到20x以应对弱信号）

    double adaptiveGain;
    if (peakAmplitude > 0.001) {
      // 基于峰值的自适应增益
      final peakBasedGain = targetPeak / peakAmplitude;

      // 基于RMS的增益调整（防止过度放大噪音）
      // 🔧 对于极弱信号（RMS < 0.005），放宽RMS限制
      final rmsBasedGain = rmsAmplitude > 0.005 ? 0.5 / rmsAmplitude : maxGain;

      // 组合增益（取较小值，优先防止削波）
      adaptiveGain = min(peakBasedGain, rmsBasedGain).clamp(minGain, maxGain);

      // 🔍 调试：打印增益信息（每50次打印一次）
      if (_audioChunkCount % 50 == 0) {
        _log('🎚️ 自适应增益控制:');
        _log('   峰值: $peakAmplitude');
        _log('   RMS: $rmsAmplitude');
        _log('   应用增益: $adaptiveGain');
        _log(
          '   信号强度评估: ${peakAmplitude < 0.01
              ? "弱"
              : peakAmplitude < 0.05
              ? "中等"
              : "强"}',
        );
      }
    } else {
      adaptiveGain = 1.0;
    }

    // 步骤3: 快速线性插值重采样（48kHz → 16kHz）
    // 使用简单线性插值替代SOXR级算法，性能提升约10倍
    final resampledData = _fastResample(monoData, downsampleFactor);

    final pcmData = <int>[];

    // 🔍 诊断1：检查第一个样本的值（仅第一次）
    if (_firstChunkSamples == null && floatData.length >= 16) {
      _log('🎵 音频诊断 - 快速线性插值重采样:');
      _log('   输入数据: ${floatData.length} 字节');
      _log('   输入帧数: $inputFrameCount 帧');
      _log('   输出帧数: $outputFrameCount 帧');
      _log('   重采样比例: 1:$downsampleFactor');
      _log('   方法: 简单抽取（性能优化版）');
      _log('   自适应增益: $adaptiveGain');

      final leftBits =
          (floatData[3] << 24) |
          (floatData[2] << 16) |
          (floatData[1] << 8) |
          floatData[0];
      final rightBits =
          (floatData[7] << 24) |
          (floatData[6] << 16) |
          (floatData[5] << 8) |
          floatData[4];
      final leftValue = _ieee754BitsToFloat(leftBits);
      final rightValue = _ieee754BitsToFloat(rightBits);

      _log('🎵 原始音频值:');
      _log('   左声道: $leftValue');
      _log('   右声道: $rightValue');
      _log(
        '   混合后: ${(leftValue + rightValue) / 2.0 * stereoToMonoCompensation}',
      );
      _log('   峰值: $peakAmplitude');
      _log('   RMS: $rmsAmplitude');
      _log('   重采样后: ${resampledData.isNotEmpty ? resampledData[0] : 0.0}');
    }

    // 🔍 诊断2：统计音频范围（第10个数据块）
    if (_audioChunkCount == 10) {
      double maxValue = 0.0;
      double minValue = 0.0;
      int sampleCount = 0;
      int zeroCount = 0;

      for (int i = 0; i < monoData.length && i < 600; i++) {
        final mixedValue = monoData[i];
        if (mixedValue > maxValue) maxValue = mixedValue;
        if (mixedValue < minValue) minValue = mixedValue;
        if (mixedValue.abs() < 0.001) zeroCount++;
        sampleCount++;
      }

      final zeroRatio = zeroCount / sampleCount * 100;

      _log('🎊 音频范围统计 (基于 $sampleCount 个样本):');
      _log('   最大值: $maxValue');
      _log('   最小值: $minValue');
      _log('   峰值幅度: $peakAmplitude');
      _log('   RMS: $rmsAmplitude');
      _log(
        '   静音比例: ${zeroRatio.toStringAsFixed(1)}% ($zeroCount/$sampleCount)',
      );
      _log('   自适应增益: $adaptiveGain');

      if (zeroRatio > 90) {
        _log('   ⚠️ 警告：音频几乎是静音！');
      } else if (peakAmplitude < 0.01) {
        _log('   ⚠️ 警告：音频幅度太小！');
      } else {
        _log('   ✅ 音频幅度正常');
      }
    }

    // 预计算软限幅函数的参数
    // 使用双曲正切函数实现软限幅，避免硬削波
    final softLimitKnee = 0.8; // 软限幅起点
    final random = Random(42); // 固定种子的随机数生成器，用于抖动

    // 步骤4-5: 应用自适应增益、软限幅并转换为 PCM-16
    for (int i = 0; i < resampledData.length; i++) {
      final resampledValue = resampledData[i];

      // 应用自适应增益
      final amplifiedValue = resampledValue * adaptiveGain;

      // 软限幅（避免削波失真）
      // 使用 tanh 函数实现平滑的软限幅
      final softLimitedValue = amplifiedValue.abs() <= softLimitKnee
          ? amplifiedValue // 线性区
          : (amplifiedValue.sign *
                (softLimitKnee +
                    (1.0 - softLimitKnee) *
                        _tanh(
                          (amplifiedValue.abs() - softLimitKnee) /
                              (1.0 - softLimitKnee),
                        )));

      // 转换为 PCM-16（带TPDF抖动，减少量化误差）
      final dither = (random.nextDouble() - random.nextDouble()) / 32767.0;
      final ditheredValue = softLimitedValue + dither;

      final clampedValue = ditheredValue.clamp(-1.0, 1.0);
      final pcmValue = (clampedValue * 32767).round();

      // 转换为小端序字节
      pcmData.add(pcmValue & 0xFF);
      pcmData.add((pcmValue >> 8) & 0xFF);
    }

    return pcmData;
  }

  /// 双曲正切函数（用于软限幅）
  /// tanh(x) = (e^x - e^(-x)) / (e^x + e^(-x))
  double _tanh(double x) {
    if (x > 10) return 1.0; // 避免溢出
    if (x < -10) return -1.0;
    final expX = exp(x);
    final expNegX = exp(-x);
    return (expX - expNegX) / (expX + expNegX);
  }

  /// 快速线性插值重采样（48kHz → 16kHz）
  /// 使用简单线性插值，性能提升约10倍，质量略降但对语音识别影响很小
  ///
  /// 参数：
  /// - inputData: 输入音频数据（单声道，48kHz）
  /// - downsampleFactor: 降采样因子（3 表示 48kHz → 16kHz）
  ///
  /// 返回：重采样后的音频数据（16kHz）
  List<double> _fastResample(List<double> inputData, int downsampleFactor) {
    final outputLength = inputData.length ~/ downsampleFactor;
    final outputData = <double>[];

    for (int i = 0; i < outputLength; i++) {
      final inputPos = i * downsampleFactor;

      // 简单抽取（直接取第1、4、7、10...个样本）
      // 对于48kHz → 16kHz的3:1降采样，这已经足够
      outputData.add(inputData[inputPos]);
    }

    return outputData;
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
      _log('音频文件已保存: ${_audioFile!.path}, 数据长度: $_audioDataLength 字节');
      state = state.copyWith(statusMessage: '音频文件已保存: ${_audioFile!.path}');

      // 如果启用了自动ASR，进行语音识别
      if (_enableAutoAsr) {
        await _performAsrRecognition(_audioFile!.path);
      }
    }
  }

  /// 分析音频格式（调试用）
  void _analyzeAudioFormat() {
    if (_firstChunkTime == null || _audioDataLength == 0) {
      _log('无音频数据可分析');
      return;
    }

    final elapsed = DateTime.now().difference(_firstChunkTime!).inMilliseconds;
    if (elapsed == 0) return;

    final avgBytesPerSec = _audioDataLength * 1000 / elapsed;

    _log('=== 音频格式分析 ===');
    _log('总数据长度: $_audioDataLength 字节');
    _log('录制时长: ${elapsed / 1000} 秒');
    _log('平均字节率: ${avgBytesPerSec.toInt()} bytes/s');

    // 分析可能的格式组合
    _log('\n可能的格式分析：');

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
          _log(
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
          _log(
            '✓ 匹配: $sampleRate Hz, $channels 声道, 32-bit Float '
            '(预期字节率: $expectedBytesPerSec, 实际: ${avgBytesPerSec.toInt()})',
          );
        }
      }
    }

    // 分析首个数据块
    if (_firstChunkSamples != null && _firstChunkSamples!.isNotEmpty) {
      _log('\n首个数据块字节值: $_firstChunkSamples');
      _checkAudioDataType();
    }

    _log('===================');
  }

  /// 检查音频数据类型（16-bit PCM 还是 32-bit Float）
  void _checkAudioDataType() {
    if (_firstChunkSamples == null || _firstChunkSamples!.length < 8) return;

    final samples = _firstChunkSamples!;

    _log('\n数据类型分析（前4个16-bit样本，小端序）：');
    for (int i = 0; i < 8; i += 2) {
      final sample16 = (samples[i + 1] << 8) | samples[i];
      // 转换为有符号整数
      final signedSample = sample16 > 32767 ? sample16 - 65536 : sample16;
      _log(
        '  样本 ${i ~/ 2}: $signedSample (0x${sample16.toRadixString(16).padLeft(4, '0')})',
      );
    }

    _log('\n提示: 如果值都在很小的范围内（如 -1000 到 1000），可能是静音');
    _log('提示: 如果值是随机分布的，说明是有效的音频数据');
    _log('建议: 用十六进制编辑器或音频分析工具检查生成的 a.wav 文件');
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
      // 🔧 发送缓冲区剩余的音频数据
      if (_enableRealtimeAsr && _isAsrConnected && _asrAudioBuffer.isNotEmpty) {
        _log('🎤 发送剩余缓冲数据: ${_asrAudioBuffer.length}字节');
        _getCurrentAsrService().sendAudioData(
          List.from(_asrAudioBuffer),
          type: 1,
        );
        _asrAudioBuffer.clear();
      }

      // 断开ASR连接
      if (_enableRealtimeAsr) {
        await _getCurrentAsrService().disconnect();
      }

      // 取消系统声音捕获订阅
      await systemSoundCaptureStreamSubscription?.cancel();
      systemSoundCaptureStreamSubscription = null;

      // 完成音频文件（关闭流并更新 WAV 文件头）
      await _finalizeAudioFile();

      state = state.copyWith(statusMessage: '系统声音获取已停止');
    } catch (e) {
      _log('停止系统声音错误: $e');
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
      _log('录音错误: $e');
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
      _log('停止录音错误: $e');
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

  /// 切换一栏 TTS 播报状态
  void toggleOneTts() {
    final newState = !state.isOneTtsEnabled;
    state = state.copyWith(isOneTtsEnabled: newState);

    _log('🎚️ 切换一栏 TTS: $newState');
    _log('   一栏 TTS: $newState');
    _log('   二栏 TTS: ${state.isTwoTtsEnabled}');

    if (newState) {
      _getCurrentAsrService().enableTts(type: 1); // 一栏 TTS
      _log('✅ 一栏 TTS 播报已启用');
    } else {
      _getCurrentAsrService().disableTts(type: 1); // 一栏 TTS
      _log('⏸️ 一栏 TTS 播报已禁用');
    }
  }

  /// 切换二栏 TTS 播报状态
  void toggleTwoTts() {
    final newState = !state.isTwoTtsEnabled;
    state = state.copyWith(isTwoTtsEnabled: newState);

    _log('🎚️ 切换二栏 TTS: $newState');
    _log('   一栏 TTS: ${state.isOneTtsEnabled}');
    _log('   二栏 TTS: $newState');

    if (newState) {
      _getCurrentAsrService().enableTts(type: 2); // 二栏 TTS
      _log('✅ 二栏 TTS 播报已启用');
    } else {
      _getCurrentAsrService().disableTts(type: 2); // 二栏 TTS
      _log('⏸️ 二栏 TTS 播报已禁用');
    }
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
    _log('音频输出格式已设置为: ${usePcm16 ? "16-bit PCM" : "32-bit Float"}');
  }

  /// 获取音频文件保存目录（跨平台）
  Future<Directory> _getAudioSaveDirectory() async {
    // 所有平台统一使用应用程序当前目录下的 sounds 文件夹
    return Directory(path.join(Directory.current.path, 'sounds'));
  }

  /// 执行 ASR 语音识别
  Future<void> _performAsrRecognition(String audioFilePath) async {
    _log('开始 ASR 识别: $audioFilePath');
    state = state.copyWith(statusMessage: '正在识别语音...');
  }

  /// 语言名称转换为语言代码
  String _getLanguageCode(String language) {
    return _languageCodeMap[language] ?? 'zh';
  }

  /// 设置是否启用自动 ASR
  void setAutoAsrEnabled(bool enabled) {
    _enableAutoAsr = enabled;
    _log('自动ASR已${enabled ? "启用" : "禁用"}');
  }

  /// 设置是否启用实时ASR（分段识别）
  void setRealtimeAsrEnabled(bool enabled) {
    _enableRealtimeAsr = enabled;
    _log('实时ASR已${enabled ? "启用" : "禁用"}');
  }

  /// 清除已识别的文本
  void clearRecognizedText() {
    state = state.copyWith(inputOneText: '');
    _log('已清除识别文本');
  }

  /// 检查 ASR 是否已连接
  bool isAsrConnected() {
    return _isAsrConnected;
  }

  /// 获取 ASR 连接状态描述
  String getAsrConnectionStatus() {
    if (!_enableRealtimeAsr) {
      return 'ASR 未启用';
    }
    if (_isAsrConnected) {
      return 'ASR 已连接';
    }
    return 'ASR 未连接';
  }

  /// 切换JSON调试信息显示
  void toggleJsonDebug() {
    final newState = !state.showJsonDebug;
    state = state.copyWith(showJsonDebug: newState);
    _log('📋 JSON调试信息显示: ${newState ? "开启" : "关闭"}');
  }

  /// 清空JSON调试信息
  void clearJsonDebug() {
    state = state.copyWith(jsonDebug: '');
    _log('📋 已清空JSON调试信息');
  }
}
