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

  static const String xFBaseUrl = String.fromEnvironment(
    'XF_BASE_URL',
    defaultValue: 'https://open.bigmodel.cn/api/paas/v4',
  );

  static const String xFInterpretationUrl = String.fromEnvironment(
    'XF_INTERPRETATION_URL',
    defaultValue: 'wss://ws-api.xf-yun.com/v1/private/simult_interpretation',
  );

  static const String xFAPPID = String.fromEnvironment(
    'XF_APPID',
    defaultValue: '45f8b6dc',
  );

  static const String xFAPIKey = String.fromEnvironment(
    'XF_APIKey',
    defaultValue: 'd1e278fccac15457aaf4c98d85a65236',
  );

  static const String xFAPISecret = String.fromEnvironment(
    'XF_APISecret',
    defaultValue: 'NzhiOWNjZTA5YmJmMWU5MGIwYmM4YTIw',
  );

  // 科大讯飞实时语音转写 API URL（更稳定，推荐使用）
  static const String xFRealtimeAsrUrl = String.fromEnvironment(
    'XF_REALTIME_ASR_URL',
    defaultValue: 'wss://iat-api.xfyun.cn/v2/iat',
  );

  // 默认使用实时语音转写
  static const String xFDefaultAsrUrl = xFRealtimeAsrUrl;

  /// 火山引擎配置
  static const String volcanoAppId = String.fromEnvironment(
    'VOLCANO_APP_ID',
    defaultValue: '', // 需要从火山引擎控制台获取
  );

  static const String volcanoAccessKey = String.fromEnvironment(
    'VOLCANO_ACCESS_KEY',
    defaultValue: '', // 需要从火山引擎控制台获取
  );

  static const String volcanoUri = String.fromEnvironment(
    'VOLCANO_URI',
    defaultValue: 'openspeech.bytedance.com',
  );

  static const String volcanoWsUrl = String.fromEnvironment(
    'VOLCANO_WS_URL',
    defaultValue: 'wss://openspeech.bytedance.com/api/v2/vop?part=&part=rtc.orc.v1',
  );

  /// 检查火山引擎是否已配置
  static bool get isVolcanoConfigured => volcanoAppId.isNotEmpty && volcanoAccessKey.isNotEmpty;

  /// 检查科大讯飞是否已配置
  static bool get isXfyunConfigured => xFAPPID.isNotEmpty && xFAPIKey.isNotEmpty && xFAPISecret.isNotEmpty;

  /// ASR 服务类型选择
  /// 可选值: 'xfyun' (科大讯飞), 'volcano' (火山引擎), 'auto' (自动选择)
  static const String defaultAsrService = String.fromEnvironment(
    'DEFAULT_ASR_SERVICE',
    defaultValue: 'auto', // 默认自动选择
  );

  /// 获取最佳可用的ASR服务
  /// 优先级: 火山引擎 > 科大讯飞
  static String get bestAsrService {
    if (defaultAsrService != 'auto') {
      // 如果用户指定了服务，检查是否可用
      if (defaultAsrService == 'volcano' && isVolcanoConfigured) {
        return 'volcano';
      } else if (defaultAsrService == 'xfyun' && isXfyunConfigured) {
        return 'xfyun';
      } else if (defaultAsrService == 'volcano') {
        // 用户指定了火山引擎但未配置，回退到科大讯飞
        if (isXfyunConfigured) {
          return 'xfyun';
        }
      }
    }

    // 自动选择模式：优先使用火山引擎
    if (isVolcanoConfigured) {
      return 'volcano';
    } else if (isXfyunConfigured) {
      return 'xfyun';
    }

    // 都不可用时，默认科大讯飞（已配置密钥）
    return 'xfyun';
  }

  /// Azure Speech Services配置
  static const String azureSpeechKey = String.fromEnvironment(
    'AZURE_SPEECH_KEY',
    defaultValue: '', // 需要从Azure Portal获取
  );

  static const String azureSpeechRegion = String.fromEnvironment(
    'AZURE_SPEECH_REGION',
    defaultValue: 'eastasia', // 可选: eastasia, southeastasia, westus, eastus等
  );

  /// Azure Speech Services WebSocket URLs
  static String get azureSpeechWsUrl =>
      'wss://$azureSpeechRegion.stt.speech.microsoft.com/speech/recognition/conversation/cognitiveservices/v1';
  static String get azureTranslationWsUrl =>
      'wss://$azureSpeechRegion.s2s.speech.microsoft.com/speech/translation/cognitiveservices/v1';

  /// 检查Azure是否已配置
  static bool get isAzureConfigured => azureSpeechKey.isNotEmpty;

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
