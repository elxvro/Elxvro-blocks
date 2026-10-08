import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/game_theme.dart';
import 'premium_background.dart';

class GameplayBackground extends StatelessWidget {
  const GameplayBackground({
    super.key,
    required this.theme,
    required this.child,
  });

  final GameThemeData theme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PremiumBackground(
      top: theme.backgroundTop,
      bottom: theme.backgroundBottom,
      material: theme.material,
      accent: theme.blockAccent,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          IgnorePointer(
            child: CustomPaint(
              painter: _GameplayAtmospherePainter(
                material: theme.material,
                accent: theme.blockAccent,
                base: theme.block,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _GameplayAtmospherePainter extends CustomPainter {
  const _GameplayAtmospherePainter({
    required this.material,
    required this.accent,
    required this.base,
  });

  final ThemeMaterial material;
  final Color accent;
  final Color base;

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          accent.withValues(alpha: 0.10),
          base.withValues(alpha: 0.025),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.50, size.height * 0.42),
          radius: size.longestSide * 0.50,
        ),
      );
    canvas.drawRect(Offset.zero & size, glow);

    switch (material) {
      case ThemeMaterial.glass:
      case ThemeMaterial.crystal:
        _facets(canvas, size);
        break;
      case ThemeMaterial.stone:
        _stone(canvas, size);
        break;
      case ThemeMaterial.wood:
        _wood(canvas, size);
        break;
      case ThemeMaterial.leaf:
        _leaf(canvas, size);
        break;
      case ThemeMaterial.marble:
        _marble(canvas, size);
        break;
    }
  }

  void _facets(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = accent.withValues(alpha: 0.075);
    for (var i = 0; i < 9; i++) {
      final x = size.width * ((i * 37) % 100) / 100;
      final y = size.height * ((i * 61 + 13) % 100) / 100;
      final r = 30.0 + (i % 4) * 18;
      final path = Path()
        ..moveTo(x, y - r)
        ..lineTo(x + r * 0.78, y - r * 0.12)
        ..lineTo(x + r * 0.36, y + r * 0.72)
        ..lineTo(x - r * 0.62, y + r * 0.42)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  void _stone(Canvas canvas, Size size) {
    final dark = Paint()..color = Colors.black.withValues(alpha: 0.055);
    final light = Paint()..color = accent.withValues(alpha: 0.040);
    for (var i = 0; i < 26; i++) {
      final x = size.width * ((i * 29 + 7) % 100) / 100;
      final y = size.height * ((i * 43 + 19) % 100) / 100;
      final r = 2.5 + (i % 5) * 1.4;
      canvas.drawCircle(Offset(x, y), r, i.isEven ? dark : light);
    }
  }

  void _wood(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = accent.withValues(alpha: 0.055);
    for (var i = 0; i < 7; i++) {
      final center = Offset(
        size.width * (0.12 + (i % 3) * 0.38),
        size.height * (0.14 + i * 0.12),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: 80 + i * 10,
          height: 24 + i * 4,
        ),
        paint,
      );
    }
  }

  void _leaf(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..color = accent.withValues(alpha: 0.065);
    for (var i = 0; i < 12; i++) {
      final x = size.width * ((i * 31 + 9) % 100) / 100;
      final y = size.height * ((i * 47 + 17) % 100) / 100;
      final w = 18.0 + (i % 4) * 5;
      final h = w * 0.56;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate((i % 6 - 3) * 0.22);
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: w, height: h), paint);
      canvas.drawLine(Offset(-w * 0.35, 0), Offset(w * 0.35, 0), paint);
      canvas.restore();
    }
  }

  void _marble(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = accent.withValues(alpha: 0.060);
    for (var i = 0; i < 5; i++) {
      final path = Path();
      final y = size.height * (0.16 + i * 0.18);
      path.moveTo(-20, y);
      path.cubicTo(
        size.width * 0.28,
        y - 28 - i * 4,
        size.width * 0.64,
        y + 26 + i * 3,
        size.width + 20,
        y - 10,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GameplayAtmospherePainter oldDelegate) =>
      oldDelegate.material != material ||
      oldDelegate.accent != accent ||
      oldDelegate.base != base;
}
