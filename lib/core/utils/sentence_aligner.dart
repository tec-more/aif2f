/// 句子对
class SentencePair {
  final String source;
  final String? target;
  final int sourceIndex;
  final int? targetIndex;

  SentencePair({
    required this.source,
    this.target,
    required this.sourceIndex,
    this.targetIndex,
  });

  @override
  String toString() {
    return 'SentencePair(source: "$source", target: "$target")';
  }
}

/// 对齐结果
class AlignmentResult {
  final List<SentencePair> pairs;
  final String algorithm;
  final int confidence;

  AlignmentResult({
    required this.pairs,
    required this.algorithm,
    this.confidence = 100,
  });
}

/// 句子对齐算法
class SentenceAligner {
  /// 算法1: 简单索引对齐（当前实现）
  ///
  /// 优点: 简单快速
  /// 缺点: 当句子数量不匹配时会丢失内容
  static AlignmentResult alignByIndex(List<String> source, List<String> target) {
    final pairs = <SentencePair>[];
    final maxLen = source.length > target.length ? source.length : target.length;

    for (int i = 0; i < maxLen; i++) {
      pairs.add(SentencePair(
        source: i < source.length ? source[i] : '',
        target: i < target.length ? target[i] : null,
        sourceIndex: i,
        targetIndex: i < target.length ? i : null,
      ));
    }

    return AlignmentResult(
      pairs: pairs,
      algorithm: 'Index Alignment',
      confidence: 60,
    );
  }

  /// 算法2: 智能填充对齐
  ///
  /// 优点: 保证所有句子都显示，不会丢失内容
  /// 缺点: 可能有空行
  static AlignmentResult alignWithPadding(List<String> source, List<String> target) {
    final pairs = <SentencePair>[];

    // 如果源文本更多
    if (source.length >= target.length) {
      for (int i = 0; i < source.length; i++) {
        // 尝试将目标句子分配到对应的源句子
        final targetIndex = (i * target.length / source.length).floor();
        pairs.add(SentencePair(
          source: source[i],
          target: targetIndex < target.length ? target[targetIndex] : null,
          sourceIndex: i,
          targetIndex: targetIndex < target.length ? targetIndex : null,
        ));
      }
    } else {
      // 如果目标文本更多，尽可能均匀分布
      for (int i = 0; i < target.length; i++) {
        final sourceIndex = (i * source.length / target.length).floor();
        // 避免重复添加源句子
        if (pairs.isEmpty || pairs.last.sourceIndex != sourceIndex) {
          pairs.add(SentencePair(
            source: source[sourceIndex],
            target: target[i],
            sourceIndex: sourceIndex,
            targetIndex: i,
          ));
        } else {
          // 将多个目标句子合并到同一个源句子
          pairs.last = SentencePair(
            source: pairs.last.source,
            target: '${pairs.last.target}\n${target[i]}',
            sourceIndex: pairs.last.sourceIndex,
            targetIndex: i,
          );
        }
      }
    }

    return AlignmentResult(
      pairs: pairs,
      algorithm: 'Padding Alignment',
      confidence: 75,
    );
  }

