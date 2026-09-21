import 'package:flutter/material.dart';

class CrystalMark extends StatelessWidget {
  const CrystalMark({super.key, this.size = 132});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _CrystalPainter()),
    );
  }
}

class _CrystalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.36;
    final top = Offset(center.dx, center.dy - radius);
    final right = Offset(center.dx + radius * 0.72, center.dy);
    final bottom = Offset(center.dx, center.dy + radius);
    final left = Offset(center.dx - radius * 0.72, center.dy);

    final path = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(right.dx, right.dy)
      ..lineTo(bottom.dx, bottom.dy)
      ..lineTo(left.dx, left.dy)
      ..close();

    final fill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color(0xFFFFE4A0),
          Color(0xFF9C5A1F),
          Color(0xFFF8CF7C),
        ],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.fill;

    final stroke = Paint()
      ..color = const Color(0xFFFFD98B).withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
    canvas.drawLine(top, bottom, stroke);
    canvas.drawLine(left, right, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
