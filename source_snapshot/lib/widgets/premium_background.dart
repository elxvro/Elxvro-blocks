import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/game_theme.dart';

class PremiumBackground extends StatelessWidget {
  const PremiumBackground({
    super.key,
    required this.top,
    required this.bottom,
    required this.child,
    this.material,
    this.accent,
  });

  final Color top;
  final Color bottom;
  final Widget child;
  final ThemeMaterial? material;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[top, bottom],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (material != null)
            IgnorePointer(
              child: CustomPaint(
                painter: _ThemeBackdropPainter(
                  material: material!,
                  accent: accent ?? Colors.white,
                ),
              ),
            ),
          IgnorePointer(child: _AmbientGlow(accent: accent)),
          child,
        ],
      ),
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({this.accent});

  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final glow = accent ?? const Color(0xFFFFB84A);
    return Stack(
      children: <Widget>[
        Positioned(
          top: -120,
          left: -90,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: <Color>[
                  glow.withValues(alpha: 0.20),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -160,
          right: -90,
          child: Container(
            width: 340,
            height: 340,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: <Color>[
                  glow.withValues(alpha: 0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ThemeBackdropPainter extends CustomPainter {
  const _ThemeBackdropPainter({required this.material, required this.accent});

  final ThemeMaterial material;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
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
  }

  void _glass(Canvas canvas, Size s) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.085);
    for (var i = -2; i < 8; i++) {
      final x = s.width * (i / 6);
      canvas.drawLine(Offset(x, 0), Offset(x + s.height * 0.22, s.height), p);
    }
    final bubble = Paint()..color = accent.withValues(alpha: 0.075);
    for (final q in <Offset>[
      Offset(s.width * .16, s.height * .22),
      Offset(s.width * .80, s.height * .18),
      Offset(s.width * .72, s.height * .66),
      Offset(s.width * .24, s.height * .78),
    ]) {
      canvas.drawCircle(q, math.min(s.width, s.height) * 0.045, bubble);
    }
  }

  void _wood(Canvas canvas, Size s) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = const Color(0xFFE4A766).withValues(alpha: 0.11);
    for (var i = 0; i < 10; i++) {
      final y = s.height * (0.05 + i * 0.105);
      final path = Path()
        ..moveTo(-20, y)
        ..cubicTo(s.width * .28, y - 22, s.width * .62, y + 20, s.width + 30, y - 6);
      canvas.drawPath(path, p);
    }
    final branch = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5
      ..color = const Color(0xFF9A6232).withValues(alpha: 0.15);
    canvas.drawLine(Offset(-30, s.height * .78), Offset(s.width * .44, s.height * .52), branch);
    canvas.drawLine(Offset(s.width * .26, s.height * .61), Offset(s.width * .48, s.height * .37), branch..strokeWidth=3);
  }

  void _stone(Canvas canvas, Size s) {
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withValues(alpha: 0.07);
    const cols = 4;
    const rows = 8;
    final w = s.width / cols;
    final h = s.height / rows;
    for (var r = 0; r <= rows; r++) {
      canvas.drawLine(Offset(0, r*h), Offset(s.width, r*h), line);
    }
    for (var r = 0; r < rows; r++) {
      final shift = r.isOdd ? w*.5 : 0.0;
      for (var c = -1; c <= cols; c++) {
        canvas.drawLine(Offset(c*w+shift, r*h), Offset(c*w+shift, (r+1)*h), line);
      }
    }
  }

  void _leaf(Canvas canvas, Size s) {
    final vein = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = const Color(0xFFCEFFC7).withValues(alpha: 0.085);
    for (var i = 0; i < 7; i++) {
      final x = s.width * (0.05 + i * .16);
      final path = Path()
        ..moveTo(x, s.height + 30)
        ..quadraticBezierTo(x + 80, s.height * .55, x + 20, -30);
      canvas.drawPath(path, vein);
    }
    final leaf = Paint()..color = accent.withValues(alpha: 0.06);
    for (final p in <Offset>[
      Offset(s.width*.16,s.height*.25),
      Offset(s.width*.82,s.height*.34),
      Offset(s.width*.34,s.height*.73),
    ]) {
      canvas.save();
      canvas.translate(p.dx,p.dy);
      canvas.rotate(-0.6);
      canvas.drawOval(Rect.fromLTWH(-28, -11, 56, 22), leaf);
      canvas.restore();
    }
  }

  void _crystal(Canvas canvas, Size s) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withValues(alpha: 0.08);
    final points = <Offset>[
      Offset(s.width*.10,s.height*.20),
      Offset(s.width*.78,s.height*.12),
      Offset(s.width*.62,s.height*.62),
      Offset(s.width*.20,s.height*.82),
      Offset(s.width*.92,s.height*.78),
    ];
    for (var i=0;i<points.length;i++) {
      for (var j=i+1;j<points.length;j++) {
        if ((i+j).isEven) canvas.drawLine(points[i],points[j],p);
      }
    }
  }

  void _marble(Canvas canvas, Size s) {
    final gold = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25
      ..color = accent.withValues(alpha: 0.11);
    final white = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..color = Colors.white.withValues(alpha: 0.055);
    for (var i=0;i<5;i++) {
      final y=s.height*(.08+i*.21);
      final p=Path()..moveTo(-30,y)..cubicTo(s.width*.22,y-90,s.width*.62,y+80,s.width+40,y-25);
      canvas.drawPath(p,i.isEven?gold:white);
    }
  }

  @override
  bool shouldRepaint(covariant _ThemeBackdropPainter oldDelegate) =>
      oldDelegate.material != material || oldDelegate.accent != accent;
}
