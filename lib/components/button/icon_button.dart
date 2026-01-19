import 'package:flutter/material.dart';

/// 图标按钮组件
/// 用于显示带图标的按钮
class IconButtonWidget extends StatelessWidget {
  /// 按钮图标
  final IconData icon;

  /// 点击事件回调
  final VoidCallback onPressed;

  /// 按钮宽度
  final double width;

  /// 按钮高度
  final double height;

  /// 是否禁用
  final bool isDisabled;

  /// 主色调
  final Color? primaryColor;

  /// 图标颜色
  final Color? iconColor;

  /// 图标大小
  final double iconSize;

  /// 按钮形状
  final ShapeBorder? shape;

  /// 构造函数
  const IconButtonWidget({
    super.key,
    required this.icon,
    required this.onPressed,
    this.width = 44,
    this.height = 44,
    this.isDisabled = false,
    this.primaryColor,
    this.iconColor = Colors.white,
    this.iconSize = 24,
    this.shape,
  });

  @override
  Widget build(BuildContext context) {
    final color = primaryColor ?? Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton.icon(
        onPressed: isDisabled ? null : onPressed,
        icon: Icon(icon, size: iconSize, color: iconColor),
        label: const SizedBox.shrink(), // 隐藏标签
        style: ElevatedButton.styleFrom(
          backgroundColor: isDisabled ? color.withOpacity(0.5) : color,
          foregroundColor: iconColor,
          shape:
              (shape as OutlinedBorder?) ??
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

/// 圆形图标按钮组件
class CircularIconButton extends StatelessWidget {
  /// 按钮图标
  final IconData icon;

  /// 点击事件回调
  final VoidCallback onPressed;

  /// 按钮大小
  final double size;

  /// 是否禁用
  final bool isDisabled;

  /// 主色调
  final Color? primaryColor;

  /// 图标颜色
  final Color? iconColor;

  /// 图标大小
  final double iconSize;

  /// 构造函数
  const CircularIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 44,
    this.isDisabled = false,
    this.primaryColor,
    this.iconColor = Colors.white,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    final color = primaryColor ?? Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: size,
      height: size,
      child: ElevatedButton.icon(
        onPressed: isDisabled ? null : onPressed,
        icon: Icon(icon, size: iconSize, color: iconColor),
        label: const SizedBox.shrink(),
        style: ElevatedButton.styleFrom(
          backgroundColor: isDisabled ? color.withOpacity(0.5) : color,
          foregroundColor: iconColor,
          shape: const CircleBorder(),
          elevation: 0,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

/// 文本图标按钮组件
class TextIconButton extends StatelessWidget {
  /// 按钮文本
  final String text;

  /// 按钮图标
  final IconData icon;

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

  /// 文本颜色
  final Color? textColor;

  /// 图标颜色
  final Color? iconColor;

  /// 图标位置
  final IconPosition iconPosition;

  /// 图标大小
  final double iconSize;

  /// 图标与文本的间距
  final double iconSpacing;

  /// 构造函数
  const TextIconButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
    this.width,
    this.height = 44,
    this.isDisabled = false,
    this.primaryColor,
    this.textColor = Colors.white,
    this.iconColor = Colors.white,
    this.iconPosition = IconPosition.left,
    this.iconSize = 20,
    this.iconSpacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    final color = primaryColor ?? Theme.of(context).colorScheme.primary;

    final children = <Widget>[
      if (iconPosition == IconPosition.left) ...[
        Icon(icon, size: iconSize, color: iconColor),
        SizedBox(width: iconSpacing),
      ],
      Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      if (iconPosition == IconPosition.right) ...[
        SizedBox(width: iconSpacing),
        Icon(icon, size: iconSize, color: iconColor),
      ],
    ];

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDisabled ? color.withOpacity(0.5) : color,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }
}

/// 图标位置枚举
enum IconPosition { left, right }
