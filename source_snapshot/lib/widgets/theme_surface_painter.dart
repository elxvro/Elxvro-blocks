import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/game_theme.dart';

class ThemeSurfacePainter extends CustomPainter {
  const ThemeSurfacePainter({
    required this.material,
    required this.accent,
    this.intensity = 1,
  });

  final ThemeMaterial material;
  final Color accent;
  final double intensity;

  double get _alpha => (0.22 * intensity).clamp(0.06, 0.34).toDouble();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 2 || size.height <= 2) return;

    switch (material) {
      case ThemeMaterial.glass:
        _paintGlass(canvas, size);
        break;
      case ThemeMaterial.wood:
        _paintWood(canvas, size);
        break;
      case ThemeMaterial.stone:
        _paintStone(canvas, size);
        break;
      case ThemeMaterial.leaf:
        _paintLeaf(canvas, size);
        break;
      case ThemeMaterial.crystal:
        _paintCrystal(canvas, size);
        break;
      case ThemeMaterial.marble:
        _paintMarble(canvas, size);
        break;
    }
  }

  void _paintGlass(Canvas canvas, Size size) {
    final shine = Paint()
      ..color = Colors.white.withValues(alpha: 0.24 * intensity)
      ..strokeWidth = math.max(0.7, size.shortestSide * 0.045)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.18, size.height * 0.16),
      Offset(size.width * 0.68, size.height * 0.16),
      shine,
    );
    canvas.drawLine(
      Offset(size.width * 0.20, size.height * 0.26),
      Offset(size.width * 0.45, size.height * 0.26),
      shine..color = Colors.white.withValues(alpha: 0.12 * intensity),
    );
  }

  void _paintWood(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent.withValues(alpha: _alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.55, size.shortestSide * 0.035);
    for (var i = 0; i < 3; i++) {
      final y = size.height * (0.25 + i * 0.23);
      final path = Path()
        ..moveTo(size.width * 0.08, y)
        ..quadraticBezierTo(
          size.width * 0.34,
          y - size.height * 0.08,
          size.width * 0.55,
          y,
        )
        ..quadraticBezierTo(
          size.width * 0.78,
          y + size.height * 0.07,
          size.width * 0.94,
          y - size.height * 0.02,
        );
      canvas.drawPath(path, paint);
    }
  }

  void _paintStone(Canvas canvas, Size size) {
    final crack = Paint()
      ..color = Colors.white.withValues(alpha: 0.14 * intensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.5, size.shortestSide * 0.026);
    final center = Offset(size.width * 0.55, size.height * 0.45);
    canvas.drawLine(center, Offset(size.width * 0.84, size.height * 0.20), crack);
    canvas.drawLine(center, Offset(size.width * 0.82, size.height * 0.72), crack);
    canvas.drawLine(center, Offset(size.width * 0.28, size.height * 0.78), crack);
    final speck = Paint()..color = accent.withValues(alpha: 0.12 * intensity);
    for (final point in <Offset>[
      Offset(size.width * 0.22, size.height * 0.24),
      Offset(size.width * 0.72, size.height * 0.32),
      Offset(size.width * 0.35, size.height * 0.62),
    ]) {
      canvas.drawCircle(point, math.max(0.7, size.shortestSide * 0.025), speck);
    }
  }

  void _paintLeaf(Canvas canvas, Size size) {
    final vein = Paint()
      ..color = accent.withValues(alpha: 0.24 * intensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.6, size.shortestSide * 0.032)
      ..strokeCap = StrokeCap.round;
    final start = Offset(size.width * 0.22, size.height * 0.82);
    final end = Offset(size.width * 0.78, size.height * 0.18);
    canvas.drawLine(start, end, vein);
    for (var i = 1; i <= 3; i++) {
      final t = i / 4;
      final x = start.dx + (end.dx - start.dx) * t;
      final y = start.dy + (end.dy - start.dy) * t;
      canvas.drawLine(
        Offset(x, y),
        Offset(x - size.width * 0.17, y - size.height * 0.04),
        vein..color = accent.withValues(alpha: 0.14 * intensity),
      );
      canvas.drawLine(
        Offset(x, y),
        Offset(x + size.width * 0.13, y + size.height * 0.08),
        vein,
      );
    }
  }

  void _paintCrystal(Canvas canvas, Size size) {
    final facet = Paint()
      ..color = Colors.white.withValues(alpha: 0.18 * intensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.5, size.shortestSide * 0.028);
    final center = Offset(size.width * 0.50, size.height * 0.48);
    canvas.drawLine(Offset(size.width * 0.10, size.height * 0.12), center, facet);
    canvas.drawLine(Offset(size.width * 0.90, size.height * 0.16), center, facet);
    canvas.drawLine(Offset(size.width * 0.84, size.height * 0.88), center, facet);
    canvas.drawLine(Offset(size.width * 0.12, size.height * 0.82), center, facet);
    canvas.drawLine(
      Offset(size.width * 0.10, size.height * 0.12),
      Offset(size.width * 0.90, size.height * 0.16),
      facet..color = accent.withValues(alpha: 0.14 * intensity),
    );
  }

  void _paintMarble(Canvas canvas, Size size) {
    final vein = Paint()
      ..color = accent.withValues(alpha: 0.20 * intensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.55, size.shortestSide * 0.028);
    final first = Path()
      ..moveTo(size.width * 0.04, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.34,
        size.height * 0.35,
        size.width * 0.62,
        size.height * 0.54,
      )
      ..quadraticBezierTo(
        size.width * 0.80,
        size.height * 0.64,
        size.width * 0.98,
        size.height * 0.24,
      );
    canvas.drawPath(first, vein);
    final second = Path()
      ..moveTo(size.width * 0.18, size.height * 0.02)
      ..quadraticBezierTo(
        size.width * 0.42,
        size.height * 0.36,
        size.width * 0.92,
        size.height * 0.78,
      );
    canvas.drawPath(
      second,
      vein..color = Colors.white.withValues(alpha: 0.08 * intensity),
    );
  }

  @override
  bool shouldRepaint(covariant ThemeSurfacePainter oldDelegate) {
    return oldDelegate.material != material ||
        oldDelegate.accent != accent ||
        oldDelegate.intensity != intensity;
  }
}
