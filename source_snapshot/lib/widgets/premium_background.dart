import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/game_theme.dart';

class PremiumBackground extends StatefulWidget {
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
  State<PremiumBackground> createState() => _PremiumBackgroundState();
}

class _PremiumBackgroundState extends State<PremiumBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rainController;

  @override
  void initState() {
    super.initState();
    _rainController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();
  }

  @override
  void dispose() {
    _rainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[widget.top, widget.bottom],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _rainController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _RainDropPainter(
                    progress: _rainController.value,
                    accent: widget.accent ?? Colors.white,
                    material: widget.material,
                  ),
                );
              },
            ),
          ),
          IgnorePointer(child: _AmbientGlow(accent: widget.accent)),
          widget.child,
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
                  glow.withValues(alpha: 0.16),
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
                  glow.withValues(alpha: 0.12),
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

class _RainDropPainter extends CustomPainter {
  const _RainDropPainter({
    required this.progress,
    required this.accent,
    required this.material,
  });

  final double progress;
  final Color accent;
  final ThemeMaterial? material;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final baseAlpha = switch (material) {
      ThemeMaterial.glass => 0.19,
      ThemeMaterial.crystal => 0.18,
      ThemeMaterial.marble => 0.14,
      ThemeMaterial.stone => 0.12,
      ThemeMaterial.wood => 0.11,
      ThemeMaterial.leaf => 0.13,
      null => 0.14,
    };

    const count = 42;
    for (var i = 0; i < count; i++) {
      final seed = i * 17.173;
      final xRatio =
          (0.5 + 0.5 * math.sin(seed * 1.73 + math.cos(seed))).abs();
      final speed = 0.42 + (i % 7) * 0.055;
      final phase = (i * 0.137) % 1.0;
      final yRatio = (phase + progress * speed) % 1.0;

      final x = xRatio * size.width;
      final y = (yRatio * 1.18 - 0.08) * size.height;
      final radius = 1.6 + (i % 5) * 0.55;
      final stretch = 1.35 + (i % 3) * 0.16;

      final bodyRect = Rect.fromCenter(
        center: Offset(x, y),
        width: radius * 1.55,
        height: radius * 2.2 * stretch,
      );

      final body = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.40),
          colors: <Color>[
            Colors.white.withValues(alpha: baseAlpha + 0.09),
            accent.withValues(alpha: baseAlpha),
            Colors.transparent,
          ],
        ).createShader(bodyRect);

      canvas.drawOval(bodyRect, body);

      final highlight = Paint()
        ..color = Colors.white.withValues(alpha: baseAlpha + 0.08)
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(0.55, radius * 0.28);

      canvas.drawLine(
        Offset(x - radius * 0.22, y - radius * 0.55),
        Offset(x - radius * 0.05, y - radius * 0.22),
        highlight,
      );

      if (i % 4 == 0) {
        final rippleWidth = radius * (2.8 + (i % 3) * 0.5);
        final rippleRect = Rect.fromCenter(
          center: Offset(x, y + radius * 2.2),
          width: rippleWidth,
          height: radius * 0.85,
        );
        canvas.drawOval(
          rippleRect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.6
            ..color = accent.withValues(alpha: baseAlpha * 0.42),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RainDropPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.accent != accent ||
      oldDelegate.material != material;
}
