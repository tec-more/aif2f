/// 应用配置
/// 用于管理API密钥和配置信息
class AppConfig {
  /// 服务器API配置
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:9998',
  );

  static const String apiVersion = 'v1';

  /// 获取完整的API路径
  static String getApiPath(String path) {
    return '$apiBaseUrl/$apiVersion$path';
  }

  /// 获取WebSocket路径（可能需要/api前缀）
  static String getWebSocketPath(String path) {
    // WebSocket路径可能需要 /api/v1 而不是 /v1
    // 根据服务器文档，WebSocket使用 /api/v1
    return '$apiBaseUrl/api/$apiVersion$path';
  }

  /// 句子分隔符（用于区分识别的不同句子）
  /// 使用特殊字符组合，避免与正常文本冲突
  static const String sentenceSeparator = '|||';

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
  static bool get isFullyConfigured => apiBaseUrl.isNotEmpty;

  /// 获取配置摘要(用于调试)
  static Map<String, dynamic> getConfigSummary() {
    return {
      'apiBaseUrl': apiBaseUrl,
      'debugMode': enableDebugMode,
      'audioSampleRate': audioSampleRate,
      'realTimeSegmentDuration': realTimeSegmentDuration,
    };
  }
}
