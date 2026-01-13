import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:aif2f/interpret/model/interpret_model.dart';
import 'package:aif2f/core/services/translation_service.dart';

class InterpretViewModel extends ChangeNotifier {
  final TranslationConfig config;
  final TranslationService _translationService = TranslationService();

  // 状态
  TranslationResult? _currentTranslation;
  bool _isProcessing = false;
  bool _isRecording = false;
  bool _isConnected = false;
  String _statusMessage = '';
  String _recognizedText = '';
  String _translatedText = '';

  // 流订阅
  StreamSubscription<String>? _translationSubscription;
  StreamSubscription<String>? _recognizedTextSubscription;
  StreamSubscription<String>? _errorSubscription;

  // Getters
  TranslationResult? get currentTranslation => _currentTranslation;
  bool get isProcessing => _isProcessing;
  bool get isRecording => _isRecording;
  bool get isConnected => _isConnected;
  String get statusMessage => _statusMessage;
  String get recognizedText => _recognizedText;
  String get translatedText => _translatedText;

  // 语言代码映射
  final Map<String, String> _languageCodeMap = {
    '英语': 'en',
    '中文': 'zh',
    '日语': 'ja',
    '韩语': 'ko',
    '法语': 'fr',
    '德语': 'de',
    '西班牙语': 'es',
    '俄语': 'ru',
  };

  InterpretViewModel() : config = TranslationConfig(), super() {
    _initializeStreams();
  }

  /// 初始化流监听
  void _initializeStreams() {
    // 监听翻译结果流
    _translationSubscription = _translationService.translationStream.listen(
      (delta) {
        _translatedText += delta;
        _currentTranslation = TranslationResult(
          sourceText: _recognizedText,
          targetText: _translatedText,
          sourceLanguage: config.sourceLanguage,
          targetLanguage: config.targetLanguage,
        );
        notifyListeners();
      },
      onError: (error) {
        debugPrint('翻译流错误: $error');
        _statusMessage = '翻译错误: $error';
        notifyListeners();
      },
    );

    // 监听识别文本流
    _recognizedTextSubscription =
        _translationService.recognizedTextStream.listen(
      (text) {
        _recognizedText = text;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('识别流错误: $error');
      },
    );

    // 监听错误流
    _errorSubscription = _translationService.errorStream.listen(
      (error) {
        _statusMessage = '错误: $error';
        _isProcessing = false;
        notifyListeners();
      },
    );
  }

  /// 初始化并连接到翻译服务
  Future<void> initialize() async {
    try {
      final sourceCode = _languageCodeMap[config.sourceLanguage] ?? 'zh';
      final targetCode = _languageCodeMap[config.targetLanguage] ?? 'en';

      await _translationService.initAndConnect(
        sourceLanguage: sourceCode,
        targetLanguage: targetCode,
      );

      _isConnected = true;
      _statusMessage = '已连接到翻译服务';
      notifyListeners();
    } catch (e) {
      _statusMessage = '连接失败: $e';
      _isConnected = false;
      notifyListeners();
    }
  }

  /// 开始录音翻译
  Future<void> startRecording() async {
    if (_isRecording) return;

    _isProcessing = true;
    _statusMessage = '正在录音翻译...';
    notifyListeners();

    try {
      final success = await _translationService.startStreaming();
      if (success) {
        _isRecording = true;
        _statusMessage = '录音翻译中...';

        // 清空之前的文本
        _recognizedText = '';
        _translatedText = '';
        _currentTranslation = null;

        notifyListeners();
      } else {
        _isProcessing = false;
        _statusMessage = '启动录音失败';
        notifyListeners();
      }
    } catch (e) {
      _isProcessing = false;
      _statusMessage = '录音失败: $e';
      debugPrint('录音失败: $e');
      notifyListeners();
    }
  }

  /// 停止录音翻译
  Future<void> stopRecording() async {
    if (!_isRecording) return;

    _isProcessing = true;
    _statusMessage = '正在停止...';
    notifyListeners();

    try {
      await _translationService.stopStreaming();
      _isRecording = false;
      _isProcessing = false;
      _statusMessage = '翻译完成';
      notifyListeners();
    } catch (e) {
      _isProcessing = false;
      _statusMessage = '停止失败: $e';
      debugPrint('停止失败: $e');
      notifyListeners();
    }
  }

  /// 翻译文本
  Future<void> translateText(String text) async {
    if (text.isEmpty || _isProcessing) return;

    _isProcessing = true;
    _statusMessage = '正在翻译...';
    notifyListeners();

    try {
      // TODO: 实现文本翻译功能
      // 目前 TranslationService 主要用于语音翻译
      // 文本翻译需要单独实现或使用其他 API

      _statusMessage = '翻译完成';
      _isProcessing = false;
      notifyListeners();
    } catch (e) {
      _statusMessage = '翻译失败: $e';
      _isProcessing = false;
      debugPrint('翻译错误: $e');
      notifyListeners();
    }
  }

  /// 设置源语言
  void setSourceLanguage(String language) async {
    config.sourceLanguage = language;

    // 更新翻译服务的语言配置
    if (_isConnected) {
      final sourceCode = _languageCodeMap[language] ?? 'zh';
      final targetCode = _languageCodeMap[config.targetLanguage] ?? 'en';
      _translationService.updateLanguages(sourceCode, targetCode);
    }

    notifyListeners();
  }

  /// 设置目标语言
  void setTargetLanguage(String language) async {
    config.targetLanguage = language;

    // 更新翻译服务的语言配置
    if (_isConnected) {
      final sourceCode = _languageCodeMap[config.sourceLanguage] ?? 'zh';
      final targetCode = _languageCodeMap[language] ?? 'en';
      _translationService.updateLanguages(sourceCode, targetCode);
    }

    notifyListeners();
  }

  /// 切换语言
  void swapLanguages() async {
    final temp = config.sourceLanguage;
    config.sourceLanguage = config.targetLanguage;
    config.targetLanguage = temp;

    // 更新翻译服务的语言配置
    if (_isConnected) {
      final sourceCode = _languageCodeMap[config.sourceLanguage] ?? 'zh';
      final targetCode = _languageCodeMap[config.targetLanguage] ?? 'en';
      _translationService.updateLanguages(sourceCode, targetCode);
    }

    // 交换文本
    final tempText = _recognizedText;
    _recognizedText = _translatedText;
    _translatedText = tempText;

    _currentTranslation = TranslationResult(
      sourceText: _recognizedText,
      targetText: _translatedText,
      sourceLanguage: config.sourceLanguage,
      targetLanguage: config.targetLanguage,
    );

    notifyListeners();
  }

  /// 切换自动播放
  void toggleAutoPlay() {
    config.isAutoPlay = !config.isAutoPlay;
    notifyListeners();
  }

  /// 设置API密钥
  void setApiKey(String apiKey) {
    // TODO: 实现 API 密钥设置
  }

  /// 清空翻译结果
  void clearTranslation() {
    _recognizedText = '';
    _translatedText = '';
    _currentTranslation = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _translationSubscription?.cancel();
    _recognizedTextSubscription?.cancel();
    _errorSubscription?.cancel();

    _currentTranslation = null;
    // 注意：不能在这里 await，因为 dispose 不应该是 async 的
    _translationService.dispose();
    super.dispose();
  }
}
