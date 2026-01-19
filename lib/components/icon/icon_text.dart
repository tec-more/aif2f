import 'package:flutter/material.dart';

// 自定义双面板图标 - 两个左右排列的空心矩形框
class _TwoPanelsIcon extends StatelessWidget {
  const _TwoPanelsIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(24, 24), painter: _TwoPanelsPainter());
  }
}

class _TwoPanelsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 计算每个方框的大小
    final boxWidth = (size.width - 6) / 2; // 两个框，中间间隔2
    final boxHeight = size.height - 4;

    // 绘制左边的方框
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 2, boxWidth, boxHeight),
        const Radius.circular(2),
      ),
      paint,
    );

    // 绘制右边的方框
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(boxWidth + 4, 2, boxWidth, boxHeight),
        const Radius.circular(2),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 文本布局1 - 分为上下两部分，上面部分左边是一个实心矩形，右边在分为上下2行，上面是一个长横线，下面是一个短横线；
// 下面部分同上面部分
class _TextLayout1Icon extends StatelessWidget {
  const _TextLayout1Icon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(24, 24),
      painter: _TextLayout1Painter(),
    );
  }
}

class _TextLayout1Painter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // 分为上下两部分
    final halfHeight = size.height / 2;
    final padding = 2.0;
    final rectWidth = 6.0;
    final rectHeight = halfHeight - padding * 2;

    // 上半部分
    // 左边：实心矩形
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(padding, padding, rectWidth, rectHeight),
        const Radius.circular(1),
      ),
      fillPaint,
    );

    // 右边上方：长横线
    canvas.drawLine(
      Offset(padding + rectWidth + 2, halfHeight / 2 - 2),
      Offset(size.width - padding, halfHeight / 2 - 2),
      strokePaint,
    );

    // 右边下方：短横线
    canvas.drawLine(
      Offset(padding + rectWidth + 2, halfHeight / 2 + 2),
      Offset(size.width - 6, halfHeight / 2 + 2),
      strokePaint,
    );

    // 下半部分
    // 左边：实心矩形
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(padding, halfHeight + padding, rectWidth, rectHeight),
        const Radius.circular(1),
      ),
      fillPaint,
    );

    // 右边上方：长横线
    canvas.drawLine(
      Offset(padding + rectWidth + 2, halfHeight + halfHeight / 2 - 2),
      Offset(size.width - padding, halfHeight + halfHeight / 2 - 2),
      strokePaint,
    );

    // 右边下方：短横线
    canvas.drawLine(
      Offset(padding + rectWidth + 2, halfHeight + halfHeight / 2 + 2),
      Offset(size.width - 6, halfHeight + halfHeight / 2 + 2),
      strokePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 文本布局2 - 分为上下两部分，上面部分左边是一个实心三角形，箭头向右，右边在分为上下2行，上面是一个长横线，下面是一个短横线；
// 下面部分同上面部分
class _TextLayout2Icon extends StatelessWidget {
  const _TextLayout2Icon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(24, 24),
      painter: _TextLayout2Painter(),
    );
  }
}

class _TextLayout2Painter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // 分为上下两部分
    final halfHeight = size.height / 2;
    final padding = 2.0;
    final arrowSize = 6.0;

    // 上半部分
    // 左边：向右的实心三角形箭头
    final upperArrowCenterY = halfHeight / 2;
    final upperArrowPath = Path();
    upperArrowPath.moveTo(padding, upperArrowCenterY - arrowSize / 2);
    upperArrowPath.lineTo(padding + arrowSize, upperArrowCenterY);
    upperArrowPath.lineTo(padding, upperArrowCenterY + arrowSize / 2);
    upperArrowPath.close();
    canvas.drawPath(upperArrowPath, fillPaint);

    // 右边上方：长横线
    canvas.drawLine(
      Offset(padding + arrowSize + 2, upperArrowCenterY - 2),
      Offset(size.width - padding, upperArrowCenterY - 2),
      strokePaint,
    );

    // 右边下方：短横线
    canvas.drawLine(
      Offset(padding + arrowSize + 2, upperArrowCenterY + 2),
      Offset(size.width - 6, upperArrowCenterY + 2),
      strokePaint,
    );

    // 下半部分
    // 左边：向右的实心三角形箭头
    final lowerArrowCenterY = halfHeight + halfHeight / 2;
    final lowerArrowPath = Path();
    lowerArrowPath.moveTo(padding, lowerArrowCenterY - arrowSize / 2);
    lowerArrowPath.lineTo(padding + arrowSize, lowerArrowCenterY);
    lowerArrowPath.lineTo(padding, lowerArrowCenterY + arrowSize / 2);
    lowerArrowPath.close();
    canvas.drawPath(lowerArrowPath, fillPaint);

    // 右边上方：长横线
    canvas.drawLine(
      Offset(padding + arrowSize + 2, lowerArrowCenterY - 2),
      Offset(size.width - padding, lowerArrowCenterY - 2),
      strokePaint,
    );

    // 右边下方：短横线
    canvas.drawLine(
      Offset(padding + arrowSize + 2, lowerArrowCenterY + 2),
      Offset(size.width - 6, lowerArrowCenterY + 2),
      strokePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 文本布局3 - 分为上下两部分，上面部分左边是一个实心矩形，右边在分为上下2行，上面是一个长横线，下面是一个短横线；
// 下面部分左边是一个实心三角形，箭头向右，右边在分为上下2行，上面是一个长横线，下面是一个短横线；
class _TextLayout3Icon extends StatelessWidget {
  const _TextLayout3Icon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(24, 24),
      painter: _TextLayout3Painter(),
    );
  }
}

