import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 语言选择状态类
class LanguagePair {
  /// 源语言
  final String sourceLanguage;

  /// 目标语言
  final String targetLanguage;

  /// 语言代码映射表 (完整语言名称 -> 语言代码)
  final Map<String, String> languageCodes;

  /// 构造函数
  const LanguagePair({
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.languageCodes,
  });

  /// 复制方法
  LanguagePair copyWith({
    String? sourceLanguage,
    String? targetLanguage,
    Map<String, String>? languageCodes,
  }) {
    return LanguagePair(
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      languageCodes: languageCodes ?? this.languageCodes,
    );
  }

  /// 交换源语言和目标语言
  LanguagePair swap() {
    return LanguagePair(
      sourceLanguage: targetLanguage,
      targetLanguage: sourceLanguage,
      languageCodes: languageCodes,
    );
  }
}

/// 默认语言列表
const defaultLanguageCodes = {
  '英语': 'EN',
  '中文': 'ZH',
  '日语': 'JA',
  '韩语': 'KO',
  '法语': 'FR',
  '德语': 'DE',
  '西班牙语': 'ES',
  '俄语': 'RU',
};

/// 语言选择状态管理器
class LanguageNotifier extends Notifier<LanguagePair> {
  /// 构建方法 - 替换原来的构造函数
  @override
  LanguagePair build() {
    return const LanguagePair(
      sourceLanguage: '英语',
      targetLanguage: '中文',
      languageCodes: defaultLanguageCodes,
    );
  }
  
  // 其他方法保持不变
  void setSourceLanguage(String language) {
    state = state.copyWith(sourceLanguage: language);
  }
  
  void setTargetLanguage(String language) {
    state = state.copyWith(targetLanguage: language);
  }
  
  void swapLanguages() {
    state = state.swap();
  }
  
  void updateLanguageCodes(Map<String, String> languageCodes) {
    state = state.copyWith(languageCodes: languageCodes);
  }
}

final languageProvider = NotifierProvider<LanguageNotifier, LanguagePair>(LanguageNotifier.new);

/// 交换语言按钮点击事件提供器
/// 交换语言按钮点击事件提供器
final swapLanguagesProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    ref.read(languageProvider.notifier).swapLanguages();
  };
});

/// 语言代码提供器
final languageCodesProvider = Provider<Map<String, String>>((ref) {
  return ref.watch(languageProvider).languageCodes;
});

/// 源语言提供器
final sourceLanguageProvider = Provider<String>((ref) {
  return ref.watch(languageProvider).sourceLanguage;
});

/// 目标语言提供器
final targetLanguageProvider = Provider<String>((ref) {
  return ref.watch(languageProvider).targetLanguage;
});
