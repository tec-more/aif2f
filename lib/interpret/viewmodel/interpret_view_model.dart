import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:aif2f/interpret/model/interpret_model.dart';
import 'package:aif2f/core/services/audio_capture_service.dart';
import 'package:aif2f/core/services/speech_recognition_service.dart';
import 'package:aif2f/core/services/translation_service.dart';

class InterpretViewModel extends ChangeNotifier {
  final TranslationConfig config;
  TranslationResult? _currentTranslation;
  bool _isRecording = false;
  bool _isProcessing = false;
  String _statusMessage = '';

  // 服务
  final AudioCaptureService _audioService = AudioCaptureService();
  final SpeechRecognitionService _speechService = SpeechRecognitionService();
  final TranslationService _translationService = TranslationService();

  // 状态
  TranslationResult? get currentTranslation => _currentTranslation;
  bool get isRecording => _isRecording;
  bool get isProcessing => _isProcessing;
  String get statusMessage => _statusMessage;

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
    'EN': 'en',
    'ZH': 'zh',
    'JA': 'ja',
    'KO': 'ko',
    'FR': 'fr',
    'DE': 'de',
    'ES': 'es',
    'RU': 'ru',
  };

  InterpretViewModel()
      : config = TranslationConfig(),
        super() {
    // 初始化配置
  }

  /// 开始录音并翻译
  Future<void> startRecordingAndTranslate() async {
    if (_isRecording || _isProcessing) return;

    _isRecording = true;
    _statusMessage = '正在录音...';
    notifyListeners();

    try {
      // 开始录音
      final success = await _audioService.startRecording();
      if (!success) {
        _statusMessage = '录音启动失败';
        _isRecording = false;
        notifyListeners();
        return;
      }
    } catch (e) {
      _statusMessage = '录音错误: $e';
      _isRecording = false;
      notifyListeners();
    }
  }

  /// 停止录音并处理翻译
  Future<void> stopRecordingAndTranslate() async {
    if (!_isRecording) return;

    _isRecording = false;
    _isProcessing = true;
    _statusMessage = '正在处理...';
    notifyListeners();

    try {
      // 停止录音
      final audioPath = await _audioService.stopRecording();
      if (audioPath == null) {
        _statusMessage = '录音保存失败';
        _isProcessing = false;
        notifyListeners();
        return;
      }

      // 语音识别
      _statusMessage = '正在识别语音...';
      notifyListeners();

      final sourceLanguageCode = _languageCodeMap[config.sourceLanguage] ?? 'zh';
      final recognizedText = await _speechService.transcribeAudioMock(
        audioFilePath: audioPath,
        language: sourceLanguageCode,
      );

      if (recognizedText.isEmpty) {
        _statusMessage = '未识别到语音';
        _isProcessing = false;
        notifyListeners();
        return;
      }

      debugPrint('识别到的文本: $recognizedText');

      // 翻译文本
      _statusMessage = '正在翻译...';
      notifyListeners();

      final translatedText = await _translationService.translateTextMock(
        text: recognizedText,
        sourceLanguage: config.sourceLanguage,
        targetLanguage: config.targetLanguage,
      );

      debugPrint('翻译结果: $translatedText');

      // 保存翻译结果
      _currentTranslation = TranslationResult(
        sourceText: recognizedText,
        targetText: translatedText,
        sourceLanguage: config.sourceLanguage,
        targetLanguage: config.targetLanguage,
      );

      _statusMessage = '翻译完成';
      _isProcessing = false;
      notifyListeners();

      // 如果启用自动播放，播放翻译结果
      if (config.isAutoPlay) {
        await playTranslation();
      }
    } catch (e) {
      _statusMessage = '处理失败: $e';
      _isProcessing = false;
      debugPrint('错误: $e');
      notifyListeners();
    }
  }

  /// 取消录音
  Future<void> cancelRecording() async {
    if (_isRecording) {
      await _audioService.cancelRecording();
      _isRecording = false;
      _statusMessage = '已取消';
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
      final translatedText = await _translationService.translateTextMock(
        text: text,
        sourceLanguage: config.sourceLanguage,
        targetLanguage: config.targetLanguage,
      );

      _currentTranslation = TranslationResult(
        sourceText: text,
        targetText: translatedText,
        sourceLanguage: config.sourceLanguage,
        targetLanguage: config.targetLanguage,
      );

      _statusMessage = '翻译完成';
      _isProcessing = false;
      notifyListeners();

      // 如果启用自动播放，播放翻译结果
      if (config.isAutoPlay) {
        await playTranslation();
      }
    } catch (e) {
      _statusMessage = '翻译失败: $e';
      _isProcessing = false;
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

  /// 切换语言
  void swapLanguages() {
    final temp = config.sourceLanguage;
    config.sourceLanguage = config.targetLanguage;
    config.targetLanguage = temp;
    notifyListeners();
  }

  /// 切换自动播放
  void toggleAutoPlay() {
    config.isAutoPlay = !config.isAutoPlay;
    notifyListeners();
  }

  /// 播放翻译结果
  Future<void> playTranslation() async {
    if (_currentTranslation?.targetText == null) return;

    try {
      debugPrint('播放翻译结果: ${_currentTranslation?.targetText}');
      // TODO: 实现TTS功能
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      debugPrint('播放失败: $e');
    }
  }

  /// 设置API密钥
  void setApiKey(String apiKey) {
    _speechService.setApiKey(apiKey);
    _translationService.setApiKey(apiKey);
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}
