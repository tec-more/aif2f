import 'package:flutter/material.dart';

/// 主色调按钮组件
class PrimaryButton extends StatelessWidget {
  /// 按钮文本
  final String text;

  /// 点击事件回调
  final VoidCallback onPressed;

  /// 按钮宽度
  final double? width;

  /// 按钮高度
  final double height;

  /// 是否禁用
  final bool isDisabled;

  /// 主色调
  final Color? primaryColor;

  /// 构造函数
  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.width,
    this.height = 44,
    this.isDisabled = false,
    this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = primaryColor ?? Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDisabled ? color.withOpacity(0.5) : color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
