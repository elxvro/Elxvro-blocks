import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/game_theme.dart';

/// Decorative art rendered only behind Adventure gameplay.
class AdventureWorldBackdrop extends StatelessWidget {
  const AdventureWorldBackdrop({super.key, required this.world, required this.theme});
  final int world;
  final GameThemeData theme;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: _WorldPainter(world, theme.blockAccent),
      ),
    ),
  );
}

class _WorldPainter extends CustomPainter {
  const _WorldPainter(this.world, this.accent);
  final int world;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final worldColor = <Color>[
      const Color(0xFF9A6CFF), const Color(0xFF80DFFF),
      const Color(0xFF5FE0A3), const Color(0xFFFF9458),
      const Color(0xFF7BA3FF), const Color(0xFFD27BFF),
    ][world.clamp(0, 5).toInt()];
    final color = Color.lerp(worldColor, accent, 0.46)!;
    final p = Paint()..style = PaintingStyle.fill;
    p.shader = RadialGradient(colors: <Color>[
      color.withValues(alpha: 0.23), Colors.transparent,
    ]).createShader(Rect.fromCircle(center: Offset(w * .56, h * .48), radius: h * .55));
    canvas.drawRect(Offset.zero & size, p);
    p.shader = null;

    for (var i = 0; i < 44; i++) {
      final x = ((i * 73 + world * 37) % 997) / 997 * w;
      final y = ((i * 167 + world * 103) % 991) / 991 * h;
      p.color = color.withValues(alpha: i % 7 == 0 ? .31 : .14);
      canvas.drawCircle(Offset(x, y), i % 7 == 0 ? 2.5 : 1.1, p);
    }
    switch (world) {
      case 0: // Neon city
        for (var i = 0; i < 8; i++) {
          final x = (i + .1) * w / 8;
          final height = (70 + ((i * 29) % 90)).toDouble();
          p.color = color.withValues(alpha: .1);
          canvas.drawRRect(RRect.fromRectAndRadius(
            Rect.fromLTWH(x, h-height-18, w/13, height), const Radius.circular(4)), p);
          p.color = color.withValues(alpha: .34);
          canvas.drawRect(Rect.fromLTWH(x + w/40, h-height-10, 1.5, height-16), p);
        }
      case 1: // Ice crystals
        for (var i = 0; i < 7; i++) {
          final x = i*w/6, y = h*(.79 + i%2*.055);
          final peak = Path()..moveTo(x-31,h)..lineTo(x,y-83)
            ..lineTo(x+40,h)..close();
          p.color = color.withValues(alpha: .11);
          canvas.drawPath(peak,p);
          p..color = Colors.white.withValues(alpha: .10)
            ..style = PaintingStyle.stroke..strokeWidth = 1;
          canvas.drawPath(peak,p);
          p.style = PaintingStyle.fill;
        }
      case 2: // Luminous forest spores
        for (var i = 0; i < 14; i++) {
          final x = (i*67%101)/101*w, y = (i*37%107)/107*h;
          p.color = color.withValues(alpha: .12);
          canvas.drawCircle(Offset(x,y), 8+i%4*5,p);
        }
      case 3: // Lava seams
        for (var i = 0; i < 7; i++) {
          final x = i*w/6;
          final path = Path()..moveTo(x,h)
            ..cubicTo(x+15,h*.88,x-23,h*.8,x+22,h*.66);
          p..color = color.withValues(alpha: .17)
            ..style = PaintingStyle.stroke..strokeWidth = 2.2;
          canvas.drawPath(path,p);
          p.style = PaintingStyle.fill;
        }
      case 4: // Orbital rings
        for (var i=0; i<3; i++) {
          p..color = color.withValues(alpha: .17)
            ..style = PaintingStyle.stroke..strokeWidth = 1.5;
          canvas.drawOval(Rect.fromCenter(center: Offset(w*.5,h*.48),
            width: w*(.75+i*.25),height: h*(.15+i*.11)),p);
          p.style = PaintingStyle.fill;
        }
      default: // Dark dimension runes
        for (var i = 0; i < 6; i++) {
          final theta = i*math.pi/3;
          final center = Offset(w*.5 + math.cos(theta)*w*.44,
            h*.48 + math.sin(theta)*h*.27);
          final path=Path();
          for (var corner=0;corner<6;corner++) {
            final a=math.pi*corner/3;
            final v=center+Offset(math.cos(a)*20,math.sin(a)*20);
            if (corner==0) {path.moveTo(v.dx,v.dy);}
            else {path.lineTo(v.dx,v.dy);}
          }
          path.close();
          p..color=color.withValues(alpha: .22)
            ..style=PaintingStyle.stroke..strokeWidth=1.6;
          canvas.drawPath(path,p);
          p.style=PaintingStyle.fill;
        }
    }
  }

  @override
  bool shouldRepaint(covariant _WorldPainter old) =>
    old.world != world || old.accent != accent;
}
