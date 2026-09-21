import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/game_theme.dart';

/// Draws the complete material surface for a single occupied block cell.
/// Each theme deliberately uses a different silhouette and texture so themes
/// read as different materials, not as recolors of the same square.
class ThemedBlockTile extends StatelessWidget {
  const ThemedBlockTile({
    super.key,
    required this.material,
    required this.base,
    required this.accent,
    this.flash = 0,
  });

  final ThemeMaterial material;
  final Color base;
  final Color accent;
  final double flash;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _MaterialBlockPainter(
          material: material,
          base: base,
          accent: accent,
          flash: flash,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _MaterialBlockPainter extends CustomPainter {
  const _MaterialBlockPainter({
    required this.material,
    required this.base,
    required this.accent,
    required this.flash,
  });

  final ThemeMaterial material;
  final Color base;
  final Color accent;
  final double flash;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.shortestSide <= 2) return;
    switch (material) {
      case ThemeMaterial.glass:
        _glass(canvas, size);
        break;
      case ThemeMaterial.wood:
        _wood(canvas, size);
        break;
      case ThemeMaterial.stone:
        _stone(canvas, size);
        break;
      case ThemeMaterial.leaf:
        _leaf(canvas, size);
        break;
      case ThemeMaterial.crystal:
        _crystal(canvas, size);
        break;
      case ThemeMaterial.marble:
        _marble(canvas, size);
        break;
    }
    if (flash > 0) {
      final r = RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(size.shortestSide * 0.16),
      );
      canvas.drawRRect(
        r,
        Paint()..color = Colors.white.withValues(alpha: 0.42 * flash),
      );
    }
  }

  Paint _gradient(Size size, List<Color> colors) => Paint()
    ..shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    ).createShader(Offset.zero & size);

  void _glass(Canvas canvas, Size size) {
    final r = size.shortestSide * 0.20;
    final rr = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
      Radius.circular(r),
    );
    canvas.drawRRect(
      rr,
      _gradient(size, <Color>[
        accent.withValues(alpha: 0.92),
        base.withValues(alpha: 0.60),
        const Color(0xFF1B6E8C).withValues(alpha: 0.72),
      ]),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, size.shortestSide * 0.055)
        ..color = Colors.white.withValues(alpha: 0.72),
    );
    final inner = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.10,
        size.height * 0.10,
        size.width * 0.80,
        size.height * 0.80,
      ),
      Radius.circular(r * 0.72),
    );
    canvas.drawRRect(
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = Colors.white.withValues(alpha: 0.22),
    );
    final shine = Paint()
      ..color = Colors.white.withValues(alpha: 0.62)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1, size.shortestSide * 0.06);
    canvas.drawLine(
      Offset(size.width * 0.20, size.height * 0.19),
      Offset(size.width * 0.62, size.height * 0.19),
      shine,
    );
    canvas.drawCircle(
      Offset(size.width * 0.75, size.height * 0.68),
      size.shortestSide * 0.065,
      Paint()..color = Colors.white.withValues(alpha: 0.18),
    );
  }

  void _wood(Canvas canvas, Size size) {
    final rr = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
      Radius.circular(size.shortestSide * 0.13),
    );
    canvas.drawRRect(
      rr,
      _gradient(size, <Color>[
        accent.withValues(alpha: 0.92),
        base,
        const Color(0xFF70401E),
      ]),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, size.shortestSide * 0.06)
        ..color = const Color(0xFF5A3015).withValues(alpha: 0.92),
    );
    final grain = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(0.65, size.shortestSide * 0.025)
      ..color = const Color(0xFF633516).withValues(alpha: 0.65);
    for (var i = 0; i < 4; i++) {
      final y = size.height * (0.22 + i * 0.19);
      final p = Path()
        ..moveTo(size.width * 0.08, y)
        ..cubicTo(
          size.width * 0.30,
          y - size.height * 0.10,
          size.width * 0.62,
          y + size.height * 0.09,
          size.width * 0.93,
          y - size.height * 0.02,
        );
      canvas.drawPath(p, grain);
    }
    final knotCenter = Offset(size.width * 0.67, size.height * 0.48);
    canvas.drawOval(
      Rect.fromCenter(
        center: knotCenter,
        width: size.width * 0.22,
        height: size.height * 0.16,
      ),
      grain..strokeWidth = math.max(0.75, size.shortestSide * 0.03),
    );
    canvas.drawCircle(
      knotCenter,
      size.shortestSide * 0.035,
      Paint()..color = const Color(0xFF4C2813).withValues(alpha: 0.70),
    );
  }

  void _stone(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final c = size.shortestSide * 0.11;
    final path = Path()
      ..moveTo(c, 1)
      ..lineTo(w - c * 0.55, 1)
      ..lineTo(w - 1, c * 1.05)
      ..lineTo(w - c * 0.25, h - c * 0.72)
      ..lineTo(w - c * 1.05, h - 1)
      ..lineTo(c * 0.75, h - 1)
      ..lineTo(1, h - c * 1.10)
      ..lineTo(1, c * 0.75)
      ..close();
    canvas.drawPath(
      path,
      _gradient(size, <Color>[
        accent.withValues(alpha: 0.82),
        base,
        const Color(0xFF48515A),
      ]),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, size.shortestSide * 0.05)
        ..color = const Color(0xFFCBD5DF).withValues(alpha: 0.34),
    );
    final crack = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.7, size.shortestSide * 0.026)
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF263039).withValues(alpha: 0.72);
    final mid = Offset(w * 0.54, h * 0.47);
    canvas.drawLine(mid, Offset(w * 0.78, h * 0.21), crack);
    canvas.drawLine(mid, Offset(w * 0.86, h * 0.63), crack);
    canvas.drawLine(mid, Offset(w * 0.36, h * 0.78), crack);
    final speck = Paint()..color = Colors.white.withValues(alpha: 0.16);
    for (final p in <Offset>[
      Offset(w * 0.23, h * 0.28),
      Offset(w * 0.73, h * 0.34),
      Offset(w * 0.31, h * 0.59),
    ]) {
      canvas.drawCircle(p, size.shortestSide * 0.022, speck);
    }
  }

  void _leaf(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.12, h * 0.68)
      ..cubicTo(w * 0.18, h * 0.20, w * 0.63, h * 0.05, w * 0.88, h * 0.18)
      ..cubicTo(w * 0.98, h * 0.52, w * 0.70, h * 0.88, w * 0.25, h * 0.90)
      ..cubicTo(w * 0.20, h * 0.82, w * 0.16, h * 0.75, w * 0.12, h * 0.68)
      ..close();
    canvas.drawPath(
      path,
      _gradient(size, <Color>[
        accent.withValues(alpha: 0.95),
        base,
        const Color(0xFF16733A),
      ]),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, size.shortestSide * 0.045)
        ..color = const Color(0xFFC8FFAE).withValues(alpha: 0.42),
    );
    final vein = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(0.75, size.shortestSide * 0.03)
      ..color = const Color(0xFFE3FFBD).withValues(alpha: 0.50);
    final a = Offset(w * 0.22, h * 0.77);
    final b = Offset(w * 0.78, h * 0.24);
    canvas.drawLine(a, b, vein);
    for (var i = 1; i <= 3; i++) {
      final t = i / 4;
      final x = a.dx + (b.dx - a.dx) * t;
      final y = a.dy + (b.dy - a.dy) * t;
      canvas.drawLine(Offset(x, y), Offset(x - w * 0.15, y - h * 0.02), vein);
      canvas.drawLine(Offset(x, y), Offset(x + w * 0.12, y + h * 0.10), vein);
    }
  }

  void _crystal(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final p1 = Offset(w * 0.50, h * 0.04);
    final p2 = Offset(w * 0.92, h * 0.27);
    final p3 = Offset(w * 0.82, h * 0.82);
    final p4 = Offset(w * 0.50, h * 0.96);
    final p5 = Offset(w * 0.13, h * 0.78);
    final p6 = Offset(w * 0.07, h * 0.28);
    final outline = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..lineTo(p4.dx, p4.dy)
      ..lineTo(p5.dx, p5.dy)
      ..lineTo(p6.dx, p6.dy)
      ..close();
    canvas.drawPath(
      outline,
      _gradient(size, <Color>[
        accent.withValues(alpha: 0.94),
        base,
        const Color(0xFF4430A8),
      ]),
    );
    final center = Offset(w * 0.52, h * 0.51);
    final facet1 = Paint()..color = Colors.white.withValues(alpha: 0.20);
    canvas.drawPath(Path()..moveTo(p1.dx,p1.dy)..lineTo(p2.dx,p2.dy)..lineTo(center.dx,center.dy)..close(), facet1);
    canvas.drawPath(Path()..moveTo(p5.dx,p5.dy)..lineTo(p6.dx,p6.dy)..lineTo(center.dx,center.dy)..close(), Paint()..color=accent.withValues(alpha:0.16));
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, size.shortestSide * 0.035)
      ..color = Colors.white.withValues(alpha: 0.48);
    canvas.drawPath(outline, edge);
    for (final point in <Offset>[p1, p2, p3, p4, p5, p6]) {
      canvas.drawLine(center, point, edge..color = Colors.white.withValues(alpha: 0.15));
    }
  }

  void _marble(Canvas canvas, Size size) {
    final rr = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
      Radius.circular(size.shortestSide * 0.14),
    );
    canvas.drawRRect(
      rr,
      _gradient(size, <Color>[
        const Color(0xFFEEE4CD),
        base.withValues(alpha: 0.95),
        const Color(0xFF8D7347),
      ]),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.1, size.shortestSide * 0.055)
        ..color = accent.withValues(alpha: 0.85),
    );
    final vein = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(0.65, size.shortestSide * 0.025)
      ..color = const Color(0xFF5C5043).withValues(alpha: 0.45);
    final p = Path()
      ..moveTo(size.width * 0.04, size.height * 0.75)
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.56,
        size.width * 0.33,
        size.height * 0.22,
        size.width * 0.60,
        size.height * 0.44,
      )
      ..cubicTo(
        size.width * 0.73,
        size.height * 0.55,
        size.width * 0.84,
        size.height * 0.28,
        size.width * 0.98,
        size.height * 0.18,
      );
    canvas.drawPath(p, vein);
    canvas.drawLine(
      Offset(size.width * 0.16, size.height * 0.18),
      Offset(size.width * 0.70, size.height * 0.72),
      Paint()
        ..strokeWidth = math.max(0.7, size.shortestSide * 0.028)
        ..color = accent.withValues(alpha: 0.46),
    );
  }

  @override
  bool shouldRepaint(covariant _MaterialBlockPainter oldDelegate) {
    return oldDelegate.material != material ||
        oldDelegate.base != base ||
        oldDelegate.accent != accent ||
        oldDelegate.flash != flash;
  }
}
