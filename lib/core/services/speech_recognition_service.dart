import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

/// 语音识别服务
class SpeechRecognitionService {
  final Dio _dio = Dio();

  // TODO: 替换为实际的API配置
  String _apiKey = '35bd6c37532642a4ad0e4899b9dddfe0.SHg4UhGjeMHcArnf';
  String _apiUrl = 'https://open.bigmodel.cn/api/paas/v4';

  /// 设置API密钥
  void setApiKey(String apiKey) {
    _apiKey = apiKey;
  }

  /// 设置API URL
  void setApiUrl(String url) {
    _apiUrl = url;
  }

  /// 将音频文件转换为文本（使用OpenAI Whisper API）
  Future<String> transcribeAudio({
    required String audioFilePath,
    String language = 'zh',
  }) async {
    try {
      // 检查文件是否存在
      final file = File(audioFilePath);
      if (!await file.exists()) {
        throw Exception('音频文件不存在: $audioFilePath');
      }

      // 准备请求数据
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          audioFilePath,
          filename: 'audio.m4a',
        ),
        'model': 'whisper-1',
        'language': language,
      });

      // 发送请求
      final response = await _dio.post(
        _apiUrl,
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      // 解析响应
      if (response.statusCode == 200) {
        final result = response.data;
        return result['text'] ?? '';
      } else {
        throw Exception('语音识别失败: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('语音识别错误: $e');
      rethrow;
    }
  }

  /// 使用模拟数据进行测试（不调用实际API）
  Future<String> transcribeAudioMock({
    required String audioFilePath,
    String language = 'zh',
  }) async {
    // 模拟网络延迟
    await Future.delayed(const Duration(seconds: 1));

    // 返回模拟数据
    return '这是一段测试语音识别文本';
  }
}

/// 语音识别结果
class SpeechRecognitionResult {
  final String text;
  final String language;
  final double confidence;
  final int duration;

  SpeechRecognitionResult({
    required this.text,
    required this.language,
    this.confidence = 0.0,
    this.duration = 0,
  });

  factory SpeechRecognitionResult.fromJson(Map<String, dynamic> json) {
    return SpeechRecognitionResult(
      text: json['text'] ?? '',
      language: json['language'] ?? 'zh',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      duration: json['duration'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'language': language,
      'confidence': confidence,
      'duration': duration,
    };
  }
}
