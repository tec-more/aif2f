/// 讯飞同传API语言映射配置
///
/// 根据讯飞官方文档：https://www.xfyun.cn/doc/nlp/simultaneous-interpretation/API.html
/// 目前仅支持中文↔英文互译

/// 讯飞支持的语言列表
class XfyunLanguages {
  /// 中文
  static const String chinese = '中文';
  /// 英语
  static const String english = '英语';

  /// 所有支持的语言列表（按UI显示顺序）
  static const List<String> supportedLanguages = [
    chinese,
    english,
  ];

  /// 检查语言是否支持
  static bool isSupported(String language) {
    return supportedLanguages.contains(language);
  }
}

/// 讯流语言代码映射
class XfyunLanguageCodes {
  /// 中文代码
  static const String zh = 'zh';
  /// 英文代码
  static const String en = 'en';

  /// CN代码（用于streamtrans）
  static const String cn = 'cn';
  /// EN代码（用于streamtrans）
  static const String enTrans = 'en';

  /// UI语言名称到讯飞代码的映射
  static const Map<String, String> uiToXfyunCode = {
    XfyunLanguages.chinese: zh,
    XfyunLanguages.english: en,
  };

  /// UI语言名称到streamtrans代码的映射
  static const Map<String, String> uiToStreamtransCode = {
    XfyunLanguages.chinese: cn,
    XfyunLanguages.english: enTrans,
  };

  /// 获取语音识别语言代码（ist.language）
  /// 注意：目前讯飞只支持 "zh_cn"，该参数固定
  static String getIstLanguage(String sourceLanguage) {
    // 目前讯飞同传API只支持中文识别
    return 'zh_cn';
  }

  /// 获取语言过滤模式（ist.language_type）
  /// 根据源语言和目标语言决定使用哪种模式
  static int getLanguageType(String sourceLanguage, String targetLanguage) {
    // language_type 说明：
    // 1：中英文模式，中文英文均可识别（默认）
    // 2：中文模式，可识别出简单英文
    // 3：英文模式，只识别出英文
    // 4：纯中文模式，只识别出中文

    final src = uiToXfyunCode[sourceLanguage] ?? zh;
    final tgt = uiToXfyunCode[targetLanguage] ?? en;

    // 根据源语言和目标语言组合决定模式
    if (src == zh && tgt == en) {
      // 中文→英文：使用中英混合模式
      return 1;
    } else if (src == en && tgt == zh) {
      // 英文→中文：使用英文模式
      return 3;
    } else if (src == zh && tgt == zh) {
      // 中文→中文：使用纯中文模式
      return 4;
    } else {
      // 其他情况：默认中英混合模式
      return 1;
    }
  }

  /// 获取翻译源语言代码（streamtrans.from）
  static String getStreamtransFrom(String sourceLanguage) {
    return uiToStreamtransCode[sourceLanguage] ?? cn;
  }

  /// 获取翻译目标语言代码（streamtrans.to）
  static String getStreamtransTo(String targetLanguage) {
    return uiToStreamtransCode[targetLanguage] ?? enTrans;
  }
}

/// TTS发音人映射
class XfyunTTSVoices {
  /// 英文女性
  static const String catherine = 'x2_catherine';
  /// 英文男性
  static const String john = 'x2_john';
  /// 成年女性（中文）
  static const String xiaoguo = 'x2_xiaoguo';
  /// 成年男性（中文）
  static const String xiaozhong = 'x2_xiaozhong';

  /// 根据目标语言选择合适的发音人
  static String getVoiceForLanguage(String targetLanguage) {
    if (targetLanguage == XfyunLanguages.english) {
      return catherine; // 英文使用女声
    } else if (targetLanguage == XfyunLanguages.chinese) {
      return xiaoguo; // 中文使用女声
    }
    // 默认返回中文女声
    return xiaoguo;
  }
}

/// 语言参数配置类
/// 用于封装讯飞API所需的所有语言相关参数
class XfyunLanguageConfig {
  final String sourceLanguage;
  final String targetLanguage;

  XfyunLanguageConfig({
    required this.sourceLanguage,
    required this.targetLanguage,
  }) {
    // 验证语言是否支持
    if (!XfyunLanguages.isSupported(sourceLanguage)) {
      throw ArgumentError('讯飞API暂不支持源语言: $sourceLanguage');
    }
    if (!XfyunLanguages.isSupported(targetLanguage)) {
      throw ArgumentError('讯飞API暂不支持目标语言: $targetLanguage');
    }
  }

  /// 获取语音识别语言
  String get istLanguage => XfyunLanguageCodes.getIstLanguage(sourceLanguage);

  /// 获取语言过滤模式
  int get languageType => XfyunLanguageCodes.getLanguageType(
    sourceLanguage,
    targetLanguage,
  );

  /// 获取口音（目前固定为mandarin）
  String get accent => 'mandarin';

  /// 获取应用领域
  String get domain => 'ist_ed_open';

  /// 获取翻译源语言
  String get streamtransFrom => XfyunLanguageCodes.getStreamtransFrom(
    sourceLanguage,
  );

  /// 获取翻译目标语言
  String get streamtransTo => XfyunLanguageCodes.getStreamtransTo(
    targetLanguage,
  );

  /// 获取TTS发音人
  String get ttsVcn => XfyunTTSVoices.getVoiceForLanguage(
    targetLanguage,
  );

  /// 转换为JSON格式（用于发送到讯飞API）
  Map<String, dynamic> toJson() {
    return {
      'ist': {
        'language': istLanguage,
        'language_type': languageType,
        'domain': domain,
        'accent': accent,
      },
      'streamtrans': {
        'from': streamtransFrom,
        'to': streamtransTo,
      },
      'tts': {
        'vcn': ttsVcn,
      },
    };
  }

  @override
  String toString() {
    return 'XfyunLanguageConfig(source: $sourceLanguage → target: $targetLanguage, '
        'ist: $istLanguage(type:$languageType), '
        'trans: $streamtransFrom→$streamtransTo, '
        'tts: $ttsVcn)';
  }
}
