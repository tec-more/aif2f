import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:aif2f/core/config/app_config.dart';
import 'package:aif2f/core/services/api_key_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

/// 服务器ASR服务（WebSocket版本）
/// 使用WebSocket实时传输音频进行语音识别和翻译
class ServerAsrService {
  // 识别结果回调
  Function(String, int)? onTextSrcRecognized; // (text, is_final) 原文识别回调
  Function(String, int)? onTextDstRecognized; // (text, is_final) 译文识别回调
  Function(String, String)? onPairTranslationReceived; // 新增：配对翻译回调（格式化后的原文, 译文）
  Function(String)? onJsonReceived; // 新增：原始JSON回调（格式化的JSON字符串）
  Function(String)? onError;
  Function()? onConnected;
  Function()? onDisconnected;
  Function(Uint8List)? onTtsAudioReceived;

  // 语言配置
  String? _sourceLanguage;
  String? _targetLanguage;
  int? _type; // 1=一栏, 2=二栏

  // 状态
  bool _isConnected = false;
  String? _userAuthToken; // 用户的JWT Token
  int? _providerId; // 大模型提供商ID
  String? _sessionId;

  // 翻译历史（用于配对显示）
  final List<MapEntry<String, String>> _translationHistory = [];
  final Map<int, String> _sourceBuffer =
      {}; // 暂存原文，等待译文配对（segment_index -> text）
  final Map<int, String> _targetBuffer =
      {}; // 暂存译文，等待原文配对（segment_index -> text）
  String? _lastSourceText; // 最后收到的原文（等待配对译文）

  // WebSocket通道
  WebSocketChannel? _wsChannel;
  StreamSubscription? _wsSubscription;

  // API密钥服务
  final ApiKeyService _apiKeyService = ApiKeyService();

  // 音频发送控制
  bool _isSendingAudio = false;
  final List<int> _audioBuffer = [];
  Timer? _sendTimer;

  bool get isConnected => _isConnected;

  /// 设置用户认证Token
  void setAuthToken(String token) {
    _userAuthToken = token;
    _apiKeyService.setAuthToken(token);
    debugPrint('ServerAsrService: 已设置用户认证Token');
  }

  /// 设置语言配置
  void setLanguageConfig({
    required String sourceLanguage,
    required String targetLanguage,
    required int type,
  }) {
    _sourceLanguage = sourceLanguage;
    _targetLanguage = targetLanguage;
    _type = type;
    debugPrint(
      'ServerAsrService: 语言配置已更新 - $sourceLanguage -> $targetLanguage (type: $type)',
    );
  }

  /// 连接到WebSocket服务器
  Future<bool> connect() async {
    try {
      if (_userAuthToken == null || _userAuthToken!.isEmpty) {
        onError?.call('未设置认证Token');
        return false;
      }

      // 获取同声传译类型的API密钥（只需要provider_id）
      final apiKey = await _apiKeyService.getSimultaneousInterpretationKey();

      if (apiKey == null) {
        onError?.call('未找到同声传译类型的API密钥，请在后台配置');
        return false;
      }

      _providerId = apiKey.providerId;

      if (_providerId == null) {
        onError?.call('API密钥缺少provider_id');
        return false;
      }

      debugPrint('ServerAsrService: 找到同声传译密钥，ProviderID: $_providerId');

      // 构建WebSocket URL（使用专门的WebSocket路径方法）
      final apiPath = AppConfig.getWebSocketPath(
        '/llm/voice/translation/streaming/v3',
      );
      final wsScheme = AppConfig.apiBaseUrl.startsWith('https') ? 'wss' : 'ws';

      debugPrint('ServerAsrService: 🔍 URL构建调试');
      debugPrint('ServerAsrService:  - apiBaseUrl: ${AppConfig.apiBaseUrl}');
      debugPrint('ServerAsrService:  - apiVersion: ${AppConfig.apiVersion}');
      debugPrint('ServerAsrService:  - 原始API路径: $apiPath');
      debugPrint('ServerAsrService:  - WebSocket协议: $wsScheme');

      // 解析原始URL
      final originalUri = Uri.parse(apiPath);

      // 🔧 关键修复：直接构建字符串URL，避免Uri对象在Windows平台的问题
      final wsUrlString =
          '$wsScheme://${originalUri.host}:${originalUri.port}${originalUri.path}?provider_id=${_providerId.toString()}&token=${_userAuthToken!}';

      debugPrint('ServerAsrService: 📡 最终WebSocket URL:');
      debugPrint('ServerAsrService:  - URL字符串: $wsUrlString');

      // 建立WebSocket连接
      try {
        // 直接使用IOWebSocketChannel，传入字符串而不是Uri对象
        final socket = await WebSocket.connect(wsUrlString);
        _wsChannel = IOWebSocketChannel(socket);
      } catch (e) {
        debugPrint('ServerAsrService: WebSocket连接失败 - $e');
        rethrow;
      }

      // 监听服务器消息
      _wsSubscription = _wsChannel!.stream.listen(
        _handleServerMessage,
        onError: (error) {
          debugPrint('ServerAsrService: WebSocket错误 - $error');
          onError?.call('WebSocket错误: $error');
          _cleanup();
        },
        onDone: () {
          debugPrint('ServerAsrService: WebSocket连接已关闭');
          _cleanup();
        },
        cancelOnError: false,
      );

      // 等待连接建立
      await Future.delayed(const Duration(milliseconds: 500));

      _isConnected = true;
      debugPrint('ServerAsrService: WebSocket已连接');

      // 自动发送start消息
      await _sendStartMessage();

      return true;
    } catch (e) {
      debugPrint('ServerAsrService: 连接失败 - $e');
      onError?.call('连接失败: $e');
      return false;
    }
  }

