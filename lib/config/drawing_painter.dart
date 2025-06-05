import 'package:flutter/material.dart';

class DrawingPainter extends CustomPainter {
  final List<Offset?> points;
  final String pagetype;

  DrawingPainter(this.points, {this.pagetype = 'default'});

  @override
  void paint(Canvas canvas, Size size) {
    double strokeWidth = pagetype == 'angka' ? 12.0 : 8.0;

    Paint paint = Paint()
      ..color = Colors.black
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
