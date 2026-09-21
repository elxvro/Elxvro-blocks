import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/game_theme.dart';

/// Premium pseudo-3D material block used by the original Flutter game shell.
/// The game logic, menus and navigation stay untouched; only the block surface
/// is rendered with depth, side faces, contact shadow and material texture.
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
        painter: _Premium3DBlockPainter(
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

class _Premium3DBlockPainter extends CustomPainter {
  const _Premium3DBlockPainter({
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
    if (size.shortestSide <= 4) return;

    final depth = (size.shortestSide * 0.13).clamp(2.0, 5.5).toDouble();
    final topSize = Size(
      math.max(2, size.width - depth),
      math.max(2, size.height - depth),
    );

    _paintContactShadow(canvas, size, depth);
    _paintDepthFaces(canvas, size, depth);

    canvas.save();
    canvas.translate(0, 0);
    switch (material) {
      case ThemeMaterial.glass:
        _glass(canvas, topSize);
        break;
      case ThemeMaterial.wood:
        _wood(canvas, topSize);
        break;
      case ThemeMaterial.stone:
        _stone(canvas, topSize);
        break;
      case ThemeMaterial.leaf:
        _leaf(canvas, topSize);
        break;
      case ThemeMaterial.crystal:
        _crystal(canvas, topSize);
        break;
      case ThemeMaterial.marble:
        _marble(canvas, topSize);
        break;
    }
    canvas.restore();

    _paintSurfaceResponse(canvas, topSize);
    _paintMicroSpecular(canvas, topSize);
    _paintBevel(canvas, topSize);

    if (flash > 0) {
      final rr = RRect.fromRectAndRadius(
        Rect.fromLTWH(0.6, 0.6, topSize.width - 1.2, topSize.height - 1.2),
        Radius.circular(topSize.shortestSide * 0.16),
      );
      final flashColor = switch (material) {
        ThemeMaterial.glass => Colors.white,
        ThemeMaterial.crystal => Color.lerp(Colors.white, accent, 0.24)!,
        ThemeMaterial.marble => const Color(0xFFFFF8E8),
        ThemeMaterial.stone => Color.lerp(base, Colors.white, 0.38)!,
        ThemeMaterial.wood => const Color(0xFFFFD7A2),
        ThemeMaterial.leaf => const Color(0xFFD9FFC5),
      };
      final flashStrength = switch (material) {
        ThemeMaterial.glass => 0.58,
        ThemeMaterial.crystal => 0.62,
        ThemeMaterial.marble => 0.42,
        ThemeMaterial.stone => 0.30,
        ThemeMaterial.wood => 0.34,
        ThemeMaterial.leaf => 0.28,
      };
      canvas.drawRRect(
        rr,
        Paint()..color = flashColor.withValues(alpha: flashStrength * flash),
      );
      canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.0, topSize.shortestSide * 0.055)
          ..color = accent.withValues(alpha: 0.78 * flash),
      );
    }
  }

  void _paintContactShadow(Canvas canvas, Size size, double depth) {
    final weight = switch (material) {
      ThemeMaterial.stone => 1.26,
      ThemeMaterial.marble => 1.20,
      ThemeMaterial.wood => 1.02,
      ThemeMaterial.crystal => 0.94,
      ThemeMaterial.glass => 0.88,
      ThemeMaterial.leaf => 0.72,
    };
    final softness = switch (material) {
      ThemeMaterial.leaf => 1.55,
      ThemeMaterial.glass => 1.24,
      ThemeMaterial.crystal => 1.18,
      ThemeMaterial.wood => 1.08,
      ThemeMaterial.marble => 0.94,
      ThemeMaterial.stone => 0.88,
    };
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        depth * (0.54 + 0.10 * weight),
        depth * (0.82 + 0.16 * weight),
        size.width - depth * 0.42,
        size.height - depth * 0.30,
      ),
      Radius.circular(size.shortestSide * 0.18),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..color = Colors.black.withValues(
          alpha: (0.31 + 0.095 * weight).clamp(0.0, 0.55),
        )
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          depth * softness,
        ),
    );

    if (material == ThemeMaterial.glass ||
        material == ThemeMaterial.crystal) {
      canvas.drawOval(
        Rect.fromLTWH(
          size.width * 0.16,
          size.height * 0.79,
          size.width * 0.64,
          size.height * 0.13,
        ),
        Paint()
          ..color = accent.withValues(alpha: 0.10)
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            depth * 1.35,
          ),
      );
    }
  }

  void _paintDepthFaces(Canvas canvas, Size size, double depth) {
    final w = size.width;
    final h = size.height;
    final topW = w - depth;
    final topH = h - depth;

    final right = Path()
      ..moveTo(topW, 1)
      ..lineTo(w - 1, depth)
      ..lineTo(w - 1, h - 1)
      ..lineTo(topW, topH)
      ..close();

    final front = Path()
      ..moveTo(1, topH)
      ..lineTo(topW, topH)
      ..lineTo(w - 1, h - 1)
      ..lineTo(depth, h - 1)
      ..close();

    final rightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Color.lerp(base, accent, 0.16)!.withValues(alpha: 0.98),
          Color.lerp(base, Colors.black, 0.48)!.withValues(alpha: 0.98),
        ],
      ).createShader(Rect.fromLTWH(topW, 0, depth, h));

    final frontPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: <Color>[
          Color.lerp(base, Colors.black, 0.34)!.withValues(alpha: 0.98),
          Color.lerp(base, Colors.black, 0.58)!.withValues(alpha: 0.98),
        ],
      ).createShader(Rect.fromLTWH(0, topH, w, depth));

    canvas.drawPath(right, rightPaint);
    canvas.drawPath(front, frontPaint);

    final seam = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.7, size.shortestSide * 0.026)
      ..color = Colors.black.withValues(alpha: 0.46);
    canvas.drawPath(right, seam);
    canvas.drawPath(front, seam);
  }

  void _paintSurfaceResponse(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(1, 1, size.width - 2, size.height - 2);
    final radius = Radius.circular(size.shortestSide * 0.16);
    final rr = RRect.fromRectAndRadius(rect, radius);

    // Directional light from the upper-left gives every material a physical
    // face instead of a flat UI gradient.
    canvas.save();
    canvas.clipRRect(rr);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const <double>[0.0, 0.34, 0.72, 1.0],
          colors: <Color>[
            Colors.white.withValues(alpha: 0.19),
            Colors.white.withValues(alpha: 0.035),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.23),
          ],
        ).createShader(rect),
    );

    switch (material) {
      case ThemeMaterial.glass:
        final glassLine = Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = math.max(0.5, size.shortestSide * 0.017)
          ..color = Colors.white.withValues(alpha: 0.20);
        canvas.drawArc(
          Rect.fromLTWH(
            size.width * 0.12,
            size.height * 0.08,
            size.width * 0.70,
            size.height * 0.58,
          ),
          -2.72,
          1.05,
          false,
          glassLine,
        );
        break;
      case ThemeMaterial.wood:
        final sheen = Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = math.max(0.5, size.shortestSide * 0.014)
          ..color = const Color(0xFFFFD6A0).withValues(alpha: 0.13);
        for (var i = 0; i < 3; i++) {
          final y = size.height * (0.22 + i * 0.21);
          canvas.drawLine(
            Offset(size.width * 0.14, y),
            Offset(size.width * (0.56 + i * 0.08), y - size.height * 0.035),
            sheen,
          );
        }
        break;
      case ThemeMaterial.stone:
        final pore = Paint()
          ..color = Colors.black.withValues(alpha: 0.18);
        final highlight = Paint()
          ..color = Colors.white.withValues(alpha: 0.09);
        final points = <Offset>[
          Offset(size.width * 0.20, size.height * 0.22),
          Offset(size.width * 0.70, size.height * 0.18),
          Offset(size.width * 0.34, size.height * 0.60),
          Offset(size.width * 0.76, size.height * 0.66),
          Offset(size.width * 0.52, size.height * 0.37),
        ];
        for (var i = 0; i < points.length; i++) {
          final r = size.shortestSide * (0.012 + (i % 2) * 0.006);
          canvas.drawCircle(points[i], r, pore);
          canvas.drawCircle(
            points[i] - Offset(r * 0.35, r * 0.35),
            r * 0.38,
            highlight,
          );
        }
        break;
      case ThemeMaterial.leaf:
        canvas.drawOval(
          Rect.fromLTWH(
            size.width * 0.16,
            size.height * 0.10,
            size.width * 0.48,
            size.height * 0.22,
          ),
          Paint()
            ..shader = RadialGradient(
              colors: <Color>[
                Colors.white.withValues(alpha: 0.18),
                Colors.transparent,
              ],
            ).createShader(
              Rect.fromLTWH(
                size.width * 0.16,
                size.height * 0.10,
                size.width * 0.48,
                size.height * 0.22,
              ),
            ),
        );
        break;
      case ThemeMaterial.crystal:
        final glint = Paint()
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: 0.36);
        glint.strokeWidth = math.max(0.55, size.shortestSide * 0.018);
        final g = Offset(size.width * 0.70, size.height * 0.24);
        canvas.drawLine(
          g - Offset(size.width * 0.11, 0),
          g + Offset(size.width * 0.11, 0),
          glint,
        );
        canvas.drawLine(
          g - Offset(0, size.height * 0.11),
          g + Offset(0, size.height * 0.11),
          glint,
        );
        break;
      case ThemeMaterial.marble:
        canvas.drawArc(
          Rect.fromLTWH(
            size.width * 0.07,
            size.height * 0.03,
            size.width * 0.78,
            size.height * 0.64,
          ),
          -2.75,
          1.08,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(0.55, size.shortestSide * 0.017)
            ..color = Colors.white.withValues(alpha: 0.20),
        );
        break;
    }

    canvas.restore();

    // Contact occlusion at the lower/right bevel makes the face sit on its
    // extruded sides instead of appearing pasted on top.
    canvas.drawLine(
      Offset(size.width * 0.13, size.height - 1.2),
      Offset(size.width * 0.82, size.height - 1.2),
      Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(0.7, size.shortestSide * 0.028)
        ..color = Colors.black.withValues(alpha: 0.25),
    );
    canvas.drawLine(
      Offset(size.width - 1.2, size.height * 0.16),
      Offset(size.width - 1.2, size.height * 0.78),
      Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(0.7, size.shortestSide * 0.028)
        ..color = Colors.black.withValues(alpha: 0.22),
    );
  }

  void _paintMicroSpecular(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(1, 1, size.width - 2, size.height - 2);
    final rr = RRect.fromRectAndRadius(
      rect,
      Radius.circular(size.shortestSide * 0.16),
    );

    canvas.save();
    canvas.clipRRect(rr);

    final strength = switch (material) {
      ThemeMaterial.glass => 0.34,
      ThemeMaterial.crystal => 0.38,
      ThemeMaterial.marble => 0.24,
      ThemeMaterial.wood => 0.12,
      ThemeMaterial.stone => 0.08,
      ThemeMaterial.leaf => 0.15,
    };

    final widthFactor = switch (material) {
      ThemeMaterial.glass => 0.34,
      ThemeMaterial.crystal => 0.27,
      ThemeMaterial.marble => 0.40,
      ThemeMaterial.wood => 0.52,
      ThemeMaterial.stone => 0.60,
      ThemeMaterial.leaf => 0.46,
    };

    final band = Path()
      ..moveTo(-size.width * 0.10, size.height * 0.42)
      ..lineTo(size.width * 0.56, -size.height * 0.08)
      ..lineTo(
        size.width * (0.56 + widthFactor),
        size.height * 0.04,
      )
      ..lineTo(
        size.width * (widthFactor - 0.04),
        size.height * 0.58,
      )
      ..close();

    canvas.drawPath(
      band,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Colors.transparent,
            Colors.white.withValues(alpha: strength * 0.26),
            Colors.white.withValues(alpha: strength),
            Colors.white.withValues(alpha: strength * 0.16),
            Colors.transparent,
          ],
          stops: const <double>[0.0, 0.30, 0.50, 0.70, 1.0],
        ).createShader(rect),
    );

    if (material == ThemeMaterial.crystal ||
        material == ThemeMaterial.glass) {
      final prism = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.5, size.shortestSide * 0.014)
        ..color = accent.withValues(alpha: 0.22);
      canvas.drawLine(
        Offset(size.width * 0.18, size.height * 0.72),
        Offset(size.width * 0.72, size.height * 0.24),
        prism,
      );
      canvas.drawLine(
        Offset(size.width * 0.26, size.height * 0.76),
        Offset(size.width * 0.78, size.height * 0.31),
        prism..color = Colors.white.withValues(alpha: 0.18),
      );
    } else if (material == ThemeMaterial.marble) {
      canvas.drawOval(
        Rect.fromLTWH(
          size.width * 0.12,
          size.height * 0.08,
          size.width * 0.58,
          size.height * 0.26,
        ),
        Paint()
          ..shader = RadialGradient(
            colors: <Color>[
              Colors.white.withValues(alpha: 0.16),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromLTWH(
              size.width * 0.12,
              size.height * 0.08,
              size.width * 0.58,
              size.height * 0.26,
            ),
          ),
      );
    } else if (material == ThemeMaterial.leaf) {
      canvas.drawOval(
        Rect.fromLTWH(
          size.width * 0.08,
          size.height * 0.10,
          size.width * 0.62,
          size.height * 0.38,
        ),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.055)
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            math.max(0.8, size.shortestSide * 0.045),
          ),
      );
    }

    canvas.restore();
  }

  void _paintBevel(Canvas canvas, Size topSize) {
    final radius = topSize.shortestSide * 0.16;
    final rr = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.7, 0.7, topSize.width - 1.4, topSize.height - 1.4),
      Radius.circular(radius),
    );

    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, topSize.shortestSide * 0.032)
        ..color = Colors.white.withValues(alpha: 0.24),
    );

    canvas.drawLine(
      Offset(topSize.width * 0.16, topSize.height * 0.10),
      Offset(topSize.width * 0.70, topSize.height * 0.10),
      Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(0.8, topSize.shortestSide * 0.035)
        ..color = Colors.white.withValues(alpha: 0.34),
    );
  }

  Paint _gradient(Size size, List<Color> colors) => Paint()
    ..shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    ).createShader(Offset.zero & size);

  RRect _topRRect(Size size, {double radiusFactor = 0.18}) {
    return RRect.fromRectAndRadius(
      Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
      Radius.circular(size.shortestSide * radiusFactor),
    );
  }

  void _glass(Canvas canvas, Size size) {
    final rr = _topRRect(size, radiusFactor: 0.20);
    canvas.drawRRect(
      rr,
      _gradient(size, <Color>[
        Colors.white.withValues(alpha: 0.38),
        accent.withValues(alpha: 0.82),
        base.withValues(alpha: 0.58),
        const Color(0xFF0B425E).withValues(alpha: 0.88),
      ]),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, size.shortestSide * 0.055)
        ..color = Colors.white.withValues(alpha: 0.68),
    );

    final inner = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.10,
        size.height * 0.11,
        size.width * 0.73,
        size.height * 0.69,
      ),
      Radius.circular(size.shortestSide * 0.11),
    );
    canvas.drawRRect(
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.7, size.shortestSide * 0.022)
        ..color = Colors.white.withValues(alpha: 0.24),
    );

    canvas.drawCircle(
      Offset(size.width * 0.74, size.height * 0.67),
      size.shortestSide * 0.075,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            Colors.white.withValues(alpha: 0.48),
            accent.withValues(alpha: 0.04),
          ],
        ).createShader(
          Rect.fromCircle(
            center: Offset(size.width * 0.74, size.height * 0.67),
            radius: size.shortestSide * 0.11,
          ),
        ),
    );
  }

  void _wood(Canvas canvas, Size size) {
    final rr = _topRRect(size, radiusFactor: 0.13);
    canvas.drawRRect(
      rr,
      _gradient(size, <Color>[
        Color.lerp(accent, Colors.white, 0.18)!,
        base,
        const Color(0xFF7C421B),
        const Color(0xFF48220E),
      ]),
    );

    final grain = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(0.55, size.shortestSide * 0.023)
      ..color = const Color(0xFF3F1E0D).withValues(alpha: 0.58);

    for (var i = 0; i < 5; i++) {
      final y = size.height * (0.17 + i * 0.15);
      final path = Path()
        ..moveTo(size.width * 0.07, y)
        ..cubicTo(
          size.width * 0.25,
          y - size.height * 0.07,
          size.width * 0.52,
          y + size.height * 0.08,
          size.width * 0.91,
          y - size.height * 0.015,
        );
      canvas.drawPath(path, grain);
    }

    final knot = Offset(size.width * 0.67, size.height * 0.50);
    canvas.drawOval(
      Rect.fromCenter(
        center: knot,
        width: size.width * 0.23,
        height: size.height * 0.16,
      ),
      grain..strokeWidth = math.max(0.8, size.shortestSide * 0.028),
    );
  }

  void _stone(Canvas canvas, Size size) {
    final c = size.shortestSide * 0.10;
    final path = Path()
      ..moveTo(c, 1)
      ..lineTo(size.width - c * 0.50, 1)
      ..lineTo(size.width - 1, c)
      ..lineTo(size.width - c * 0.20, size.height - c * 0.75)
      ..lineTo(size.width - c, size.height - 1)
      ..lineTo(c * 0.75, size.height - 1)
      ..lineTo(1, size.height - c)
      ..lineTo(1, c * 0.72)
      ..close();

    canvas.drawPath(
      path,
      _gradient(size, <Color>[
        Color.lerp(accent, Colors.white, 0.10)!,
        base,
        const Color(0xFF353C42),
      ]),
    );

    final crack = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(0.65, size.shortestSide * 0.024)
      ..color = const Color(0xFF151A1D).withValues(alpha: 0.70);

    final mid = Offset(size.width * 0.53, size.height * 0.46);
    canvas.drawLine(mid, Offset(size.width * 0.79, size.height * 0.20), crack);
    canvas.drawLine(mid, Offset(size.width * 0.86, size.height * 0.62), crack);
    canvas.drawLine(mid, Offset(size.width * 0.34, size.height * 0.80), crack);

    final speck = Paint()..color = Colors.white.withValues(alpha: 0.17);
    for (final p in <Offset>[
      Offset(size.width * 0.23, size.height * 0.28),
      Offset(size.width * 0.73, size.height * 0.34),
      Offset(size.width * 0.31, size.height * 0.59),
    ]) {
      canvas.drawCircle(p, size.shortestSide * 0.022, speck);
    }
  }

  void _leaf(Canvas canvas, Size size) {
    final rr = _topRRect(size, radiusFactor: 0.22);
    canvas.drawRRect(
      rr,
      _gradient(size, <Color>[
        const Color(0xFFB8FF8F),
        accent,
        base,
        const Color(0xFF0F5E2E),
      ]),
    );

    final vein = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(0.7, size.shortestSide * 0.026)
      ..color = const Color(0xFFE4FFC8).withValues(alpha: 0.46);

    final a = Offset(size.width * 0.18, size.height * 0.80);
    final b = Offset(size.width * 0.78, size.height * 0.20);
    canvas.drawLine(a, b, vein);
    for (var i = 1; i <= 3; i++) {
      final t = i / 4;
      final x = a.dx + (b.dx - a.dx) * t;
      final y = a.dy + (b.dy - a.dy) * t;
      canvas.drawLine(
        Offset(x, y),
        Offset(x - size.width * 0.14, y - size.height * 0.02),
        vein,
      );
      canvas.drawLine(
        Offset(x, y),
        Offset(x + size.width * 0.11, y + size.height * 0.10),
        vein,
      );
    }
  }

  void _crystal(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final p1 = Offset(w * 0.50, h * 0.03);
    final p2 = Offset(w * 0.92, h * 0.25);
    final p3 = Offset(w * 0.82, h * 0.82);
    final p4 = Offset(w * 0.50, h * 0.96);
    final p5 = Offset(w * 0.12, h * 0.79);
    final p6 = Offset(w * 0.06, h * 0.27);
    final center = Offset(w * 0.52, h * 0.50);

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
        Colors.white.withValues(alpha: 0.72),
        accent,
        base,
        const Color(0xFF352077),
      ]),
    );

    canvas.drawPath(
      Path()
        ..moveTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..lineTo(center.dx, center.dy)
        ..close(),
      Paint()..color = Colors.white.withValues(alpha: 0.24),
    );
    canvas.drawPath(
      Path()
        ..moveTo(p5.dx, p5.dy)
        ..lineTo(p6.dx, p6.dy)
        ..lineTo(center.dx, center.dy)
        ..close(),
      Paint()..color = const Color(0xFF24105A).withValues(alpha: 0.26),
    );

    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, size.shortestSide * 0.032)
      ..color = Colors.white.withValues(alpha: 0.48);
    canvas.drawPath(outline, edge);
    for (final p in <Offset>[p1, p2, p3, p4, p5, p6]) {
      canvas.drawLine(
        center,
        p,
        Paint()
          ..strokeWidth = math.max(0.5, size.shortestSide * 0.018)
          ..color = Colors.white.withValues(alpha: 0.14),
      );
    }
  }

  void _marble(Canvas canvas, Size size) {
    final rr = _topRRect(size, radiusFactor: 0.14);
    canvas.drawRRect(
      rr,
      _gradient(size, <Color>[
        Colors.white,
        const Color(0xFFF1E7D1),
        base.withValues(alpha: 0.97),
        const Color(0xFFA08658),
      ]),
    );

    final vein = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(0.60, size.shortestSide * 0.023)
      ..color = const Color(0xFF51483F).withValues(alpha: 0.42);

    final path = Path()
      ..moveTo(size.width * 0.04, size.height * 0.76)
      ..cubicTo(
        size.width * 0.27,
        size.height * 0.57,
        size.width * 0.34,
        size.height * 0.22,
        size.width * 0.60,
        size.height * 0.44,
      )
      ..cubicTo(
        size.width * 0.72,
        size.height * 0.55,
        size.width * 0.84,
        size.height * 0.28,
        size.width * 0.98,
        size.height * 0.18,
      );
    canvas.drawPath(path, vein);

    canvas.drawLine(
      Offset(size.width * 0.15, size.height * 0.18),
      Offset(size.width * 0.72, size.height * 0.74),
      Paint()
        ..strokeWidth = math.max(0.7, size.shortestSide * 0.026)
        ..color = accent.withValues(alpha: 0.52),
    );
  }

  @override
  bool shouldRepaint(covariant _Premium3DBlockPainter oldDelegate) {
    return oldDelegate.material != material ||
        oldDelegate.base != base ||
        oldDelegate.accent != accent ||
        oldDelegate.flash != flash;
  }
}
