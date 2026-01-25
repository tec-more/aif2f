import 'package:aif2f/core/utils/sentence_aligner.dart';

/// 对齐算法配置
class AlignmentConfig {
  /// 当前使用的对齐算法
  final AlignmentAlgorithm algorithm;

  /// 是否显示调试信息
  final bool showDebugInfo;

  /// 是否显示置信度
  final bool showConfidence;

  const AlignmentConfig({
    this.algorithm = AlignmentAlgorithm.adaptive,
    this.showDebugInfo = false,
    this.showConfidence = false,
  });

  /// 创建默认配置
  const AlignmentConfig.defaultConfig()
    : algorithm = AlignmentAlgorithm.adaptive,
      showDebugInfo = false,
      showConfidence = false;

  /// 创建高性能配置（适合实时翻译）
  const AlignmentConfig.highPerformance()
    : algorithm = AlignmentAlgorithm.lengthBased,
      showDebugInfo = false,
      showConfidence = false;

  /// 创建高质量配置（适合离线翻译）
  const AlignmentConfig.highQuality()
    : algorithm = AlignmentAlgorithm.dtw,
      showDebugInfo = false,
      showConfidence = true;

  AlignmentConfig copyWith({
    AlignmentAlgorithm? algorithm,
    bool? showDebugInfo,
    bool? showConfidence,
  }) {
    return AlignmentConfig(
      algorithm: algorithm ?? this.algorithm,
      showDebugInfo: showDebugInfo ?? this.showDebugInfo,
      showConfidence: showConfidence ?? this.showConfidence,
    );
  }
}

/// 对齐算法枚举
enum AlignmentAlgorithm {
  /// 简单索引对齐（最快）
  simpleIndex,

  /// 智能填充对齐
  padding,

  /// 动态时间规整对齐（最准确）
  dtw,

  /// 基于长度的对齐（推荐用于实时）
  lengthBased,

  /// 自适应对齐（推荐）
  adaptive,
}

/// 对齐算法扩展
extension AlignmentAlgorithmExtension on AlignmentAlgorithm {
  /// 获取算法名称
  String get name {
    switch (this) {
      case AlignmentAlgorithm.simpleIndex:
        return '索引对齐';
      case AlignmentAlgorithm.padding:
        return '填充对齐';
      case AlignmentAlgorithm.dtw:
        return 'DTW对齐';
      case AlignmentAlgorithm.lengthBased:
        return '长度对齐';
      case AlignmentAlgorithm.adaptive:
        return '自适应对齐';
    }
  }

  /// 获取算法描述
  String get description {
    switch (this) {
      case AlignmentAlgorithm.simpleIndex:
        return '简单快速，适合句子数量相近的场景';
      case AlignmentAlgorithm.padding:
        return '保证显示所有内容，适合句子数量差异大的场景';
      case AlignmentAlgorithm.dtw:
        return '最准确的全局对齐，计算量较大';
      case AlignmentAlgorithm.lengthBased:
        return '性能好，适合实时翻译场景';
      case AlignmentAlgorithm.adaptive:
        return '根据场景自动选择最佳算法';
    }
  }

  /// 执行对齐
  AlignmentResult align(List<String> source, List<String> target) {
    switch (this) {
      case AlignmentAlgorithm.simpleIndex:
        return SentenceAligner.alignByIndex(source, target);
      case AlignmentAlgorithm.padding:
        return SentenceAligner.alignWithPadding(source, target);
      case AlignmentAlgorithm.dtw:
        return SentenceAligner.alignWithDTW(source, target);
      case AlignmentAlgorithm.lengthBased:
        return SentenceAligner.alignByLength(source, target);
      case AlignmentAlgorithm.adaptive:
        return SentenceAligner.alignAdaptive(source, target);
    }
  }
}
