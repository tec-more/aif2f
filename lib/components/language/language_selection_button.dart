import 'package:flutter/material.dart';

/// 语言选择按钮组件
/// 提供语言选择功能的通用组件
class LanguageSelectionButton extends StatelessWidget {
  /// 源语言
  final String sourceLanguage;

  /// 目标语言
  final String targetLanguage;

  /// 语言代码映射表 (完整语言名称 -> 语言代码)
  final Map<String, String> languageCodes;

  /// 点击事件回调
  final VoidCallback onPressed;

  /// 组件宽度
  final double width;

  /// 组件高度
  final double height;

  /// 主色调
  final Color? primaryColor;

  /// 构造函数
  const LanguageSelectionButton({
    super.key,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.languageCodes,
    required this.onPressed,
    this.width = 200,
    this.height = 44,
    this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
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
                _buildLanguageText(context, sourceLanguage, color),
                Icon(Icons.compare_arrows_rounded, color: color, size: 16),
                _buildLanguageText(context, targetLanguage, color),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageText(
    BuildContext context,
    String language,
    Color color,
  ) {
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