  /// 开始发送音频（发送start消息）
  Future<void> startSendingAudio() async {
    await _sendStartMessage();
  }

  /// 发送start消息（私有方法）
  Future<void> _sendStartMessage() async {
    if (!_isConnected || _wsChannel == null) {
      debugPrint('ServerAsrService: 未连接，无法发送start消息');
      return;
    }

    if (_isSendingAudio) {
      debugPrint('ServerAsrService: 已经在发送音频中，跳过start消息');
      return;
    }

    try {
      final sourceLangCode = _getLanguageCode(_sourceLanguage ?? 'zh');
      final targetLangCode = _getLanguageCode(_targetLanguage ?? 'en');

      final startMessage = jsonEncode({
        'type': 'start',
        'format': 'wav',
        'sample_rate': 16000,
        'source_language': sourceLangCode,
        'target_language': targetLangCode,
      });

      debugPrint(
        'ServerAsrService: ===================== 发送start消息 =====================',
      );
      debugPrint('ServerAsrService: 📋 语言配置:');
      debugPrint('ServerAsrService:  - 源语言（原始）: $_sourceLanguage');
      debugPrint('ServerAsrService:  - 目标语言（原始）: $_targetLanguage');
      debugPrint('ServerAsrService:  - 源语言代码: $sourceLangCode');
      debugPrint('ServerAsrService:  - 目标语言代码: $targetLangCode');
      debugPrint('ServerAsrService: 📤 Start消息内容:');
      debugPrint('ServerAsrService:  $startMessage');
      debugPrint(
        'ServerAsrService: =================================================',
      );

      _wsChannel!.sink.add(startMessage);

      _isSendingAudio = true;
      _audioBuffer.clear();

      // 启动定时发送任务（每100ms发送一次音频块）
      _startSendTimer();
    } catch (e) {
      debugPrint('ServerAsrService: 发送start消息失败 - $e');
      onError?.call('发送start消息失败: $e');
    }
  }

  /// 处理服务器消息
  void _handleServerMessage(dynamic message) {
    try {
      debugPrint('ServerAsrService: 📥 收到消息，类型: ${message.runtimeType}');

      // 处理二进制消息
      if (message is List<int>) {
        final bytes = message as Uint8List;
        debugPrint('ServerAsrService: 🔍 二进制消息 - ${bytes.length} bytes');
        debugPrint(
          'ServerAsrService: 🔍 前20字节: ${bytes.sublist(0, bytes.length > 20 ? 20 : bytes.length)}',
        );

        // 尝试解析为JSON
        try {
          final messageString = utf8.decode(bytes);
          debugPrint('ServerAsrService: 🔍 解码为UTF-8字符串: $messageString');

          final data = jsonDecode(messageString);
          final type = data['type'];

          debugPrint('ServerAsrService: ✅ 二进制消息包含JSON - type: $type');

          _handleJsonMessage(data, messageString);
        } catch (e) {
          debugPrint('ServerAsrService: ⚠️ 二进制消息无法解析为JSON，可能是纯音频数据');
          // 纯音频数据，不需要处理
        }
      }
      // 处理字符串消息
      else if (message is String) {
        debugPrint('ServerAsrService: 🔍 字符串消息');
        final data = jsonDecode(message);
        _handleJsonMessage(data, message);
      }
    } catch (e) {
      debugPrint('ServerAsrService: 处理服务器消息失败 - $e');
    }
  }

