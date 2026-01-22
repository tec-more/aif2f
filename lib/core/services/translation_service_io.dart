import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:aif2f/core/config/app_config.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart' show IOWebSocketChannel;

/// IO平台实现 (Android, iOS, macOS, Linux, Windows)
/// 注意：flutter_sound, path_provider, permission_handler 已从 pubspec.yaml 中移除
/// 以支持 Windows 构建
/// 在移动平台上，录音功能不可用，仅支持文本翻译
class TranslationService {
  WebSocketChannel? _channel;
  final _resultController = StreamController<String>.broadcast();
  final _recognizedTextController = StreamController<String>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  bool _isRecording = false;
  bool _isConnected = false;

  // 语言配置字段
  String _sourceOneLanguage = 'zh';
  String _targetOneLanguage = 'en';
  // 语言配置字段
  String _sourceTwoLanguage = 'zh';
  String _targetTwoLanguage = 'en';

  // 保存 WebSocket 流订阅，防止被垃圾回收
  StreamSubscription? _wsStreamSubscription;

  // Getters
  Stream<String> get translationStream => _resultController.stream;
  Stream<String> get recognizedTextStream => _recognizedTextController.stream;
  Stream<String> get errorStream => _errorController.stream;
  bool get isRecording => _isRecording;
  bool get isConnected => _isConnected;

  /// 检查是否支持录音
  bool get _supportsRecording => Platform.isAndroid || Platform.isIOS;

  /// 连接与初始化 WebSocket
  Future<void> initAndConnect({
    String apiKey = AppConfig.zhipuApiKey,
    String sourceLanguage = 'zh',
    String targetLanguage = 'en',
  }) async {
    try {
      final uri = Uri.parse(AppConfig.zhipuSockBaseUrl);
      debugPrint('WebSocket URL: ${uri.toString()}');

      _channel = IOWebSocketChannel.connect(
        uri,
        headers: {'Authorization': 'Bearer $apiKey'},
      );

      _sourceOneLanguage = sourceLanguage;
      _targetOneLanguage = targetLanguage;

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

  /// 开始录音和实时翻译
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

    if (!_supportsRecording) {
      debugPrint('录音功能仅在移动平台（iOS/Android）上支持');
      _errorController.add('录音功能仅在移动平台（iOS/Android）上支持');
      return false;
    }

    // 注意：由于 flutter_sound 已被移除，录音功能暂时不可用
    debugPrint('录音功能当前不可用（依赖已从 Windows 构建中移除）');
    _errorController.add('录音功能当前不可用');
    return false;
  }

  /// 停止录音和翻译
  Future<void> stopStreaming() async {
    if (!_isRecording) return;
    _isRecording = false;
    debugPrint('停止录音');
  }

  /// 监听服务器消息
  void _listenToServer() {
    _wsStreamSubscription = _channel?.stream.listen(
      (message) {
        try {
          final Map<String, dynamic> event = jsonDecode(message);
          final eventType = event['type'] ?? 'unknown';

          if (eventType == 'session.created') {
            debugPrint('会话创建成功');
          }

          if (eventType == 'session.updated') {
            debugPrint('会话更新成功');
          }

          if (eventType == 'response.audio_transcript.delta') {
            final delta = event['delta'] ?? '';
            if (delta.isNotEmpty) {
              _resultController.add(delta);
            }
          }

          if (eventType == 'response.text.delta') {
            final delta = event['delta'] ?? '';
            if (delta.isNotEmpty) {
              _resultController.add(delta);
            }
          }

          if (eventType ==
              'conversation.item.input_audio_transcription.completed') {
            final transcript = event['transcript'] ?? '';
            if (transcript.isNotEmpty) {
              _recognizedTextController.add(transcript);
              debugPrint('识别到原话: $transcript');
            }
          }

          if (eventType == 'response.text.done') {
            final text = event['text'] ?? '';
            debugPrint('翻译完成: $text');
          }

          if (eventType == 'response.audio_transcript.done') {
            final transcript = event['transcript'] ?? '';
            debugPrint('音频转录完成: $transcript');
          }

          if (eventType == 'error') {
            final error = event['error'] ?? '未知错误';
            debugPrint('服务器错误: $error');
            _errorController.add('服务器错误: $error');
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
  void updateLanguages(String sourceLanguage, String targetLanguage, int type) {
    _sourceOneLanguage = sourceLanguage;
    _targetOneLanguage = targetLanguage;
    debugPrint('已更新语言配置: $sourceLanguage -> $targetLanguage');
  }

  /// 断开连接
  Future<void> disconnect() async {
    await stopStreaming();

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
