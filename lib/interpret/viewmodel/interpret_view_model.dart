import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_f2f_sound/flutter_f2f_sound.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aif2f/interpret/model/interpret_model.dart';
import 'package:aif2f/core/services/translation_service.dart';

// 状态类
@immutable
class InterpretState {
  final TranslationResult? currentTranslation;
  final bool isProcessing;
  final bool isConnected;
  final bool isSystemSoundEnabled;
  final double onefontSize;
  final double twofontSize;
  final int panelNumber;
  final String oneContentTypes;
  final String twoContentTypes;
  final String statusMessage;
  final String inputOneText;
  final String translatedOneText;
  final String inputTwoText;
  final String translatedTwoText;
  final String sourceOneLanguage;
  final String targetOneLanguage;
  final String sourceTwoLanguage;
  final String targetTwoLanguage;

  const InterpretState({
    this.currentTranslation,
    this.isProcessing = false,
    this.isConnected = false,
    this.isSystemSoundEnabled = false,
    this.onefontSize = 14,
    this.twofontSize = 14,
    this.panelNumber = 2, // 默认显示第二栏(录音) , 1 显示第一栏(系统音频)
    //o2o 只显示源语言，s2s 只显示目标语言，o2s 显示源语言和目标语言，l2l 源语言和目标语言分离
    this.oneContentTypes = 'o2s',
    //o2o 只显示源语言，s2s 只显示目标语言，o2s 显示源语言和目标语言，l2l 源语言和目标语言分离
    this.twoContentTypes = 'o2s',
    this.statusMessage = '',
    this.inputOneText = '',
    this.translatedOneText = '',
    this.inputTwoText = '',
    this.translatedTwoText = '',
    this.sourceOneLanguage = '中文',
    this.targetOneLanguage = '英语',
    this.sourceTwoLanguage = '英语',
    this.targetTwoLanguage = '中文',
  });

  InterpretState copyWith({
    TranslationResult? currentTranslation,
    bool? isProcessing,
    bool? isConnected,
    bool? isSystemSoundEnabled,
    double? onefontSize,
    double? twofontSize,
    int? panelNumber,
    String? oneContentTypes,
    String? twoContentTypes,
    String? statusMessage,
    String? inputOneText,
    String? translatedOneText,
    String? inputTwoText,
    String? translatedTwoText,
    String? sourceOneLanguage,
    String? targetOneLanguage,
    String? sourceTwoLanguage,
    String? targetTwoLanguage,
  }) {
    return InterpretState(
      currentTranslation: currentTranslation ?? this.currentTranslation,
      isProcessing: isProcessing ?? this.isProcessing,
      isConnected: isConnected ?? this.isConnected,
      isSystemSoundEnabled: isSystemSoundEnabled ?? this.isSystemSoundEnabled,
      onefontSize: onefontSize ?? this.onefontSize,
      twofontSize: twofontSize ?? this.twofontSize,
      panelNumber: panelNumber ?? this.panelNumber,
      oneContentTypes: oneContentTypes ?? this.oneContentTypes,
      twoContentTypes: twoContentTypes ?? this.twoContentTypes,
      statusMessage: statusMessage ?? this.statusMessage,
      inputOneText: inputOneText ?? this.inputOneText,
      translatedOneText: translatedTwoText ?? this.translatedOneText,
      inputTwoText: inputTwoText ?? this.inputTwoText,
      translatedTwoText: translatedTwoText ?? this.translatedTwoText,
      sourceOneLanguage: sourceOneLanguage ?? this.sourceOneLanguage,
      targetOneLanguage: targetOneLanguage ?? this.targetOneLanguage,
      sourceTwoLanguage: sourceTwoLanguage ?? this.sourceTwoLanguage,
      targetTwoLanguage: targetTwoLanguage ?? this.targetTwoLanguage,
    );
  }
}

// Provider
final interpretViewModelProvider =
    NotifierProvider.autoDispose<InterpretViewModel, InterpretState>(
      InterpretViewModel.new,
    );

class InterpretViewModel extends Notifier<InterpretState> {
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

  @override
  InterpretState build() {
    // 初始化状态
    return const InterpretState();
  }

  /// 设置输入文本
  void setInputText(String text, [int type = 1]) {
    if (type == 1) {
      state = state.copyWith(inputOneText: text);
    } else {
      state = state.copyWith(inputTwoText: text);
    }
  }

  /// 翻译文本
  Future<void> translateText(String text, [int type = 1]) async {
    if (text.isEmpty || state.isProcessing) return;

    if (type == 1) {
      state = state.copyWith(
        inputOneText: text,
        translatedOneText: '', // 清空之前的翻译
        isProcessing: true,
        statusMessage: '正在翻译...',
      );
    } else {
      state = state.copyWith(
        inputTwoText: text,
        translatedTwoText: '', // 清空之前的翻译
        isProcessing: true,
        statusMessage: '正在翻译...',
      );
    }

    try {
      // _translationService.sendTextMessage(text);
      // 翻译结果会通过 stream 异步返回
    } catch (e) {
      state = state.copyWith(statusMessage: '翻译失败: $e', isProcessing: false);
      debugPrint('翻译错误: $e');
    }
  }

  /// 设置源语言
  void setOneSourceLanguage(String language) {
    state = state.copyWith(sourceOneLanguage: language);
  }