  /// 处理JSON消息
  void _handleJsonMessage(Map<String, dynamic> data, String rawMessage) {
    try {
      final type = data['type'];
      // debugPrint('ServerAsrService: 收到服务器JSON消息 - type: $type');
      // debugPrint('ServerAsrService: 完整JSON: $rawMessage');

      // 格式化JSON并发送给UI显示
      final formattedJson = _formatJson(data);
      onJsonReceived?.call(formattedJson);
      // debugPrint('ServerAsrService: ✅ formattedJson - $formattedJson');

      switch (type) {
        case 'started':
          _sessionId = data['session_id'];
          // debugPrint('ServerAsrService: ✅ 会话已建立 - $_sessionId');
          onConnected?.call();
          break;

        case 'doubao_ready':
          final sessionId = data['session_id'] ?? '';
          // debugPrint('ServerAsrService: ✅ 豆包AST已就绪 - $sessionId');
          // debugPrint('ServerAsrService: 🎤 可以开始接收音频并实时翻译');
          break;

        case 'progress':
          final totalChunks = data['total_chunks'] ?? 0;
          final totalBytes = data['total_bytes'] ?? 0;
          // debugPrint(
          //   'ServerAsrService: 📊 进度 - $totalChunks chunks, $totalBytes bytes',
          // );
          break;

        case 'source':
          // debugPrint('ServerAsrService: 📥 收到source消息');
          // debugPrint('ServerAsrService: 完整JSON: $rawMessage');

          // 原文消息
          final text = data['text'] ?? '';
          final segmentIndex = data['segment_index'] ?? 0;

          // debugPrint(
          //   'ServerAsrService: 🎤 收到原文 - segment: $segmentIndex, text: "$text"',
          // );

          if (text.isNotEmpty) {
            _sourceBuffer[segmentIndex] = text;
            // 只存储原文，不立即更新显示
            _tryPairTranslation(segmentIndex);
          }
          break;

        case 'translation':
          // debugPrint('ServerAsrService: 📥 收到translation消息');
          // debugPrint('ServerAsrService: 完整JSON: $rawMessage');

          // 译文消息
          final text = data['text'] ?? '';
          final segmentIndex = data['segment_index'] ?? 0;

          // debugPrint(
          //   'ServerAsrService: 🌍 收到译文 - segment: $segmentIndex, text: "$text"',
          // );

          if (text.isNotEmpty) {
            _targetBuffer[segmentIndex] = text;
            // 当收到译文时，更新原文和译文的显示
            _updateSourceDisplay();
            _updateTargetDisplay();
            _tryPairTranslation(segmentIndex);
          }
          break;

        case 'result':
          final event = data['event'] ?? '';
          // debugPrint('ServerAsrService: ✅ 最终结果 - event: $event');
          // debugPrint('ServerAsrService: 🔍 完整result消息: $rawMessage');

          if (event == 'session_finished' && data.containsKey('result')) {
            final result = data['result'];
            // debugPrint('ServerAsrService: 🔍 result字段: $result');

            // 打印 translation_segments 和 sources_segments 字段
            if (result.containsKey('translation_segments')) {
              final translationSegments = result['translation_segments'];
              debugPrint(
                'ServerAsrService: 📝 translation_segments: $translationSegments',
              );
            }
            if (result.containsKey('sources_segments')) {
              final sourcesSegments = result['sources_segments'];
              debugPrint(
                'ServerAsrService: 📝 sources_segments: $sourcesSegments',
              );
            }

            final sourceSubtitle = result['source_subtitle'] ?? {};
            final targetSubtitle = result['target_subtitle'] ?? {};

            final sourceText = sourceSubtitle['text'] ?? '';
            final targetText = targetSubtitle['text'] ?? '';

            // debugPrint('ServerAsrService: 📝 完整原文: $sourceText');
            // debugPrint('ServerAsrService: 📝 完整译文: $targetText');

            if (sourceText.isNotEmpty && targetText.isNotEmpty) {
              // 打印后台返回的累积原文和译文
              // debugPrint('ServerAsrService: 📝 后台返回的累积原文: "$sourceText"');
              // debugPrint('ServerAsrService: 📝 后台返回的累积译文: "$targetText"');

              // 添加到翻译历史
              _translationHistory.add(MapEntry(sourceText, targetText));

              // 获取格式化后的累积原文和译文
              final formatted = _getFormattedSourceAndTarget();
              final formattedSourceText = formatted['source']!;
              final formattedTargetText = formatted['target']!;

              // 触发配对翻译回调
              onPairTranslationReceived?.call(
                formattedSourceText,
                formattedTargetText,
              );
            }

            // 触发回调（最终结果，is_final = 1）
            if (sourceText.isNotEmpty) {
              onTextSrcRecognized?.call(sourceText, 1);
            }
            if (targetText.isNotEmpty) {
              onTextDstRecognized?.call(targetText, 1);
            }
          } else {
            // 兼容旧格式
            final sourceText = data['source_text'] ?? '';
            final translationText = data['translation_text'] ?? '';
            debugPrint('ServerAsrService: ✅ 翻译结果（旧格式）');

            if (sourceText.isNotEmpty && translationText.isNotEmpty) {
              _translationHistory.add(MapEntry(sourceText, translationText));
              // 获取格式化后的累积原文和译文
              final formatted = _getFormattedSourceAndTarget();
              final formattedSourceText = formatted['source']!;
              final formattedTargetText = formatted['target']!;

              // 触发配对翻译回调
              onPairTranslationReceived?.call(
                formattedSourceText,
                formattedTargetText,
              );
            }

            if (sourceText.isNotEmpty) {
              onTextSrcRecognized?.call(sourceText, 1);
            }
            if (translationText.isNotEmpty) {
              onTextDstRecognized?.call(translationText, 1);
            }
          }
          break;

        case 'error':
          final errorMessage = data['message'] ?? '未知错误';
          debugPrint('ServerAsrService: ❌ 服务器错误 - $errorMessage');
          onError?.call('服务器错误: $errorMessage');
          break;

        default:
          debugPrint('ServerAsrService: ⚠️ 未知消息类型 - $type');
          debugPrint('ServerAsrService: 完整消息: $rawMessage');
      }
    } catch (e) {
      debugPrint('ServerAsrService: 处理JSON消息失败 - $e');
      debugPrint('ServerAsrService: 错误消息: $rawMessage');
    }
  }