class _TextLayout3Painter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // 分为上下两部分
    final halfHeight = size.height / 2;
    final padding = 2.0;
    final rectWidth = 6.0;
    final rectHeight = halfHeight - padding * 2;
    final arrowSize = 6.0;

    // 上半部分 - 左边实心矩形 + 右边两条横线
    // 左边：实心矩形
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(padding, padding, rectWidth, rectHeight),
        const Radius.circular(1),
      ),
      fillPaint,
    );

    // 右边上方：长横线
    canvas.drawLine(
      Offset(padding + rectWidth + 2, halfHeight / 2 - 2),
      Offset(size.width - padding, halfHeight / 2 - 2),
      strokePaint,
    );

    // 右边下方：短横线
    canvas.drawLine(
      Offset(padding + rectWidth + 2, halfHeight / 2 + 2),
      Offset(size.width - 6, halfHeight / 2 + 2),
      strokePaint,
    );

    // 下半部分 - 左边向右的实心三角形箭头 + 右边两条横线
    final lowerArrowCenterY = halfHeight + halfHeight / 2;
    final lowerArrowPath = Path();
    lowerArrowPath.moveTo(padding, lowerArrowCenterY - arrowSize / 2);
    lowerArrowPath.lineTo(padding + arrowSize, lowerArrowCenterY);
    lowerArrowPath.lineTo(padding, lowerArrowCenterY + arrowSize / 2);
    lowerArrowPath.close();
    canvas.drawPath(lowerArrowPath, fillPaint);

    // 右边上方：长横线
    canvas.drawLine(
      Offset(padding + arrowSize + 2, lowerArrowCenterY - 2),
      Offset(size.width - padding, lowerArrowCenterY - 2),
      strokePaint,
    );

    // 右边下方：短横线
    canvas.drawLine(
      Offset(padding + arrowSize + 2, lowerArrowCenterY + 2),
      Offset(size.width - 6, lowerArrowCenterY + 2),
      strokePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 文本布局4 - 分为上下两部分，上面部分分为2行，上面一行是向上的一个实心箭头，接连一条竖线，竖线连接一条横线，横线处于上面部分的最底端，箭头底部中央和竖线相连，竖线和上半部分横线相连；
// 下面部分分为上下2行，上面一行是一条横线，横线处于下面部分的最顶端，该横线连接一条竖线，竖线连接一个向下的实心箭头；
class _TextLayout4Icon extends StatelessWidget {
  const _TextLayout4Icon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(24, 24),
      painter: _TextLayout4Painter(),
    );
  }
}

class _TextLayout4Painter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // 分为上下两部分
    final halfHeight = size.height / 2;
    final padding = 1.0;
    final centerX = size.width / 2;
    final arrowWidth = 6.0;
    final arrowHeight = 4.0;
    final lineWidth = 1.5; // 横线的厚度

    // 上半部分 - 向上实心箭头 → 竖线 → 横线
    // 计算上半部分的各元素位置
    final upperArrowBottomY = halfHeight / 2 - arrowHeight / 2; // 箭头底部中央
    final upperArrowTopY = upperArrowBottomY - arrowHeight; // 箭头顶部
    final upperLineY = halfHeight - padding - lineWidth; // 上半部分底部的横线

    // 向上实心箭头
    final upperArrowPath = Path();
    upperArrowPath.moveTo(centerX - arrowWidth / 2, upperArrowBottomY);
    upperArrowPath.lineTo(centerX, upperArrowTopY);
    upperArrowPath.lineTo(centerX + arrowWidth / 2, upperArrowBottomY);
    upperArrowPath.close();
    canvas.drawPath(upperArrowPath, fillPaint);

    // 箭头底部中央到横线的竖线
    canvas.drawLine(
      Offset(centerX, upperArrowBottomY),
      Offset(centerX, upperLineY),
      strokePaint,
    );

    // 上半部分底部的横线
    canvas.drawLine(
      Offset(padding, upperLineY),
      Offset(size.width - padding, upperLineY),
      strokePaint,
    );

    // 下半部分 - 横线 → 竖线 → 向下实心箭头
    // 计算下半部分的各元素位置
    final lowerLineY = halfHeight + padding + lineWidth; // 下半部分顶部的横线
    final lowerArrowTopY =
        halfHeight + halfHeight / 2 + arrowHeight / 2; // 箭头顶部中央
    final lowerArrowBottomY = lowerArrowTopY + arrowHeight; // 箭头底部

    // 下半部分顶部的横线
    canvas.drawLine(
      Offset(padding, lowerLineY),
      Offset(size.width - padding, lowerLineY),
      strokePaint,
    );

    // 横线到箭头顶部中央的竖线
    canvas.drawLine(
      Offset(centerX, lowerLineY),
      Offset(centerX, lowerArrowTopY),
      strokePaint,
    );

    // 向下实心箭头
    final lowerArrowPath = Path();
    lowerArrowPath.moveTo(centerX - arrowWidth / 2, lowerArrowTopY);
    lowerArrowPath.lineTo(centerX, lowerArrowBottomY);
    lowerArrowPath.lineTo(centerX + arrowWidth / 2, lowerArrowTopY);
    lowerArrowPath.close();
    canvas.drawPath(lowerArrowPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