  /// 设置目标语言
  void setOneTargetLanguage(String language) {
    state = state.copyWith(targetOneLanguage: language);
  }

  /// 设置源语言
  void setTwoSourceLanguage(String language) {
    state = state.copyWith(sourceTwoLanguage: language);
  }

  /// 设置目标语言
  void setTwoTargetLanguage(String language) {
    state = state.copyWith(targetTwoLanguage: language);
  }

  /// 同时设置源语言和目标语言（推荐使用）
  Future<void> setLanguages(
    String sourceLanguage,
    String targetLanguage, [
    int type = 1,
  ]) async {
    if (type == 1) {
      setOneSourceLanguage(sourceLanguage);
      setOneTargetLanguage(targetLanguage);
    } else {
      setTwoSourceLanguage(sourceLanguage);
      setTwoTargetLanguage(targetLanguage);
    }
  }

  /// 切换语言
  void swapLanguages([int type = 1]) async {
    final newSourceLanguage = type == 1
        ? state.sourceOneLanguage
        : state.sourceTwoLanguage;
    final newTargetLanguage = type == 1
        ? state.targetOneLanguage
        : state.targetTwoLanguage;
    final newInputOneText = state.translatedOneText;
    final newTranslatedOneText = state.inputOneText;
    debugPrint('切换语言: $newSourceLanguage -> $newTargetLanguage');
    if (type == 1) {
      setOneSourceLanguage(newTargetLanguage);
      setOneTargetLanguage(newSourceLanguage);
    } else {
      setTwoSourceLanguage(newTargetLanguage);
      setTwoTargetLanguage(newSourceLanguage);
    }
    state = state.copyWith(
      // sourceOneLanguage: type == 1
      //     ? newSourceLanguage
      //     : state.sourceOneLanguage,
      // targetOneLanguage: type == 1
      //     ? newTargetLanguage
      //     : state.targetOneLanguage,
      // sourceTwoLanguage: type == 2
      //     ? newSourceLanguage
      //     : state.sourceTwoLanguage,
      // targetTwoLanguage: type == 2
      //     ? newTargetLanguage
      //     : state.targetTwoLanguage,
      inputOneText: newInputOneText,
      translatedOneText: newTranslatedOneText,
    );

    // 更新翻译结果
    final newTranslation = TranslationResult(
      sourceText: newInputOneText,
      targetText: newTranslatedOneText,
      sourceLanguage: newSourceLanguage,
      targetLanguage: newTargetLanguage,
    );
    state = state.copyWith(currentTranslation: newTranslation);
  }

  /// 切换自动播放
  void toggleAutoPlay() {
    // TODO: 实现自动播放功能
  }

  /// 设置API密钥
  void setApiKey(String apiKey) {
    // TODO: 实现 API 密钥设置
  }

  /// 清空翻译结果
  void clearTranslation() {
    state = state.copyWith(
      inputOneText: '',
      translatedOneText: '',
      currentTranslation: null,
    );
  }

  /// 开始录音和实时翻译
  Future<void> startRecording() async {
    if (state.isProcessing) return;

    state = state.copyWith(
      inputOneText: '',
      translatedOneText: '',
      isProcessing: true,
      statusMessage: '正在录音...',
    );

    try {
      // final success = await _translationService.startStreaming();
      // if (!success) {
      //   state = state.copyWith(isProcessing: false, statusMessage: '开始录音失败');
      // }
    } catch (e) {
      state = state.copyWith(statusMessage: '录音失败: $e', isProcessing: false);
      debugPrint('录音错误: $e');
    }
  }

  /// 停止录音和翻译
  Future<void> stopRecording() async {
    if (!state.isProcessing) return;

    try {
      // await _translationService.stopStreaming();
      state = state.copyWith(isProcessing: false, statusMessage: '录音已停止');
    } catch (e) {
      state = state.copyWith(statusMessage: '停止录音失败: $e');
      debugPrint('停止录音错误: $e');
    }
  }

  /// 切换录音状态
  Future<void> toggleRecording() async {
    if (state.isProcessing) {
      await stopRecording();
    } else {
      await startRecording();
    }
  }

  /// 设置文本布局类型
  /// 1 - 单行文本

  void setOneContentTypes(String srcContentTypes) {
    state = state.copyWith(oneContentTypes: srcContentTypes);
  }

  /// 2 - 多行文本
  void setTwoContentTypes(String twoContentTypes) {
    state = state.copyWith(twoContentTypes: twoContentTypes);
  }

  /// 切换系统声音状态
  void toggleSystemSound() {
    state = state.copyWith(isSystemSoundEnabled: !state.isSystemSoundEnabled);
  }

  void setSrcContentTypes(String srcContentTypes) {
    state = state.copyWith(oneContentTypes: srcContentTypes);
  }

  void setTartgetContentTypes(String tartgetContentTypes) {
    state = state.copyWith(twoContentTypes: tartgetContentTypes);
  }

  void setPanelNumber(int panelNumber) {
    state = state.copyWith(panelNumber: panelNumber);
  }

  void setOnefontSize(double onefontSize) {
    state = state.copyWith(onefontSize: onefontSize);
  }

  void setTwofontSize(double twofontSize) {
    state = state.copyWith(twofontSize: twofontSize);
  }
}
