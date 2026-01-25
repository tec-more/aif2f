import 'package:aif2f/core/config/alignment_config.dart';
import 'package:aif2f/core/utils/sentence_aligner.dart';
import 'package:flutter/material.dart';

/// 对齐算法使用示例
class AlignmentExampleView extends StatelessWidget {
  const AlignmentExampleView({super.key});

  /// 示例1: 使用自适应对齐（推荐）
  Widget _buildAdaptiveAlignment(BuildContext context) {
    // 原文和译文
    const sourceText = "你好。这是一个测试。我们有三个句子。";
    const targetText = "Hello. This is a test.";

    // 分割成句子
    final sourceSentences = SentenceAligner.splitIntoSentences(sourceText);
    final targetSentences = SentenceAligner.splitIntoSentences(targetText);

    // 使用自适应对齐
    final result = AlignmentAlgorithm.adaptive.align(sourceSentences, targetSentences);

    return Column(
      children: [
        Text('算法: ${result.algorithm} (置信度: ${result.confidence}%)'),
        ...result.pairs.map((pair) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 奇数行：原文
              if (pair.source.isNotEmpty)
                Text(
                  pair.source,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                  ),
                ),
              // 偶数行：译文
              if (pair.target != null)
                Text(
                  pair.target!,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        )),
      ],
    );
  }

  /// 示例2: 在现有的 O2S 视图中使用
  static List<Widget> buildAlignedLines({
    required String sourceText,
    required String targetText,
    required AlignmentAlgorithm algorithm,
    required double fontSize,
  }) {
    // 分割句子
    final sourceSentences = SentenceAligner.splitIntoSentences(sourceText);
    final targetSentences = SentenceAligner.splitIntoSentences(targetText);

    // 执行对齐
    final result = algorithm.align(sourceSentences, targetSentences);

    // 构建显示的行
    final lines = <Widget>[];

    for (final pair in result.pairs) {
      // 奇数行：显示原文
      if (pair.source.isNotEmpty) {
        lines.add(
          SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                pair.source,
                style: TextStyle(
                  fontSize: fontSize,
                  color: Colors.black54,
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        );
      }

      // 偶数行：显示译文
      if (pair.target != null && pair.target!.isNotEmpty) {
        lines.add(
          SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                pair.target!,
                style: TextStyle(
                  fontSize: fontSize,
                  color: Colors.black87,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }
    }

    return lines;
  }

  /// 示例3: 比较不同算法的效果
  Widget _buildAlgorithmComparison(BuildContext context) {
    const sourceText = "第一句。第二句。第三句。第四句。";
    const targetText = "Sentence 1. Sentence 2.";

    final sourceSentences = SentenceAligner.splitIntoSentences(sourceText);
    final targetSentences = SentenceAligner.splitIntoSentences(targetText);

    return ListView(
      children: [
        _buildAlgorithmCard(
          context,
          '简单索引对齐',
          AlignmentAlgorithm.simpleIndex.align(sourceSentences, targetSentences),
        ),
        _buildAlgorithmCard(
          context,
          '智能填充对齐',
          AlignmentAlgorithm.padding.align(sourceSentences, targetSentences),
        ),
        _buildAlgorithmCard(
          context,
          'DTW对齐',
          AlignmentAlgorithm.dtw.align(sourceSentences, targetSentences),
        ),
        _buildAlgorithmCard(
          context,
          '基于长度对齐',
          AlignmentAlgorithm.lengthBased.align(sourceSentences, targetSentences),
        ),
        _buildAlgorithmCard(
          context,
          '自适应对齐',
          AlignmentAlgorithm.adaptive.align(sourceSentences, targetSentences),
        ),
      ],
    );
  }

  Widget _buildAlgorithmCard(BuildContext context, String title, AlignmentResult result) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$title (置信度: ${result.confidence}%)',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...result.pairs.map((pair) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Text('${pair.source} → ${pair.target ?? "(空)"}'),
            )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('对齐算法示例')),
      body: _buildAdaptiveAlignment(context),
    );
  }
}

/// ============================================
/// 如何在现有代码中集成对齐算法
/// ============================================
///
/// 步骤1: 在 interpret_view.dart 中导入
/// ```dart
/// import 'package:aif2f/core/utils/sentence_aligner.dart';
/// import 'package:aif2f/core/config/alignment_config.dart';
/// ```
///
/// 步骤2: 在 ViewModel 中添加配置
/// ```dart
/// class InterpretState {
///   final AlignmentAlgorithm alignmentAlgorithm;
///
///   const InterpretState({
///     this.alignmentAlgorithm = AlignmentAlgorithm.adaptive,
///     // ... 其他字段
///   });
/// }
/// ```
///
/// 步骤3: 替换现有的 _buildO2STextField 方法
/// ```dart
/// Widget _buildO2STextField(BuildContext context, WidgetRef ref, int type) {
///   final state = ref.watch(interpretViewModelProvider);
///   final inputText = type == 1 ? state.inputOneText : state.inputTwoText;
///   final translatedText = type == 1
///       ? state.translatedOneText
///       : state.translatedTwoText;
///   final fontSize = type == 1 ? state.onefontSize : state.twofontSize;
///
///   // 使用新的对齐算法
///   final lines = AlignmentExampleView.buildAlignedLines(
///     sourceText: inputText,
///     targetText: translatedText,
///     algorithm: state.alignmentAlgorithm,
///     fontSize: fontSize,
///   );
///
///   return Card(
///     // ... 其他 UI 代码
///     child: SingleChildScrollView(
///       child: inputText.isEmpty && translatedText.isEmpty
///           ? Center(child: TextField(...))
///           : Column(
///               crossAxisAlignment: CrossAxisAlignment.start,
///               children: lines,
///             ),
///     ),
///   );
/// }
/// ```
///
/// 步骤4: 添加算法选择器（可选）
/// ```dart
/// Widget _buildAlgorithmSelector(BuildContext context, WidgetRef ref) {
///   final state = ref.watch(interpretViewModelProvider);
///
///   return DropdownButton<AlignmentAlgorithm>(
///     value: state.alignmentAlgorithm,
///     items: AlignmentAlgorithm.values.map((algo) {
///       return DropdownMenuItem(
///         value: algo,
///         child: Column(
///           crossAxisAlignment: CrossAxisAlignment.start,
///           children: [
///             Text(algo.name),
///             Text(
///               algo.description,
///               style: Theme.of(context).textTheme.bodySmall,
///             ),
///           ],
///         ),
///       );
///     }).toList(),
///     onChanged: (algorithm) {
///       if (algorithm != null) {
///         ref.read(interpretViewModelProvider.notifier)
///             .setAlignmentAlgorithm(algorithm);
///       }
///     },
///   );
/// }
/// ```
///
/// ============================================
/// 算法选择建议
/// ============================================
///
/// 1. **实时翻译场景** (推荐)
///    - 使用: AlignmentAlgorithm.lengthBased
///    - 原因: 性能好，适合流式数据
///    - 配置: AlignmentConfig.highPerformance()
///
/// 2. **离线翻译场景** (高质量)
///    - 使用: AlignmentAlgorithm.dtw
///    - 原因: 最准确的对齐效果
///    - 配置: AlignmentConfig.highQuality()
///
/// 3. **不确定场景** (推荐)
///    - 使用: AlignmentAlgorithm.adaptive
///    - 原因: 自动选择最佳算法
///    - 配置: AlignmentConfig.defaultConfig()
///
/// 4. **句子数量相近** (简单场景)
///    - 使用: AlignmentAlgorithm.simpleIndex
///    - 原因: 最快，代码最简单
///
/// ============================================
