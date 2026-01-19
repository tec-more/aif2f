import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aif2f/components/language/language_provider.dart';

/// 语言选择按钮组件
/// 提供语言选择功能的通用组件
class LanguageSelectionButton extends ConsumerWidget {
  /// 点击事件回调
  final VoidCallback? onPressed;

  /// 组件宽度
  final double width;

  /// 组件高度
  final double height;

  /// 主色调
  final Color? primaryColor;

  /// 是否显示交换按钮
  final bool showSwapButton;

  /// 构造函数
  const LanguageSelectionButton({
    super.key,
    this.onPressed,
    this.width = 200,
    this.height = 44,
    this.primaryColor,
    this.showSwapButton = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 从Riverpod获取语言状态
    final languagePair = ref.watch(languageProvider);
    final color = primaryColor ?? Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: width,
      height: height,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              border: Border.all(color: color.withOpacity(0.2), width: 1.0),
              borderRadius: BorderRadius.circular(12),
              color: color.withOpacity(0.1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLanguageText(
                  context,
                  ref,
                  languagePair.sourceLanguage,
                  color,
                ),
                if (showSwapButton) _buildSwapButton(context, ref, color),
                _buildLanguageText(
                  context,
                  ref,
                  languagePair.targetLanguage,
                  color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建交换按钮
  Widget _buildSwapButton(BuildContext context, WidgetRef ref, Color color) {
    return GestureDetector(
      onTap: () {
        // 阻止事件冒泡
        // 交换语言
        ref.read(languageProvider.notifier).swapLanguages();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.swap_horiz, color: color, size: 18),
      ),
    );
  }

  Widget _buildLanguageText(
    BuildContext context,
    WidgetRef ref, // 添加 WidgetRef 参数
    String language,
    Color color,
  ) {
    // 从 Riverpod 获取语言代码映射表
    final languageCodes = ref.watch(languageCodesProvider);

    return Expanded(
      child: Center(
        child: Text(
          languageCodes[language] ?? language,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }
}
