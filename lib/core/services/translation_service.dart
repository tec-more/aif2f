import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:aif2f/core/config/app_config.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class TranslationService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  WebSocketChannel? _channel;
  final _resultController = StreamController<String>.broadcast();
  final _recognizedTextController = StreamController<String>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  bool _isRecording = false;
  bool _isConnected = false;

  // 保存音频流订阅，用于取消
  StreamSubscription<Uint8List>? _audioStreamSubscription;

  // Getters
  Stream<String> get translationStream => _resultController.stream;
  Stream<String> get recognizedTextStream => _recognizedTextController.stream;
  Stream<String> get errorStream => _errorController.stream;
  bool get isRecording => _isRecording;
  bool get isConnected => _isConnected;

  /// 连接与初始化 WebSocket
  Future<void> initAndConnect({
    String apiKey = AppConfig.zhipuApiKey,
    String sourceLanguage = 'zh',
    String targetLanguage = 'en',
  }) async {
    try {
      final uri = Uri.parse(AppConfig.zhipuSockBaseUrl);
      _channel = WebSocketChannel.connect(uri);
      _isConnected = true;

      // 根据语言生成提示词
      String instructions = _generateInstructions(sourceLanguage, targetLanguage);

      // 发送初始化 Session 配置
      final sessionUpdate = {
        "type": "session.update",
        "session": {
          "modalities": ["text"],
          "instructions": instructions,
          "input_audio_format": "pcm16",
          "input_audio_transcription": {"model": "whisper-1"},
        },
      };

      _channel?.sink.add(jsonEncode(sessionUpdate));
      debugPrint('WebSocket 已连接，语言配置: $sourceLanguage -> $targetLanguage');

      // 开始监听服务器返回
      _listenToServer();
    } catch (e) {
      debugPrint('连接失败: $e');
      _errorController.add('连接失败: $e');
      _isConnected = false;
      rethrow;
    }
  }

  /// 生成翻译指令
  String _generateInstructions(String sourceLang, String targetLang) {
    final langNames = {
      'zh': '中文',
      'en': '英语',
      'ja': '日语',
      'ko': '韩语',
      'fr': '法语',
      'de': '德语',
      'es': '西班牙语',
      'ru': '俄语',
    };

    final sourceName = langNames[sourceLang] ?? sourceLang;
    final targetName = langNames[targetLang] ?? targetLang;

    return '你是一个实时翻译官。如果我说${sourceName}，请翻译成${targetName}；如果我说${targetName}，请翻译成${sourceName}。请直接输出翻译结果，不要添加任何解释。';
  }

  /// 开始录音和翻译
  Future<bool> startStreaming() async {
    if (_isRecording) {
      debugPrint('已经在录音中');
      return false;
    }

    if (!_isConnected) {
      debugPrint('WebSocket 未连接');
      _errorController.add('WebSocket 未连接，请先调用 initAndConnect()');
      return false;
    }

    try {
      // 检查权限
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        debugPrint('没有录音权限');
        _errorController.add('没有录音权限');
        return false;
      }

      const config = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      );

      // 获取二进制流
      final stream = await _audioRecorder.startStream(config);
      _isRecording = true;
      debugPrint('开始录音和实时翻译');

      // 监听音频流并发送到服务器
      _audioStreamSubscription = stream.listen(
        (data) {
          if (_channel != null) {
            final audioEvent = {
              "type": "input_audio_buffer.append",
              "audio": base64Encode(data),
            };
            _channel?.sink.add(jsonEncode(audioEvent));
          }
        },
        onError: (e) {
          debugPrint('音频流错误: $e');
          _errorController.add('音频流错误: $e');
        },
        onDone: () {
          debugPrint('音频流结束');
          _isRecording = false;
        },
        cancelOnError: false, // 不在错误时自动取消订阅
      );

      return true;
    } catch (e) {
      debugPrint('开始录音失败: $e');
      _errorController.add('开始录音失败: $e');
      _isRecording = false;
      return false;
    }
  }

  /// 停止录音和翻译
  Future<void> stopStreaming() async {
    if (!_isRecording) return;

    try {
      // 取消音频流订阅
      await _audioStreamSubscription?.cancel();
      _audioStreamSubscription = null;

      await _audioRecorder.stop();
      _isRecording = false;
      debugPrint('停止录音');

      // 发送结束事件
      if (_channel != null) {
        final endEvent = {
          "type": "input_audio_buffer.append",
          "audio": "",
        };
        _channel?.sink.add(jsonEncode(endEvent));
      }
    } catch (e) {
      debugPrint('停止录音失败: $e');
      _errorController.add('停止录音失败: $e');
    }
  }

  /// 监听服务器消息
  void _listenToServer() {
    _channel?.stream.listen(
      (message) {
        try {
          final Map<String, dynamic> event = jsonDecode(message);

          // 处理翻译文本的增量更新
          if (event['type'] == 'response.audio_transcript.delta') {
            final delta = event['delta'] ?? '';
            if (delta.isNotEmpty) {
              _resultController.add(delta);
              debugPrint('翻译增量: $delta');
            }
          }

          // 处理识别出的原话
          if (event['type'] ==
              'conversation.item.input_audio_transcription.completed') {
            final transcript = event['transcript'] ?? '';
            if (transcript.isNotEmpty) {
              _recognizedTextController.add(transcript);
              debugPrint('识别到原话: $transcript');
            }
          }

          // 处理错误
          if (event['type'] == 'error') {
            final error = event['error'] ?? '未知错误';
            debugPrint('服务器错误: $error');
            _errorController.add('服务器错误: $error');
          }
        } catch (e) {
          debugPrint('解析消息失败: $e');
        }
      },
      onDone: () {
        debugPrint('WebSocket 连接关闭');
        _isConnected = false;
        _errorController.add('连接已关闭');
      },
      onError: (e) {
        debugPrint('WebSocket 错误: $e');
        _errorController.add('WebSocket 错误: $e');
        _isConnected = false;
      },
    );
  }

  /// 更新翻译语言
  void updateLanguages(String sourceLanguage, String targetLanguage) {
    if (_isConnected && _channel != null) {
      final instructions = _generateInstructions(sourceLanguage, targetLanguage);
      final sessionUpdate = {
        "type": "session.update",
        "session": {
          "instructions": instructions,
        },
      };
      _channel?.sink.add(jsonEncode(sessionUpdate));
      debugPrint('已更新语言配置: $sourceLanguage -> $targetLanguage');
    }
  }

  /// 断开连接
  Future<void> disconnect() async {
    await stopStreaming();
    await _channel?.sink.close();
    _channel = null;

    await _resultController.close();
    await _recognizedTextController.close();
    await _errorController.close();
    _isConnected = false;
    debugPrint('已断开连接');
  }

  /// 释放资源
  Future<void> dispose() async {
    await disconnect();
    await _audioRecorder.dispose();
  }
}
