import 'package:flutter/material.dart';

class GridBackground extends StatelessWidget {
  final Widget child;
  final Color gridColor;
  final double gridSize;

  const GridBackground({
    super.key,
    required this.child,
    this.gridColor = const Color(0xFF00FFFF),
    this.gridSize = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: GridPainter(
        color: gridColor,
        gridSize: gridSize,
      ),
      child: child,
    );
  }
}

class GridPainter extends CustomPainter {
  final Color color;
  final double gridSize;

  GridPainter({
    required this.color,
    required this.gridSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.1)
      ..strokeWidth = 0.5;

    // 绘制垂直线
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // 绘制水平线
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