  /// 启动音频发送定时器
  void _startSendTimer() {
    _sendTimer?.cancel();
    _sendTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_isSendingAudio && _audioBuffer.isNotEmpty) {
        _sendAudioChunk();
      }
    });
  }

  /// 发送音频数据块
  void _sendAudioChunk() {
    if (_wsChannel == null || !_isSendingAudio) return;

    // 每次发送最多3200字节（约100ms@16kHz）
    const chunkSize = 3200;
    final chunkSizeToSend = _audioBuffer.length > chunkSize
        ? chunkSize
        : _audioBuffer.length;

    if (chunkSizeToSend == 0) return;

    final chunk = _audioBuffer.sublist(0, chunkSizeToSend);
    _audioBuffer.removeRange(0, chunkSizeToSend);

    try {
      _wsChannel!.sink.add(Uint8List.fromList(chunk));
      // debugPrint(
      //   'ServerAsrService: 📤 发送音频块 - ${chunk.length} bytes, 缓冲区剩余: ${_audioBuffer.length}',
      // );
    } catch (e) {
      debugPrint('ServerAsrService: 发送音频块失败 - $e');
    }
  }

  /// 发送音频数据（由外部调用）
  void sendAudioData(List<int> audioData, {required int type}) {
    if (!_isConnected) {
      debugPrint('ServerAsrService: 未连接，无法发送音频数据');
      return;
    }

    // 如果还没有发送start消息，自动发送
    if (!_isSendingAudio) {
      debugPrint('ServerAsrService: 自动发送start消息');
      _sendStartMessage();
    }

    // 将音频数据添加到缓冲区
    _audioBuffer.addAll(audioData);

    // 如果缓冲区太大，立即发送一部分
    if (_audioBuffer.length >= 6400) {
      _sendAudioChunk();
      _sendAudioChunk(); // 发送两次以快速清理缓冲区
    }
  }

  /// 停止发送音频（发送end消息）
  Future<void> stopSendingAudio() async {
    if (!_isConnected || _wsChannel == null) {
      debugPrint('ServerAsrService: 未连接，无需停止');
      return;
    }

    try {
      // 发送缓冲区中剩余的音频
      while (_audioBuffer.isNotEmpty) {
        _sendAudioChunk();
        await Future.delayed(const Duration(milliseconds: 50));
      }

      // 发送end消息
      final endMessage = jsonEncode({'type': 'end'});
      debugPrint('ServerAsrService: 发送end消息');
      _wsChannel!.sink.add(endMessage);

      _isSendingAudio = false;
      _sendTimer?.cancel();
    } catch (e) {
      debugPrint('ServerAsrService: 停止发送音频失败 - $e');
    }
  }

  /// 断开连接
  Future<void> disconnect() async {
    await stopSendingAudio();
    _cleanup();
    debugPrint('ServerAsrService: 已断开连接');
  }

  /// 清理资源
  void _cleanup() {
    _sendTimer?.cancel();
    _sendTimer = null;
    _wsSubscription?.cancel();
    _wsSubscription = null;
    _wsChannel?.sink.close();
    _wsChannel = null;
    _isConnected = false;
    _isSendingAudio = false;
    _audioBuffer.clear();
    _translationHistory.clear();
    _lastSourceText = null;
    onDisconnected?.call();
  }

  /// 立即更新原文显示
  void _updateSourceDisplay() {
    // 收集所有原文
    final sourceBuffer = StringBuffer();
    for (final entry in _translationHistory) {
      sourceBuffer.write(entry.key.trim());
      sourceBuffer.write(' ');
    }
    // 按 segmentIndex 顺序添加当前缓冲区中的原文
    final sortedSourceKeys = _sourceBuffer.keys.toList()..sort();
    for (final key in sortedSourceKeys) {
      sourceBuffer.write(_sourceBuffer[key]!.trim());
      sourceBuffer.write(' ');
    }
    final sourceText = sourceBuffer.toString().trim();

    if (sourceText.isNotEmpty) {
      onTextSrcRecognized?.call(sourceText, 1);
    }
  }

  /// 立即更新译文显示
  void _updateTargetDisplay() {
    // 收集所有译文
    final targetBuffer = StringBuffer();
    for (final entry in _translationHistory) {
      targetBuffer.write(entry.value.trim());
      targetBuffer.write(' ');
    }
    // 按 segmentIndex 顺序添加当前缓冲区中的译文
    final sortedTargetKeys = _targetBuffer.keys.toList()..sort();
    for (final key in sortedTargetKeys) {
      targetBuffer.write(_targetBuffer[key]!.trim());
      targetBuffer.write(' ');
    }
    final targetText = targetBuffer.toString().trim();

    if (targetText.isNotEmpty) {
      onTextDstRecognized?.call(targetText, 1);
    }
  }

  /// 尝试配对翻译（当同时收到原文和译文时调用）
  void _tryPairTranslation(int segmentIndex) {
    // 检查是否同时存在原文和译文
    if (_sourceBuffer.containsKey(segmentIndex) &&
        _targetBuffer.containsKey(segmentIndex)) {
      final sourceText = _sourceBuffer[segmentIndex]!;
      final targetText = _targetBuffer[segmentIndex]!;

      debugPrint('ServerAsrService: ✅ 配对成功 - segment: $segmentIndex');
      debugPrint('ServerAsrService:    原文: "$sourceText"');
      debugPrint('ServerAsrService:    译文: "$targetText"');

      // 添加到翻译历史
      _translationHistory.add(MapEntry(sourceText, targetText));

      // 获取格式化后的累积原文和译文
      final formatted = _getFormattedSourceAndTarget();
      final formattedSourceText = formatted['source']!;
      final formattedTargetText = formatted['target']!;

      debugPrint('ServerAsrService: 📝 格式化后的累积原文:');
      debugPrint('ServerAsrService: ┌─────────────────────────────────');
      debugPrint('ServerAsrService: │ $formattedSourceText');
      debugPrint('ServerAsrService: └─────────────────────────────────');
      debugPrint('ServerAsrService: 📝 格式化后的累积译文:');
      debugPrint('ServerAsrService: ┌─────────────────────────────────');
      debugPrint('ServerAsrService: │ $formattedTargetText');
      debugPrint('ServerAsrService: └─────────────────────────────────');

      // 触发配对翻译回调
      onPairTranslationReceived?.call(formattedSourceText, formattedTargetText);

      // 不再触发单独的回调，只使用配对翻译回调来更新UI
      // 这样可以避免实时翻译时显示单独的片段
      // onTextSrcRecognized?.call(formattedSourceText, 1);
      // onTextDstRecognized?.call(formattedTargetText, 1);

      // 清理已配对的缓冲区
      _sourceBuffer.remove(segmentIndex);
      _targetBuffer.remove(segmentIndex);
    }
  }

  /// 获取分开的中文和英文句子列表
  Map<String, List<String>> _getSeparatedSentences() {
    if (_translationHistory.isEmpty) {
      return {'chinese': [], 'english': []};
    }

    final chineseSentences = <String>[];
    final englishSentences = <String>[];

    // 分别收集中文和英文句子
    for (final entry in _translationHistory) {
      final sourceText = entry.key.trim();
      final targetText = entry.value.trim();

      // 检查文本是否包含中文字符
      bool isChineseSource = RegExp(r'[\u4e00-\u9fa5]').hasMatch(sourceText);
      bool isChineseTarget = RegExp(r'[\u4e00-\u9fa5]').hasMatch(targetText);

      // 处理中文
      if (isChineseSource && sourceText.isNotEmpty) {
        // 分割中文句子
        final sentences = _splitChineseSentences(sourceText);
        chineseSentences.addAll(sentences);
      } else if (isChineseTarget && targetText.isNotEmpty) {
        // 分割中文句子
        final sentences = _splitChineseSentences(targetText);
        chineseSentences.addAll(sentences);
      }

      // 处理英文
      if (!isChineseSource && sourceText.isNotEmpty) {
        // 分割英文句子
        final sentences = _splitEnglishSentences(sourceText);
        englishSentences.addAll(sentences);
      } else if (!isChineseTarget && targetText.isNotEmpty) {
        // 分割英文句子
        final sentences = _splitEnglishSentences(targetText);
        englishSentences.addAll(sentences);
      }
    }

    return {'chinese': chineseSentences, 'english': englishSentences};
  }

  /// 分割中文句子
  List<String> _splitChineseSentences(
    String text, {
    bool isCurrentSentence = false,
  }) {
    // 清理文本
    text = text.trim();
    // 移除多余的空格
    text = text.replaceAll(RegExp(r'\s+'), ' ');

    // 按照后台传过来的标点进行分割
    final result = <String>[];
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      buffer.write(char);

      // 按中文句号、感叹号、问号分割句子
      if (RegExp(r'[。！？]').hasMatch(char)) {
        result.add(buffer.toString().trim());
        buffer.clear();
      }
    }

    // 处理最后一个句子（如果没有标点）
    if (buffer.isNotEmpty) {
      result.add(buffer.toString().trim());
    }

    return result;
  }

  /// 分割英文句子
  List<String> _splitEnglishSentences(
    String text, {
    bool isCurrentSentence = false,
  }) {
    // 清理文本
    text = text.trim();
    // 移除多余的空格
    text = text.replaceAll(RegExp(r'\s+'), ' ');

    // 按照后台传过来的标点进行分割
    final result = <String>[];
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      buffer.write(char);

      // 按英文句号、感叹号、问号分割句子
      if (RegExp(r'[.!?]').hasMatch(char)) {
        result.add(buffer.toString().trim());
        buffer.clear();
      }
    }

    // 处理最后一个句子（如果没有标点）
    if (buffer.isNotEmpty) {
      result.add(buffer.toString().trim());
    }

    return result;
  }

  /// 获取格式化的翻译历史（合并所有内容，清理多余标点）
  String _getFormattedTranslationHistory() {
    final separated = _getSeparatedSentences();
    final chineseSentences = separated['chinese']!;
    final englishSentences = separated['english']!;

    // 组合结果：先显示中文，再显示英文
    final buffer = StringBuffer();
    if (chineseSentences.isNotEmpty) {
      buffer.write(chineseSentences.join(' '));
      if (englishSentences.isNotEmpty) {
        buffer.write(' ');
      }
    }
    if (englishSentences.isNotEmpty) {
      buffer.write(englishSentences.join(' '));
    }

    return buffer.toString();
  }

  /// 获取交替显示的翻译结果（一句原文，一句译文）
  List<Map<String, String>> _getAlternatingTranslation() {
    if (_translationHistory.isEmpty) {
      return [];
    }

    // 使用最新的翻译对（完整的累积原文和译文）
    final latestEntry = _translationHistory.last;
    final sourceText = latestEntry.key.trim();
    final targetText = latestEntry.value.trim();

    // 检查文本是否包含中文字符
    bool isChineseSource = RegExp(r'[\u4e00-\u9fa5]').hasMatch(sourceText);
    bool isChineseTarget = RegExp(r'[\u4e00-\u9fa5]').hasMatch(targetText);

    // 分割句子（实时翻译时，当前句不显示标点）
    final sourceSentences = isChineseSource
        ? _splitChineseSentences(sourceText, isCurrentSentence: true)
        : _splitEnglishSentences(sourceText, isCurrentSentence: true);
    final targetSentences = isChineseTarget
        ? _splitChineseSentences(targetText, isCurrentSentence: true)
        : _splitEnglishSentences(targetText, isCurrentSentence: true);

    final result = <Map<String, String>>[];
    final maxLength = max(sourceSentences.length, targetSentences.length);

    for (int i = 0; i < maxLength; i++) {
      if (i < sourceSentences.length && i < targetSentences.length) {
        result.add({
          'source': sourceSentences[i],
          'target': targetSentences[i],
        });
      } else if (i < sourceSentences.length) {
        result.add({'source': sourceSentences[i], 'target': ''});
      } else if (i < targetSentences.length) {
        result.add({'source': '', 'target': targetSentences[i]});
      }
    }

    return result;
  }

  /// 获取格式化后的累积原文和译文（用于控件显示）
  Map<String, String> _getFormattedSourceAndTarget() {
    if (_translationHistory.isEmpty) {
      return {'source': '', 'target': ''};
    }

    // 累积所有翻译对的原文和译文
    final sourceBuffer = StringBuffer();
    final targetBuffer = StringBuffer();

    for (final entry in _translationHistory) {
      sourceBuffer.write(entry.key.trim());
      sourceBuffer.write(' ');
      targetBuffer.write(entry.value.trim());
      targetBuffer.write(' ');
    }

    final sourceText = sourceBuffer.toString().trim();
    final targetText = targetBuffer.toString().trim();

    // 检查文本是否包含中文字符
    bool isChineseSource = RegExp(r'[\u4e00-\u9fa5]').hasMatch(sourceText);
    bool isChineseTarget = RegExp(r'[\u4e00-\u9fa5]').hasMatch(targetText);

    // 分割句子（实时翻译时，当前句不显示标点）
    final sourceSentences = isChineseSource
        ? _splitChineseSentences(sourceText, isCurrentSentence: true)
        : _splitEnglishSentences(sourceText, isCurrentSentence: true);
    final targetSentences = isChineseTarget
        ? _splitChineseSentences(targetText, isCurrentSentence: true)
        : _splitEnglishSentences(targetText, isCurrentSentence: true);

    // 构建格式化后的文本，使用特殊分隔符分割句子
    final sourceWithSeparator = sourceSentences.join('|||');
    final targetWithSeparator = targetSentences.join('|||');

    return {'source': sourceWithSeparator, 'target': targetWithSeparator};
  }

  /// 获取语言代码
  String _getLanguageCode(String language) {
    switch (language.toLowerCase()) {
      case '中文':
      case 'zh':
      case 'chinese':
        return 'zh';
      case '英语':
      case '英文':
      case 'en':
      case 'english':
        return 'en';
      case '日语':
      case 'ja':
      case 'japanese':
        return 'ja';
      case '韩语':
      case 'ko':
      case 'korean':
        return 'ko';
      default:
        return language.toLowerCase().substring(0, 2);
    }
  }

  /// 格式化JSON为易读的字符串
  String _formatJson(Map<String, dynamic> data) {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(data);
    } catch (e) {
      debugPrint('ServerAsrService: JSON格式化失败 - $e');
      return jsonEncode(data);
    }
  }

  /// 启用TTS
  void enableTts({required int type}) {
    debugPrint('ServerAsrService: TTS功能暂未实现（需要服务器API支持）');
  }

  /// 禁用TTS
  void disableTts({required int type}) {
    debugPrint('ServerAsrService: TTS功能暂未实现');
  }

  /// 释放资源
  void dispose() {
    disconnect();
  }
}
