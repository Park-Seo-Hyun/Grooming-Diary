import 'package:flutter/material.dart';

class BubbleTailPainter extends CustomPainter {
  final Color color;
  final bool isQuestion;

  BubbleTailPainter({required this.color, this.isQuestion = true});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();

    if (isQuestion) {
      path.moveTo(0, 0);
      path.lineTo(size.width, size.height / 100);
      path.lineTo(0, size.height);
    } else {
      path.moveTo(size.width, 0);
      path.lineTo(0, size.height / 100);
      path.lineTo(size.width, size.height);
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
