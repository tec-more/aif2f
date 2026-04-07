import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:aif2f/core/config/app_config.dart';
import 'package:aif2f/core/services/api_key_service.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

/// 服务器ASR服务（方案B：使用用户JWT认证）
class ServerAsrServiceV2 {
  // 识别结果回调
  Function(String, int)? onTextSrcRecognized;
  Function(String, int)? onTextDstRecognized;
  Function(String)? onError;
  Function()? onConnected;
  Function()? onDisconnected;
  Function(Uint8List)? onTtsAudioReceived;

  // 语言配置
  String? _sourceLanguage;
  String? _targetLanguage;
  int? _type;

  // 状态
  bool _isConnected = false;
  bool _isProcessing = false;
  String? _userAuthToken;
  int? _providerId;

  // API密钥服务
  final ApiKeyService _apiKeyService = ApiKeyService();

  // 音频缓冲区
  final List<int> _audioBuffer = [];

  bool get isConnected => _isConnected;
  bool get isProcessing => _isProcessing;

  /// 设置用户认证Token
  void setAuthToken(String token) {
    _userAuthToken = token;
    _apiKeyService.setAuthToken(token);
    debugPrint('ServerAsrServiceV2: 已设置用户认证Token');
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
    debugPrint('ServerAsrServiceV2: 语言配置已更新');
  }

  /// 连接到服务器
  Future<bool> connect() async {
    try {
      if (_userAuthToken == null || _userAuthToken!.isEmpty) {
        onError?.call('未设置认证Token');
        return false;
      }

      // 获取同声传译类型的API密钥
      final apiKey = await _apiKeyService.getSimultaneousInterpretationKey();

      if (apiKey == null) {
        onError?.call('未找到同声传译类型的API密钥');
        return false;
      }

      _providerId = apiKey.providerId;

      if (_providerId == null) {
        onError?.call('API密钥缺少provider_id');
        return false;
      }

      debugPrint('ServerAsrServiceV2: 使用ProviderID: $_providerId');
      debugPrint('ServerAsrServiceV2: 认证方式：用户JWT Token');

      _isConnected = true;
      onConnected?.call();
      return true;
    } catch (e) {
      debugPrint('ServerAsrServiceV2: 连接失败 - $e');
      onError?.call('连接失败: $e');
      return false;
    }
  }

  /// 创建WAV文件头
  List<int> _createWavHeader(List<int> pcmData) {
    final sampleRate = 16000;
    final numChannels = 1;
    final bitsPerSample = 16;
    final byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
    final blockAlign = numChannels * bitsPerSample ~/ 8;
    final dataSize = pcmData.length;
    final fileSize = 36 + dataSize;

    final header = <int>[];

    // RIFF chunk
    header.addAll('RIFF'.codeUnits);
    header.addAll(_toInt32(fileSize));
    header.addAll('WAVE'.codeUnits);

    // fmt sub-chunk
    header.addAll('fmt '.codeUnits);
    header.addAll(_toInt32(16));
    header.addAll(_toInt16(1)); // PCM
    header.addAll(_toInt16(numChannels));
    header.addAll(_toInt32(sampleRate));
    header.addAll(_toInt32(byteRate));
    header.addAll(_toInt16(blockAlign));
    header.addAll(_toInt16(bitsPerSample));

    // data sub-chunk
    header.addAll('data'.codeUnits);
    header.addAll(_toInt32(dataSize));

    return header;
  }

  List<int> _toInt32(int value) {
    return [
      value & 0xFF,
      (value >> 8) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 24) & 0xFF,
    ];
  }

  List<int> _toInt16(int value) {
    return [value & 0xFF, (value >> 8) & 0xFF];
  }

  /// 上传音频
  Future<void> _uploadAudioData(List<int> audioData) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      // 创建WAV文件（带正确的WAV头）
      final wavHeader = _createWavHeader(audioData);
      final wavData = [...wavHeader, ...audioData];

      final tempDir = Directory.systemTemp;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'audio_$timestamp.wav';
      final filePath = path.join(tempDir.path, fileName);
      final file = File(filePath);
      await file.writeAsBytes(wavData);

      debugPrint(
        'ServerAsrServiceV2: 创建WAV文件 - ${wavData.length}字节 (头:${wavHeader.length}, 数据:${audioData.length})',
      );
      debugPrint('ServerAsrServiceV2: WAV格式 - 16kHz, 16-bit, 单声道PCM');

      final url = Uri.parse(
        AppConfig.getApiPath('/llm/voice/translation/streaming/v3'),
      );
      debugPrint('ServerAsrServiceV2: URL - $url');

      final request = http.MultipartRequest('POST', url);

      // 使用用户JWT Token认证
      request.headers['Authorization'] = 'Bearer $_userAuthToken';
      debugPrint(
        'ServerAsrServiceV2: Authorization - Bearer ${_userAuthToken?.substring(0, 20)}...',
      );

      // 音频文件
      final audioFile = await http.MultipartFile.fromPath(
        'audio_file',
        filePath,
        filename: fileName,
      );
      request.files.add(audioFile);

      // 参数
      request.fields['provider_id'] = _providerId.toString();
      request.fields['source_language'] = _sourceLanguage ?? 'zh';
      request.fields['target_language'] = _targetLanguage ?? 'en';
      request.fields['format'] = 'wav';
      request.fields['sample_rate'] = '16000';

      debugPrint(
        'ServerAsrServiceV2: provider_id = ${request.fields['provider_id']}',
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (await file.exists()) {
        await file.delete();
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        _handleResponse(data);
      } else {
        debugPrint(
          'ServerAsrServiceV2: 错误 ${response.statusCode} - $responseBody',
        );
        onError?.call('API错误: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ServerAsrServiceV2: 上传失败 - $e');
      onError?.call('上传失败: $e');
    } finally {
      _isProcessing = false;
    }
  }

  void _handleResponse(dynamic data) {
    if (data is Map) {
      final srcText = data['source_text'] ?? '';
      final dstText = data['target_text'] ?? '';

      if (srcText.isNotEmpty) {
        onTextSrcRecognized?.call(srcText, 1);
        debugPrint('ServerAsrServiceV2: 原文 - $srcText');
      }

      if (dstText.isNotEmpty) {
        onTextDstRecognized?.call(dstText, 1);
        debugPrint('ServerAsrServiceV2: 译文 - $dstText');
      }
    }
  }

  /// 其他方法...
  void sendAudioData(List<int> audioData, {required int type}) async {
    if (!_isConnected) return;
    _audioBuffer.addAll(audioData);
    if (_audioBuffer.length >= 48000) {
      await _uploadAudioData(List.from(_audioBuffer));
      _audioBuffer.clear();
    }
  }

  Future<void> disconnect() async {
    _isConnected = false;
    onDisconnected?.call();
  }

  void dispose() {
    disconnect();
  }

  void enableTts({required int type}) {}
  void disableTts({required int type}) {}
}
