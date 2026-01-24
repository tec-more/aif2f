import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:aif2f/core/config/app_config.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart' show IOWebSocketChannel;

/// 桌面平台的存根实现 - 不支持录音功能
class TranslationService {
  WebSocketChannel? _channel;
  final _resultController = StreamController<String>.broadcast();
  final _recognizedTextController = StreamController<String>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  bool _isConnected = false;

  // 语言配置字段
  String _sourceLanguage = 'zh';
  String _targetLanguage = 'en';

  // 保存 WebSocket 流订阅，防止被垃圾回收
  StreamSubscription? _wsStreamSubscription;

  // Getters
  Stream<String> get translationStream => _resultController.stream;
  Stream<String> get recognizedTextStream => _recognizedTextController.stream;
  Stream<String> get errorStream => _errorController.stream;
  bool get isRecording => false; // 桌面平台不支持录音
  bool get isConnected => _isConnected;

  /// 连接与初始化 WebSocket
  Future<void> initAndConnect({
    String apiKey = AppConfig.zhipuApiKey,
    String sourceLanguage = 'zh',
    String targetLanguage = 'en',
  }) async {
    try {
      // 科大讯飞 使用 Authorization 请求头进行认证
      final uri = Uri.parse(AppConfig.xFInterpretationUrl);
      debugPrint('WebSocket URL: ${uri.toString()}');

      // 使用 IOWebSocketChannel 以支持自定义请求头
      _channel = IOWebSocketChannel.connect(
        uri,
        headers: {'Authorization': 'Bearer $apiKey'},
      );

      // 保存语言配置供后续使用
      _sourceLanguage = sourceLanguage;
      _targetLanguage = targetLanguage;

      // 开始监听服务器返回
      _listenToServer();

      _isConnected = true;
      debugPrint('WebSocket 连接已建立，等待会话创建...');
    } catch (e) {
      debugPrint('连接失败: $e');
      _errorController.add('连接失败: $e');
      _isConnected = false;
      rethrow;
    }
  }

  /// 生成唯一的事件 ID
  String _generateEventId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'event_${timestamp}';
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

    return '你是一个实时翻译官。如果我说$sourceName，请翻译成$targetName；如果我说$targetName，请翻译成$sourceName。请直接输出翻译结果，不要添加任何解释。';
  }

  /// 开始录音和实时翻译 - 桌面平台不支持
  Future<bool> startStreaming() async {
    debugPrint('录音功能仅在移动平台（iOS/Android）上支持');
    _errorController.add('录音功能仅在移动平台（iOS/Android）上支持');
    return false;
  }

  /// 停止录音和翻译 - 桌面平台不支持
  Future<void> stopStreaming() async {
    debugPrint('录音功能仅在移动平台（iOS/Android）上支持');
  }

  /// 监听服务器消息
  void _listenToServer() {
    _wsStreamSubscription = _channel?.stream.listen(
      (message) {
        try {
          final Map<String, dynamic> event = jsonDecode(message);
          final eventType = event['type'] ?? 'unknown';

          // 处理会话创建成功
          if (eventType == 'session.created') {
            debugPrint('会话创建成功');
          }

          // 处理会话更新成功
          if (eventType == 'session.updated') {
            debugPrint('会话更新成功');
          }

          // 处理翻译文本的增量更新
          if (eventType == 'response.audio_transcript.delta') {
            final delta = event['delta'] ?? '';
            if (delta.isNotEmpty) {
              _resultController.add(delta);
            }
          }

          // 处理响应文本增量
          if (eventType == 'response.text.delta') {
            final delta = event['delta'] ?? '';
            if (delta.isNotEmpty) {
              _resultController.add(delta);
            }
          }

          // 处理识别出的原话
          if (eventType ==
              'conversation.item.input_audio_transcription.completed') {
            final transcript = event['transcript'] ?? '';
            if (transcript.isNotEmpty) {
              _recognizedTextController.add(transcript);
              debugPrint('识别到原话: $transcript');
            }
          }

          // 处理响应文本完成
          if (eventType == 'response.text.done') {
            final text = event['text'] ?? '';
            debugPrint('翻译完成: $text');
          }

          // 处理音频转录完成
          if (eventType == 'response.audio_transcript.done') {
            final transcript = event['transcript'] ?? '';
            debugPrint('音频转录完成: $transcript');
          }

          // 处理错误
          if (eventType == 'error') {
            final error = event['error'] ?? '未知错误';
            debugPrint('服务器错误: $error');
            _errorController.add('服务器错误: $error');
          }

          // 打印心跳事件（调试用）
          if (eventType == 'heartbeat') {
            // 不打印心跳日志，避免日志过多
          }
        } catch (e) {
          debugPrint('解析消息失败: $e');
          debugPrint('原始消息: $message');
        }
      },
      onDone: () {
        debugPrint('WebSocket 连接关闭 (onDone)');
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

  /// 发送文本消息进行翻译
  void sendTextMessage(String text) {
    if (!_isConnected || _channel == null) {
      debugPrint('WebSocket 未连接，无法发送消息');
      _errorController.add('WebSocket 未连接');
      return;
    }

    try {
      final messageEvent = {
        "event_id": _generateEventId(),
        "client_timestamp": DateTime.now().millisecondsSinceEpoch,
        "type": "conversation.item.create",
        "item": {
          "id": _generateEventId(),
          "type": "message",
          "role": "user",
          "content": [
            {"type": "input_text", "text": text},
          ],
        },
      };

      _channel?.sink.add(jsonEncode(messageEvent));
      debugPrint('已发送文本消息: $text');

      // 发送响应创建事件
      final responseEvent = {
        "event_id": _generateEventId(),
        "client_timestamp": DateTime.now().millisecondsSinceEpoch,
        "type": "response.create",
      };

      _channel?.sink.add(jsonEncode(responseEvent));
      debugPrint('已请求创建响应');
    } catch (e) {
      debugPrint('发送消息失败: $e');
      _errorController.add('发送消息失败: $e');
    }
  }

  /// 更新翻译语言
  void updateLanguages(String sourceLanguage, String targetLanguage) {
    _sourceLanguage = sourceLanguage;
    _targetLanguage = targetLanguage;
    debugPrint('已更新语言配置: $sourceLanguage -> $targetLanguage');
  }

  /// 断开连接
  Future<void> disconnect() async {
    await stopStreaming();

    // 取消 WebSocket 流订阅
    await _wsStreamSubscription?.cancel();
    _wsStreamSubscription = null;

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
  }
}
