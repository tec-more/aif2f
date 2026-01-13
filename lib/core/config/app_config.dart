/// 应用配置
/// 用于管理API密钥和配置信息
class AppConfig {
  /// 智谱AI配置
  static const String zhipuApiKey = String.fromEnvironment(
    'ZHIPU_API_KEY',
    defaultValue:
        '35bd6c37532642a4ad0e4899b9dddfe0.SHg4UhGjeMHcArnf', // 默认为空,需要在运行时设置
  );

  static const String zhipuBaseUrl = String.fromEnvironment(
    'ZHIPU_BASE_URL',
    defaultValue: 'https://open.bigmodel.cn/api/paas/v4',
  );

  static const String zhipuSockBaseUrl = String.fromEnvironment(
    'ZHIPU_SOCK_BASE_URL',
    defaultValue: 'wss://open.bigmodel.cn/api/paas/v4/realtime',
  );

  /// OpenAI配置(可选)
  static const String openaiApiKey = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: '',
  );

  static const String openaiBaseUrl = String.fromEnvironment(
    'OPENAI_BASE_URL',
    defaultValue: 'https://api.openai.com/v1',
  );

  /// 应用设置
  static const bool enableDebugMode = bool.fromEnvironment(
    'DEBUG_MODE',
    defaultValue: true,
  );

  /// 音频配置
  static const int audioSampleRate = 16000;
  static const int audioBitRate = 128000;
  static const int audioChannels = 1;

  /// 实时翻译配置
  static const int realTimeSegmentDuration = 3; // 秒
  static const int maxTranslationHistory = 100;

  /// 检查配置是否完整
  static bool get isZhipuConfigured => zhipuApiKey.isNotEmpty;
  static bool get isOpenAIConfigured => openaiApiKey.isNotEmpty;
  static bool get isFullyConfigured => isZhipuConfigured;

  /// 获取配置摘要(用于调试)
  static Map<String, dynamic> getConfigSummary() {
    return {
      'zhipuConfigured': isZhipuConfigured,
      'openaiConfigured': isOpenAIConfigured,
      'debugMode': enableDebugMode,
      'audioSampleRate': audioSampleRate,
      'realTimeSegmentDuration': realTimeSegmentDuration,
    };
  }
}
