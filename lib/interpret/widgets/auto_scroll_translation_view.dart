import 'package:flutter/material.dart';

/// 自动滚动到底部的翻译显示组件
///
/// 功能：
/// - 新句子到达时自动滚动到底部
/// - 用户手动滚动时暂停自动滚动
/// - 支持奇数行原文、偶数行译文显示
class AutoScrollTranslationView extends StatefulWidget {
  /// 原文句子列表
  final List<String> sourceSentences;

  /// 译文句子列表
  final List<String> targetSentences;

  /// 字体大小
  final double fontSize;

  /// 初始文本
  final String? initialText;

  /// 文本变化回调
  final ValueChanged<String>? onChanged;

  /// 文本提交回调
  final ValueChanged<String>? onSubmitted;

  const AutoScrollTranslationView({
    super.key,
    required this.sourceSentences,
    required this.targetSentences,
    required this.fontSize,
    this.initialText,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  State<AutoScrollTranslationView> createState() =>
      _AutoScrollTranslationViewState();
}

class _AutoScrollTranslationViewState extends State<AutoScrollTranslationView> {
  late ScrollController _scrollController;
  bool _isUserScrolling = false;
  int _lastSentenceCount = 0;
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _lastSentenceCount =
        widget.sourceSentences.length + widget.targetSentences.length;
    // 初始化文本控制器
    _textController = TextEditingController(text: widget.initialText ?? '');
  }

  @override
  void didUpdateWidget(AutoScrollTranslationView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 更新文本控制器内容（如果初始文本变化）
    if (widget.initialText != oldWidget.initialText &&
        widget.initialText != _textController.text) {
      _textController.text = widget.initialText ?? '';
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    }

    // 检测是否有新句子
    final currentCount =
        widget.sourceSentences.length + widget.targetSentences.length;
    final hasNewSentences = currentCount > _lastSentenceCount;
    _lastSentenceCount = currentCount;

    // 如果有新句子且用户没有在手动滚动，则自动滚动到底部
    if (hasNewSentences && !_isUserScrolling && mounted) {
      // 等待两个帧完成，确保布局完全稳定
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _scrollController.hasClients && !_isUserScrolling) {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _handleUserScroll(ScrollNotification notification) {
    // 判断是否应该恢复自动滚动
    final isAtBottom =
        _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50;

    if (isAtBottom) {
      // 用户滚动到底部，恢复自动滚动
      _isUserScrolling = false;
    } else if (notification is ScrollUpdateNotification) {
      // 用户正在滚动且不在底部，暂停自动滚动
      _isUserScrolling = true;
    }
  }

  bool get _hasContent =>
      widget.sourceSentences.isNotEmpty || widget.targetSentences.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    // 构建显示的行
    final List<Widget> lines = [];

    final maxPairs =
        widget.sourceSentences.length > widget.targetSentences.length
        ? widget.sourceSentences.length
        : widget.targetSentences.length;

    for (int i = 0; i < maxPairs; i++) {
      // 奇数行：显示原文
      if (i < widget.sourceSentences.length) {
        lines.add(
          SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                widget.sourceSentences[i],
                style: TextStyle(
                  fontSize: widget.fontSize,
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
      if (i < widget.targetSentences.length) {
        lines.add(
          SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                widget.targetSentences[i],
                style: TextStyle(
                  fontSize: widget.fontSize,
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

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        if (scrollNotification is ScrollUpdateNotification) {
          _handleUserScroll(scrollNotification);
        }
        return false;
      },
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: !_hasContent
            ? Center(
                child: TextField(
                  controller: _textController,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  maxLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    hintText: '源语言/目标语言',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                    hintStyle: TextStyle(fontSize: widget.fontSize),
                  ),
                  style: TextStyle(
                    fontSize: widget.fontSize,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: lines,
              ),
      ),
    );
  }
}

/// 简化版本：使用 ListView.builder 优化性能
class AutoScrollTranslationViewOptimized extends StatefulWidget {
  final List<String> sourceSentences;
  final List<String> targetSentences;
  final double fontSize;
  final bool isEmpty;
  final String? initialText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const AutoScrollTranslationViewOptimized({
    super.key,
    required this.sourceSentences,
    required this.targetSentences,
    required this.fontSize,
    this.isEmpty = true,
    this.initialText,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  State<AutoScrollTranslationViewOptimized> createState() =>
      _AutoScrollTranslationViewOptimizedState();
}

class _AutoScrollTranslationViewOptimizedState
    extends State<AutoScrollTranslationViewOptimized> {
  final ScrollController _scrollController = ScrollController();
  bool _isUserScrolling = false;
  int _lastSentenceCount = 0;
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _lastSentenceCount =
        widget.sourceSentences.length + widget.targetSentences.length;
    _textController = TextEditingController(text: widget.initialText ?? '');
  }

  @override
  void didUpdateWidget(AutoScrollTranslationViewOptimized oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 更新文本控制器内容（如果初始文本变化）
    if (widget.initialText != oldWidget.initialText &&
        widget.initialText != _textController.text) {
      _textController.text = widget.initialText ?? '';
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    }

    final currentCount =
        widget.sourceSentences.length + widget.targetSentences.length;
    final hasNewSentences = currentCount > _lastSentenceCount;
    _lastSentenceCount = currentCount;

    // 如果有新句子且用户没有在手动滚动，则自动滚动到底部
    if (hasNewSentences && !_isUserScrolling && mounted) {
      // 等待两个帧完成，确保布局完全稳定
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _scrollController.hasClients && !_isUserScrolling) {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  bool get _hasContent =>
      widget.sourceSentences.isNotEmpty || widget.targetSentences.isNotEmpty;

  int get _itemCount {
    final maxPairs =
        widget.sourceSentences.length > widget.targetSentences.length
        ? widget.sourceSentences.length
        : widget.targetSentences.length;
    return maxPairs * 2; // 每个pair有2行
  }

  Widget _buildItem(int index) {
    final pairIndex = index ~/ 2;
    final isSource = index % 2 == 0;

    if (isSource) {
      // 原文行
      if (pairIndex < widget.sourceSentences.length) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Text(
            widget.sourceSentences[pairIndex],
            style: TextStyle(
              fontSize: widget.fontSize,
              color: Colors.black54,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        );
      }
    } else {
      // 译文行
      if (pairIndex < widget.targetSentences.length) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Text(
            widget.targetSentences[pairIndex],
            style: TextStyle(
              fontSize: widget.fontSize,
              color: Colors.black87,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        if (scrollNotification is ScrollUpdateNotification) {
          final isAtBottom =
              _scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 50;

          if (isAtBottom) {
            setState(() {
              _isUserScrolling = false;
            });
          } else {
            setState(() {
              _isUserScrolling = true;
            });
          }
        }
        return false;
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        itemCount: !_hasContent && _itemCount == 0 ? 1 : _itemCount,
        itemBuilder: (context, index) {
          if (!_hasContent && _itemCount == 0) {
            return Center(
              child: TextField(
                controller: _textController,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                maxLines: null,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: '源语言/目标语言',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                  hintStyle: TextStyle(fontSize: widget.fontSize),
                ),
                style: TextStyle(
                  fontSize: widget.fontSize,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
            );
          }
          return _buildItem(index);
        },
      ),
    );
  }
}
