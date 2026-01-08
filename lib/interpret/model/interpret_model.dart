/// 翻译配置
class TranslationConfig {
  String sourceLanguage;
  String targetLanguage;
  String selectedVoice;
  double voiceSpeed;
  double voicePitch;
  bool isAutoPlay;

  TranslationConfig({
    this.sourceLanguage = 'zh-CN',
    this.targetLanguage = 'en-US',
    this.selectedVoice = 'zh-CN-XiaoxiaoNeural',
    this.voiceSpeed = 1.0,
    this.voicePitch = 1.0,
    this.isAutoPlay = true,
  });
}

/// 翻译结果
class TranslationResult {
  final String sourceText;
  final String targetText;
  final String sourceLanguage;
  final String targetLanguage;

  TranslationResult({
    required this.sourceText,
    required this.targetText,
    required this.sourceLanguage,
    required this.targetLanguage,
  });
}

/// 支持的语言
List<Language> supportedLanguages = [
  Language(code: 'zh-CN', name: '中文'),
  Language(code: 'en-US', name: 'English'),
  Language(code: 'ja-JP', name: '日本語'),
  Language(code: 'ko-KR', name: '한국어'),
  Language(code: 'fr-FR', name: 'Français'),
  Language(code: 'de-DE', name: 'Deutsch'),
  Language(code: 'es-ES', name: 'Español'),
  Language(code: 'ru-RU', name: 'Русский'),
];

class Language {
  final String code;
  final String name;

  Language({required this.code, required this.name});
}

/// 支持的音色
List<Voice> supportedVoices = [
  Voice(id: 'zh-CN-XiaoxiaoNeural', name: '晓晓 - 女'),
  Voice(id: 'zh-CN-YunxiNeural', name: '云希 - 男'),
  Voice(id: 'zh-CN-XiaoyiNeural', name: '小依 - 女'),
  Voice(id: 'zh-CN-YunjianNeural', name: '云健 - 男'),
  Voice(id: 'en-US-AriaNeural', name: 'Aria - 女'),
  Voice(id: 'en-US-ChristopherNeural', name: 'Christopher - 男'),
];

class Voice {
  final String id;
  final String name;

  Voice({required this.id, required this.name});
}
