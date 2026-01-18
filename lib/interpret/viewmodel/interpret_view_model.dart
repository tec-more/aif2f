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
  bool _isConnected = false;
  String _statusMessage = '';
  String _inputText = '';
  String _translatedText = '';

  // 流订阅
  StreamSubscription<String>? _translationSubscription;
  StreamSubscription<String>? _errorSubscription;
  StreamSubscription<String>? _recognizedTextSubscription;

  // Getters
  TranslationResult? get currentTranslation => _currentTranslation;
  bool get isProcessing => _isProcessing;
  bool get isConnected => _isConnected;
  String get statusMessage => _statusMessage;
  String get inputText => _inputText;
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
          sourceText: _inputText,
          targetText: _translatedText,
          sourceLanguage: config.sourceLanguage,
          targetLanguage: config.targetLanguage,
        );
        notifyListeners();
      },
      onError: (error) {
        debugPrint('翻译流错误: $error');
        _statusMessage = '翻译错误: $error';
        _isProcessing = false;
        notifyListeners();
      },
    );

    // 监听识别文本流
    _recognizedTextSubscription = _translationService.recognizedTextStream
        .listen(
          (transcript) {
            _inputText = transcript;
            notifyListeners();
          },
          onError: (error) {
            debugPrint('识别文本流错误: $error');
          },
        );

    // 监听错误流
    _errorSubscription = _translationService.errorStream.listen((error) {
      _statusMessage = '错误: $error';
      _isProcessing = false;
      notifyListeners();
    });
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

  /// 翻译文本
  Future<void> translateText(String text) async {
    if (text.isEmpty || _isProcessing) return;

    _inputText = text;
    _translatedText = ''; // 清空之前的翻译
    _isProcessing = true;
    _statusMessage = '正在翻译...';
    notifyListeners();

    try {
      _translationService.sendTextMessage(text);
      // 翻译结果会通过 stream 异步返回
    } catch (e) {
      _statusMessage = '翻译失败: $e';
      _isProcessing = false;
      debugPrint('翻译错误: $e');
      notifyListeners();
    }
  }

  /// 设置源语言
  void setSourceLanguage(String language) {
    config.sourceLanguage = language;
    notifyListeners();
  }

  /// 设置目标语言
  void setTargetLanguage(String language) {
    config.targetLanguage = language;
    notifyListeners();
  }

  /// 同时设置源语言和目标语言（推荐使用）
  Future<void> setLanguages(
    String sourceLanguage,
    String targetLanguage,
  ) async {
    config.sourceLanguage = sourceLanguage;
    config.targetLanguage = targetLanguage;

    // 更新翻译服务的语言配置
    if (_isConnected) {
      final sourceCode = _languageCodeMap[sourceLanguage] ?? 'zh';
      final targetCode = _languageCodeMap[targetLanguage] ?? 'en';
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
    final tempText = _inputText;
    _inputText = _translatedText;
    _translatedText = tempText;

    _currentTranslation = TranslationResult(
      sourceText: _inputText,
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
    _inputText = '';
    _translatedText = '';
    _currentTranslation = null;
    notifyListeners();
  }

  /// 开始录音和实时翻译
  Future<void> startRecording() async {
    if (_isProcessing) return;

    _inputText = '';
    _translatedText = '';
    _isProcessing = true;
    _statusMessage = '正在录音...';
    notifyListeners();

    try {
      final success = await _translationService.startStreaming();
      if (!success) {
        _isProcessing = false;
        _statusMessage = '开始录音失败';
        notifyListeners();
      }
    } catch (e) {
      _statusMessage = '录音失败: $e';
      _isProcessing = false;
      debugPrint('录音错误: $e');
      notifyListeners();
    }
  }

  /// 停止录音和翻译
  Future<void> stopRecording() async {
    if (!_isProcessing) return;

    try {
      await _translationService.stopStreaming();
      _isProcessing = false;
      _statusMessage = '录音已停止';
      notifyListeners();
    } catch (e) {
      _statusMessage = '停止录音失败: $e';
      debugPrint('停止录音错误: $e');
      notifyListeners();
    }
  }

  /// 切换录音状态
  Future<void> toggleRecording() async {
    if (_isProcessing) {
      await stopRecording();
    } else {
      await startRecording();
    }
  }

  @override
  void dispose() {
    _translationSubscription?.cancel();
    _errorSubscription?.cancel();
    _recognizedTextSubscription?.cancel();

    _currentTranslation = null;
    // 注意：不能在这里 await，因为 dispose 不应该是 async 的
    _translationService.dispose();
    super.dispose();
  }
}
