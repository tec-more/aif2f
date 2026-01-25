import 'package:aif2f/core/utils/sentence_aligner.dart';

/// 句子对管理器
///
/// 解决问题：原文和译文返回时机不同步
class SentencePairManager {
  /// 存储句子对的列表
  final List<SentencePair> _pairs = [];

  /// 添加原文句子
  void addSource(String text, {bool isFinal = true}) {
    if (!isFinal) return; // 跳过中间结果

    // 查找是否有对应的空译文句子
    final existingIndex = _pairs.indexWhere((p) => p.target == null && p.source.isEmpty);

    if (existingIndex >= 0) {
      // 找到了空的原文位置，填充
      _pairs[existingIndex] = SentencePair(
        source: text,
        target: null,
        sourceIndex: _pairs[existingIndex].sourceIndex,
        targetIndex: null,
      );
    } else {
      // 添加新的原文句子
      _pairs.add(SentencePair(
        source: text,
        target: null,
        sourceIndex: _pairs.length,
        targetIndex: null,
      ));
    }
  }

  /// 添加译文句子
  void addTarget(String text, {bool isFinal = true}) {
    if (!isFinal) return; // 跳过中间结果

    // 查找是否有等待译文的原文句子
    final existingIndex = _pairs.indexWhere((p) => p.target == null);

    if (existingIndex >= 0) {
      // 找到了等待的原文句子，填充译文
      _pairs[existingIndex] = SentencePair(
        source: _pairs[existingIndex].source,
        target: text,
        sourceIndex: _pairs[existingIndex].sourceIndex,
        targetIndex: existingIndex,
      );
    } else {
      // 没有等待的原文，译文先到了
      _pairs.add(SentencePair(
        source: '',
        target: text,
        sourceIndex: -1,
        targetIndex: _pairs.length - 1,
      ));
    }
  }

  /// 获取所有句子对
  List<SentencePair> get pairs => List.unmodifiable(_pairs);

  /// 获取格式化后的文本（用于显示）
  String get sourceText => _pairs
      .where((p) => p.source.isNotEmpty)
      .map((p) => p.source)
      .join('。');

  String get targetText => _pairs
      .where((p) => p.target != null && p.target!.isNotEmpty)
      .map((p) => p.target!)
      .join('。');

  /// 清空所有句子对
  void clear() {
    _pairs.clear();
  }

  /// 获取句子对数量
  int get length => _pairs.length;
}

/// 改进的文本分割器
class ImprovedTextSplitter {
  /// 使用正则表达式分割句子
  /// 支持：中文。英文. 以及混合情况
  static List<String> splitSentences(String text) {
    if (text.isEmpty) return [];

    // 匹配：中文句号、英文句点、问号、感叹号
    final pattern = RegExp(r'[。.！!?？]+');
    final sentences = text.split(pattern);

    return sentences
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// 智能分割 - 保留分隔符信息
  static List<SentenceWithSeparator> splitWithSeparators(String text) {
    if (text.isEmpty) return [];

    final result = <SentenceWithSeparator>[];
    final pattern = RegExp(r'([。.！!?？]+)');

    int lastIndex = 0;
    for (final match in pattern.allMatches(text)) {
      // 提取句子内容
      final sentence = text.substring(lastIndex, match.start).trim();
      if (sentence.isNotEmpty) {
        result.add(SentenceWithSeparator(
          text: sentence,
          separator: match.group(0)!,
        ));
      }
      lastIndex = match.end;
    }

    // 处理最后一段（没有结束标点）
    if (lastIndex < text.length) {
      final lastPart = text.substring(lastIndex).trim();
      if (lastPart.isNotEmpty) {
        result.add(SentenceWithSeparator(
          text: lastPart,
          separator: '',
        ));
      }
    }

    return result;
  }
}

/// 带分隔符的句子
class SentenceWithSeparator {
  final String text;
  final String separator;

  SentenceWithSeparator({required this.text, required this.separator});

  /// 完整句子（带分隔符）
  String get fullText => separator.isEmpty ? text : '$text$separator';
}

/// 使用示例
class SentencePairExample {
  static void demo() {
    final manager = SentencePairManager();

    // 场景1：原文先到
    manager.addSource("你好");
    print("原文1句，译文0句: ${manager.length}"); // 1

    manager.addTarget("Hello");
    print("原文1句，译文1句: ${manager.length}"); // 1

    manager.addSource("世界");
    manager.addSource("测试");
    print("原文3句，译文1句: ${manager.length}"); // 3

    manager.addTarget("World");
    manager.addTarget("Test");
    print("原文3句，译文3句: ${manager.length}"); // 3

    // 获取所有句子对
    for (final pair in manager.pairs) {
      print("${pair.source} → ${pair.target}");
    }
    // 输出:
    // 你好 → Hello
    // 世界 → World
    // 测试 → Test
  }
}