  /// 算法3: 动态时间规整(DTW)对齐
  ///
  /// 优点: 找到最佳的全局对齐方式
  /// 缺点: 计算复杂度较高 O(n*m)
  static AlignmentResult alignWithDTW(List<String> source, List<String> target) {
    if (source.isEmpty || target.isEmpty) {
      return alignWithPadding(source, target);
    }

    final n = source.length;
    final m = target.length;

    // 创建距离矩阵
    final List<List<double>> distanceMatrix = List.generate(
      n + 1,
      (i) => List.generate(m + 1, (j) => double.infinity),
    );

    distanceMatrix[0][0] = 0;

    // 计算累积距离
    for (int i = 1; i <= n; i++) {
      for (int j = 1; j <= m; j++) {
        final cost = _calculateSentenceDistance(source[i - 1], target[j - 1]);
        distanceMatrix[i][j] = cost +
            [
              distanceMatrix[i - 1][j],     // 删除
              distanceMatrix[i][j - 1],     // 插入
              distanceMatrix[i - 1][j - 1], // 匹配
            ].reduce((a, b) => a < b ? a : b);
      }
    }

    // 回溯找出最优路径
    final pairs = <SentencePair>[];
    int i = n, j = m;

    while (i > 0 || j > 0) {
      if (i > 0 && j > 0 &&
          distanceMatrix[i][j] ==
              distanceMatrix[i - 1][j - 1] + _calculateSentenceDistance(source[i - 1], target[j - 1])) {
        // 匹配
        pairs.insert(0, SentencePair(
          source: source[i - 1],
          target: target[j - 1],
          sourceIndex: i - 1,
          targetIndex: j - 1,
        ));
        i--;
        j--;
      } else if (i > 0 &&
          distanceMatrix[i][j] == distanceMatrix[i - 1][j] + 1.0) {
        // 删除（源句子没有对应的译文）
        pairs.insert(0, SentencePair(
          source: source[i - 1],
          target: null,
          sourceIndex: i - 1,
          targetIndex: null,
        ));
        i--;
      } else {
        // 插入（译文没有对应的源句子）
        pairs.insert(0, SentencePair(
          source: '',
          target: target[j - 1],
          sourceIndex: -1,
          targetIndex: j - 1,
        ));
        j--;
      }
    }

    return AlignmentResult(
      pairs: pairs,
      algorithm: 'DTW Alignment',
      confidence: 90,
    );
  }

  /// 算法4: 基于长度的智能对齐（推荐用于实时翻译）
  ///
  /// 优点: 适合实时场景，性能好，结果合理
  /// 缺点: 需要调优参数
  static AlignmentResult alignByLength(List<String> source, List<String> target) {
    if (source.isEmpty || target.isEmpty) {
      return alignWithPadding(source, target);
    }

    final pairs = <SentencePair>[];

    // 如果长度相近，使用1:1对齐
    if ((source.length - target.length).abs() <= 1) {
      return alignByIndex(source, target);
    }

    // 使用比例分配
    final ratio = source.length / target.length;
    int targetIndex = 0;

    for (int i = 0; i < source.length; i++) {
      // 计算当前源句子应该对应的目标句子索引
      final expectedTargetIndex = (i / ratio).round();

      // 收集所有应该映射到当前源句子的目标句子
      final targetBuffer = <String>[];
      final targetIndices = <int>[];

      while (targetIndex < target.length && targetIndex <= expectedTargetIndex) {
        targetBuffer.add(target[targetIndex]);
        targetIndices.add(targetIndex);
        targetIndex++;
      }

      pairs.add(SentencePair(
        source: source[i],
        target: targetBuffer.isEmpty ? null : targetBuffer.join('\n'),
        sourceIndex: i,
        targetIndex: targetIndices.isEmpty ? null : targetIndices.first,
      ));
    }

    // 添加剩余的目标句子
    while (targetIndex < target.length) {
      pairs.add(SentencePair(
        source: '',
        target: target[targetIndex],
        sourceIndex: -1,
        targetIndex: targetIndex,
      ));
      targetIndex++;
    }

    return AlignmentResult(
      pairs: pairs,
      algorithm: 'Length-Based Alignment',
      confidence: 85,
    );
  }

  /// 算法5: 自适应对齐（推荐用于混合场景）
  ///
  /// 根据文本特征自动选择最佳算法
  static AlignmentResult alignAdaptive(List<String> source, List<String> target) {
    // 如果句子数量相近，使用简单对齐
    if ((source.length - target.length).abs() <= 1) {
      return alignByIndex(source, target);
    }

    // 如果数量差异较大但都不多，使用DTW
    if (source.length < 20 && target.length < 20) {
      return alignWithDTW(source, target);
    }

    // 否则使用基于长度的对齐
    return alignByLength(source, target);
  }

  /// 计算两个句子的距离（用于DTW）
  static double _calculateSentenceDistance(String s1, String s2) {
    // 简单的长度差异作为距离度量
    // 实际应用中可以使用更复杂的算法（如编辑距离、语义相似度等）
    final len1 = s1.length;
    final len2 = s2.length;
    return (len1 - len2).abs() / (len1 + len2 + 1);
  }

  /// 将文本分割成句子（改进版）
  static List<String> splitIntoSentences(String text) {
    if (text.isEmpty) return [];

    // 扩展的分隔符：句号、问号、感叹号、省略号
    final pattern = RegExp(r'[。.！!?？\n]+');
    final sentences = text.split(pattern);

    return sentences
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }
}
