import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:aif2f/core/config/app_config.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

/// 服务器ASR服务
/// 使用服务器API的豆包同传进行语音识别和翻译
class ServerAsrService {
  // 识别结果回调
  Function(String, int)? onTextSrcRecognized; // (text, is_final) 原文识别回调
  Function(String, int)? onTextDstRecognized; // (text, is_final) 译文识别回调
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
  bool _isProcessing = false;
  String? _authToken;

  // 音频缓冲区
  final List<int> _audioBuffer = [];
  Timer? _uploadTimer;

  bool get isConnected => _isConnected;
  bool get isProcessing => _isProcessing;

  /// 设置认证Token
  void setAuthToken(String token) {
    _authToken = token;
    debugPrint('ServerAsrService: 已设置认证Token');
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
    debugPrint('ServerAsrService: 语言配置已更新 - $sourceLanguage -> $targetLanguage (type: $type)');
  }

  /// 连接到服务器
  Future<bool> connect() async {
    try {
      if (_authToken == null || _authToken!.isEmpty) {
        onError?.call('未设置认证Token');
        return false;
      }

      _isConnected = true;
      onConnected?.call();
      debugPrint('ServerAsrService: 已连接到服务器');
      return true;
    } catch (e) {
      debugPrint('ServerAsrService: 连接失败 - $e');
      onError?.call('连接失败: $e');
      return false;
    }
  }

  /// 断开连接
  Future<void> disconnect() async {
    _uploadTimer?.cancel();
    _uploadTimer = null;

    // 上传剩余的音频数据
    if (_audioBuffer.isNotEmpty) {
      await _uploadAudioData(List.from(_audioBuffer));
      _audioBuffer.clear();
    }

    _isConnected = false;
    _isProcessing = false;
    onDisconnected?.call();
    debugPrint('ServerAsrService: 已断开连接');
  }

  /// 发送音频数据
  void sendAudioData(List<int> audioData, {required int type}) async {
    if (!_isConnected) {
      debugPrint('ServerAsrService: 未连接，无法发送音频数据');
      return;
    }

    // 将音频数据添加到缓冲区
    _audioBuffer.addAll(audioData);

    // 如果缓冲区达到一定大小，立即上传
    if (_audioBuffer.length >= 48000) { // 约3秒的音频（16kHz采样率）
      await _uploadAudioData(List.from(_audioBuffer));
      _audioBuffer.clear();
    }
  }

  /// 上传音频数据到服务器进行识别和翻译
  Future<void> _uploadAudioData(List<int> audioData) async {
    if (_isProcessing) return; // 避免重复处理

    try {
      _isProcessing = true;

      // 创建临时文件
      final tempDir = Directory.systemTemp;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'audio_$timestamp.wav';
      final filePath = path.join(tempDir.path, fileName);
      final file = File(filePath);
      await file.writeAsBytes(audioData);

      debugPrint('ServerAsrService: 上传音频文件 - ${audioData.length}字节');

      // 创建multipart请求
      final url = Uri.parse(AppConfig.getApiPath('/llm/voice/translation/streaming'));
      final request = http.MultipartRequest('POST', url);

      // 添加认证头
      request.headers['Authorization'] = 'Bearer $_authToken';

      // 添加音频文件
      final audioFile = await http.MultipartFile.fromPath(
        'audio_file',
        filePath,
        filename: fileName,
      );
      request.files.add(audioFile);

      // 添加其他参数
      request.fields['source_language'] = _sourceLanguage ?? 'zh';
      request.fields['target_language'] = _targetLanguage ?? 'en';
      request.fields['format'] = 'wav';
      request.fields['sample_rate'] = '16000';

      // 发送请求
      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      // 删除临时文件
      if (await file.exists()) {
        await file.delete();
      }

      // 解析响应
      if (streamedResponse.statusCode == 200) {
        final data = jsonDecode(responseBody);
        _handleTranslationResponse(data);
      } else {
        debugPrint('ServerAsrService: API错误 - ${streamedResponse.statusCode}');
        debugPrint('响应: $responseBody');
        onError?.call('API错误: ${streamedResponse.statusCode}');
      }
    } catch (e) {
      debugPrint('ServerAsrService: 上传失败 - $e');
      onError?.call('上传失败: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// 处理翻译响应
  void _handleTranslationResponse(dynamic data) {
    try {
      // 根据API响应格式解析结果
      // 注意：这里需要根据实际API响应格式调整
      if (data is Map) {
        final srcText = data['source_text'] ?? '';
        final dstText = data['target_text'] ?? '';

        if (srcText.isNotEmpty) {
          onTextSrcRecognized?.call(srcText, 1); // is_final = 1
          debugPrint('ServerAsrService: 原文 - $srcText');
        }

        if (dstText.isNotEmpty) {
          onTextDstRecognized?.call(dstText, 1); // is_final = 1
          debugPrint('ServerAsrService: 译文 - $dstText');
        }
      }
    } catch (e) {
      debugPrint('ServerAsrService: 解析响应失败 - $e');
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
