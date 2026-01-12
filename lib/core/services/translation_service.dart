import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// 翻译服务
class TranslationService {
  final Dio _dio = Dio();

  // TODO: 替换为实际的API配置
  String _apiKey = 'YOUR_API_KEY';
  String _apiUrl = 'https://api.openai.com/v1/chat/completions';

  /// 设置API密钥
  void setApiKey(String apiKey) {
    _apiKey = apiKey;
  }

  /// 设置API URL
  void setApiUrl(String url) {
    _apiUrl = url;
  }

  /// 翻译文本
  Future<String> translateText({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    try {
      if (text.isEmpty) {
        return '';
      }

      // 构建提示词
      final prompt = _buildTranslationPrompt(
        text: text,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      );

      // 准备请求数据
      final data = {
        'model': 'gpt-3.5-turbo',
        'messages': [
          {
            'role': 'system',
            'content': '你是一个专业的翻译助手。请准确翻译用户输入的文本，只返回翻译结果，不要添加任何解释或额外内容。',
          },
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.3,
        'max_tokens': 2000,
      };

      // 发送请求
      final response = await _dio.post(
        _apiUrl,
        data: data,
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
        ),
      );

      // 解析响应
      if (response.statusCode == 200) {
        final result = response.data;
        final content = result['choices']?[0]?['message']?['content'];
        return content?.trim() ?? '';
      } else {
        throw Exception('翻译失败: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('翻译错误: $e');
      rethrow;
    }
  }

  /// 构建翻译提示词
  String _buildTranslationPrompt({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  }) {
    final sourceName = _getLanguageName(sourceLanguage);
    final targetName = _getLanguageName(targetLanguage);

    return '请将以下$sourceName文本翻译成$targetName：\n\n$text';
  }

  /// 获取语言名称
  String _getLanguageName(String code) {
    final languageMap = {
      '英语': '英语',
      '中文': '中文',
      '日语': '日语',
      '韩语': '韩语',
      '法语': '法语',
      '德语': '德语',
      '西班牙语': '西班牙语',
      '俄语': '俄语',
      'EN': '英语',
      'ZH': '中文',
      'JA': '日语',
      'KO': '韩语',
      'FR': '法语',
      'DE': '德语',
      'ES': '西班牙语',
      'RU': '俄语',
    };
    return languageMap[code] ?? code;
  }

  /// 使用模拟数据进行测试（不调用实际API）
  Future<String> translateTextMock({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 800));

    // 返回模拟数据
    if (targetLanguage == '英语' || targetLanguage == 'EN') {
      return 'Translated: $text';
    } else if (targetLanguage == '日语' || targetLanguage == 'JA') {
      return '翻訳: $text';
    } else if (targetLanguage == '韩语' || targetLanguage == 'KO') {
      return '번역: $text';
    } else {
      return '$targetLanguage: $text';
    }
  }
}
