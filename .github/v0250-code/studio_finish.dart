import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/game_theme.dart';

/// GPU-painted studio highlights. No textures, allocations or timers are
/// retained between frames, so older Android phones keep the same gameplay.
class StudioFinish {
  const StudioFinish._();

  static void paint(Canvas canvas, Size s, ThemeMaterial material, Color base, Color accent) {
    if (s.shortestSide < 5) return;
    final r = Rect.fromLTWH(1.5, 1.5, s.width - 3, s.height - 3);
    final brightness = switch (material) {
      ThemeMaterial.glass => 0.33,
      ThemeMaterial.crystal => 0.39,
      ThemeMaterial.marble => 0.26,
      ThemeMaterial.wood => 0.14,
      ThemeMaterial.stone => 0.11,
      ThemeMaterial.leaf => 0.16,
    };
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(r, Radius.circular(s.shortestSide * 0.15)));
    canvas.drawRect(r, Paint()..shader = RadialGradient(
      center: const Alignment(-0.78, -0.82), radius: 1.28,
      colors: <Color>[
        Colors.white.withValues(alpha: brightness),
        accent.withValues(alpha: brightness * 0.22),
        Colors.transparent,
      ],
      stops: const <double>[0, 0.29, 1],
    ).createShader(r));
    switch (material) {
      case ThemeMaterial.glass:
        _glass(canvas, s, accent);
      case ThemeMaterial.crystal:
        _crystal(canvas, s, accent);
      case ThemeMaterial.marble:
        _marble(canvas, s, accent);
      case ThemeMaterial.wood:
        _wood(canvas, s);
      case ThemeMaterial.stone:
        _stone(canvas, s, base);
      case ThemeMaterial.leaf:
        _leaf(canvas, s, accent);
    }
    canvas.drawLine(Offset(s.width * .15, s.height * .075),
      Offset(s.width * .70, s.height * .075),
      Paint()..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(.55, s.shortestSide * .016)
        ..color = Colors.white.withValues(alpha: brightness));
    canvas.restore();
  }

  static void _spark(Canvas c, Offset p, double r, double a) {
    final paint = Paint()..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(.7, r * .13)
      ..color = Colors.white.withValues(alpha: a);
    c.drawLine(Offset(p.dx-r,p.dy), Offset(p.dx+r,p.dy), paint);
    c.drawLine(Offset(p.dx,p.dy-r), Offset(p.dx,p.dy+r), paint);
    c.drawCircle(p, r * .23, Paint()..color = Colors.white.withValues(alpha: a));
  }

  static void _glass(Canvas c, Size s, Color tint) {
    final w=s.width,h=s.height;
    final prism=Path()..moveTo(w*.07,h*.30)..lineTo(w*.68,h*.08)
      ..lineTo(w*.94,h*.18)..lineTo(w*.36,h*.43)..close();
    c.drawPath(prism, Paint()..shader=LinearGradient(
      begin: Alignment.topLeft,end: Alignment.bottomRight,
      colors:<Color>[
        Colors.white.withValues(alpha:.32),
        tint.withValues(alpha:.11),Colors.transparent
      ]).createShader(Offset.zero & s));
    final p=Paint()..style=PaintingStyle.stroke..strokeCap=StrokeCap.round
      ..strokeWidth=math.max(.55,s.shortestSide*.014)
      ..color=Colors.white.withValues(alpha:.48);
    c.drawLine(Offset(w*.14,h*.73),Offset(w*.77,h*.39),p);
    c.drawLine(Offset(w*.19,h*.79),Offset(w*.82,h*.46),
      p..color=tint.withValues(alpha:.34));
    _spark(c,Offset(w*.74,h*.23),s.shortestSide*.075,.70);
  }

  static void _crystal(Canvas c,Size s,Color accent) {
    final w=s.width,h=s.height;
    final center=Offset(w*.49,h*.53);
    final parts=<List<Offset>>[
      <Offset>[Offset(w*.52,h*.07),Offset(w*.10,h*.24),center],
      <Offset>[Offset(w*.52,h*.07),Offset(w*.79,h*.15),center],
      <Offset>[Offset(w*.79,h*.15),Offset(w*.89,h*.76),center],
      <Offset>[Offset(w*.89,h*.76),Offset(w*.30,h*.89),center],
    ];
    for(var i=0;i<parts.length;i++){
      final path=Path()..moveTo(parts[i][0].dx,parts[i][0].dy)
        ..lineTo(parts[i][1].dx,parts[i][1].dy)
        ..lineTo(parts[i][2].dx,parts[i][2].dy)..close();
      final alpha=(i.isEven ? .11 : .27);
      c.drawPath(path,Paint()..shader=LinearGradient(
        colors:<Color>[Colors.white.withValues(alpha:alpha),
          accent.withValues(alpha:alpha*.75)],
      ).createShader(Offset.zero & s));
    }
    _spark(c,Offset(w*.74,h*.24),s.shortestSide*.10,.84);
  }

  static void _marble(Canvas c,Size s,Color accent) {
    final w=s.width,h=s.height;
    for(var i=0;i<4;i++){
      final dy=(i-1.5)*h*.15;
      final path=Path()..moveTo(-w*.10,h*.22+dy)
        ..cubicTo(w*.18,h*.14+dy,w*.22,h*.67+dy,w*.48,h*.42+dy)
        ..cubicTo(w*.75,h*.12+dy,w*.82,h*.63+dy,w*1.1,h*.34+dy);
      c.drawPath(path,Paint()..style=PaintingStyle.stroke
        ..strokeWidth=math.max(.6,s.shortestSide*(i.isEven ? .022 : .012))
        ..color=(i.isEven?accent:Colors.black).withValues(alpha:i.isEven ? .35 : .21));
    }
  }

  static void _wood(Canvas c,Size s) {
    final w=s.width,h=s.height;
    for(var i=0;i<7;i++){
      final y=h*(.12+i*.105);
      final path=Path()..moveTo(w*.04,y)
        ..cubicTo(w*.29,y-h*(.045+(i%2)*.024),
          w*.54,y+h*.05,w*.93,y-h*.024);
      c.drawPath(path,Paint()..style=PaintingStyle.stroke
        ..strokeWidth=math.max(.45,s.shortestSide*.010)
        ..color=(i.isEven?const Color(0xFFFFD899):const Color(0xFF47210C))
          .withValues(alpha:i.isEven ? .22 : .27));
    }
  }

  static void _stone(Canvas c,Size s,Color base) {
    final w=s.width,h=s.height;
    final shadow=Paint()..color=Colors.black.withValues(alpha:.18);
    final gleam=Paint()..color=Colors.white.withValues(alpha:.16);
    for(var i=0;i<11;i++){
      final x=(.12+((i*37)%78)/100)*w;
      final y=(.11+((i*19)%78)/100)*h;
      final r=s.shortestSide*(.010+(i%3)*.003);
      c.drawCircle(Offset(x,y),r,shadow);
      c.drawCircle(Offset(x-r*.30,y-r*.35),r*.42,gleam);
    }
    final ridge=Path()..moveTo(w*.13,h*.34)..lineTo(w*.31,h*.28)
      ..lineTo(w*.53,h*.42)..lineTo(w*.72,h*.35)..lineTo(w*.85,h*.49);
    c.drawPath(ridge,Paint()..style=PaintingStyle.stroke
      ..strokeWidth=math.max(.5,s.shortestSide*.014)
      ..color=Color.lerp(base,Colors.white,.48)!.withValues(alpha:.33));
  }

  static void _leaf(Canvas c,Size s,Color accent) {
    final w=s.width,h=s.height;
    final vein=Paint()..style=PaintingStyle.stroke..strokeCap=StrokeCap.round
      ..strokeWidth=math.max(.55,s.shortestSide*.018)
      ..color=accent.withValues(alpha:.31);
    c.drawLine(Offset(w*.17,h*.86),Offset(w*.78,h*.17),vein);
    for(var i=0;i<4;i++){
      final t=(i+1)/5,x=w*(.17+.61*t),y=h*(.86-.69*t);
      c.drawLine(Offset(x,y),Offset(x-w*.16,y-h*.12),
        vein..strokeWidth=math.max(.45,s.shortestSide*.011));
      c.drawLine(Offset(x,y),Offset(x+w*.14,y+h*.10),vein);
    }
    _spark(c,Offset(w*.68,h*.27),s.shortestSide*.035,.33);
  }
}
