import 'package:flutter/material.dart';

import '../models/game_theme.dart';

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
    final palette = _paletteFor(theme);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            palette.top,
            palette.middle,
            palette.bottom,
          ],
          stops: const <double>[0, 0.48, 1],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned(
            left: -90,
            top: 80,
            child: _GlowOrb(
              size: 250,
              color: palette.accent.withValues(alpha: 0.10),
            ),
          ),
          Positioned(
            right: -120,
            bottom: 90,
            child: _GlowOrb(
              size: 310,
              color: theme.blockAccent.withValues(alpha: 0.08),
            ),
          ),
          ..._themeDecor(theme),
          child,
        ],
      ),
    );
  }

  List<Widget> _themeDecor(GameThemeData theme) {
    final accent = theme.blockAccent;
    switch (theme.material) {
      case ThemeMaterial.glass:
        return <Widget>[
          _facet(const Alignment(-0.72, -0.34), 150, -0.32, accent, 0.055),
          _facet(const Alignment(0.76, 0.10), 190, 0.28, accent, 0.045),
          _facet(const Alignment(-0.44, 0.72), 120, 0.18, accent, 0.040),
        ];
      case ThemeMaterial.crystal:
        return <Widget>[
          _diamond(const Alignment(-0.74, -0.22), 96, accent, 0.07),
          _diamond(const Alignment(0.72, 0.40), 138, accent, 0.055),
          _diamond(const Alignment(0.08, 0.78), 72, accent, 0.045),
        ];
      case ThemeMaterial.stone:
        return <Widget>[
          _rock(const Alignment(-0.78, -0.12), 150, accent, 0.045),
          _rock(const Alignment(0.74, 0.30), 180, accent, 0.038),
          _rock(const Alignment(-0.38, 0.78), 100, accent, 0.032),
        ];
      case ThemeMaterial.wood:
        return <Widget>[
          _ring(const Alignment(-0.74, -0.18), 180, accent, 0.050),
          _ring(const Alignment(0.70, 0.42), 230, accent, 0.038),
          _ring(const Alignment(-0.20, 0.84), 130, accent, 0.032),
        ];
      case ThemeMaterial.leaf:
        return <Widget>[
          _leaf(const Alignment(-0.72, -0.24), 120, -0.55, accent, 0.060),
          _leaf(const Alignment(0.72, 0.22), 150, 0.42, accent, 0.048),
          _leaf(const Alignment(-0.28, 0.78), 95, -0.16, accent, 0.040),
        ];
      case ThemeMaterial.marble:
        return <Widget>[
          _vein(const Alignment(-0.62, -0.24), 230, -0.34, accent, 0.052),
          _vein(const Alignment(0.66, 0.16), 260, 0.28, accent, 0.042),
          _vein(const Alignment(-0.26, 0.74), 180, -0.20, accent, 0.034),
        ];
    }
  }

  Widget _positioned({
    required Alignment alignment,
    required Widget child,
  }) {
    final left = alignment.x <= 0;
    final top = alignment.y <= 0;
    return Positioned(
      left: left ? 12 + (alignment.x + 1) * 60 : null,
      right: left ? null : 12 + (1 - alignment.x) * 60,
      top: top ? 60 + (alignment.y + 1) * 120 : null,
      bottom: top ? null : 40 + (1 - alignment.y) * 100,
      child: child,
    );
  }

  Widget _facet(
    Alignment alignment,
    double size,
    double angle,
    Color color,
    double opacity,
  ) {
    return _positioned(
      alignment: alignment,
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: size,
          height: size * 0.60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: color.withValues(alpha: opacity), width: 1.2),
            gradient: LinearGradient(
              colors: <Color>[
                Colors.white.withValues(alpha: opacity * 0.55),
                color.withValues(alpha: opacity * 0.26),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _diamond(Alignment alignment, double size, Color color, double opacity) {
    return _positioned(
      alignment: alignment,
      child: Transform.rotate(
        angle: 0.78,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.18),
            border: Border.all(color: color.withValues(alpha: opacity), width: 1.2),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Colors.white.withValues(alpha: opacity * 0.65),
                color.withValues(alpha: opacity * 0.30),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _rock(Alignment alignment, double size, Color color, double opacity) {
    return _positioned(
      alignment: alignment,
      child: Container(
        width: size,
        height: size * 0.58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(size * 0.24),
            topRight: Radius.circular(size * 0.10),
            bottomLeft: Radius.circular(size * 0.14),
            bottomRight: Radius.circular(size * 0.28),
          ),
          color: color.withValues(alpha: opacity * 0.42),
          border: Border.all(color: Colors.white.withValues(alpha: opacity * 0.35)),
        ),
      ),
    );
  }

  Widget _ring(Alignment alignment, double size, Color color, double opacity) {
    return _positioned(
      alignment: alignment,
      child: Container(
        width: size,
        height: size * 0.42,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: opacity), width: 1.4),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: color.withValues(alpha: opacity * 0.38),
              spreadRadius: -8,
              blurRadius: 0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _leaf(
    Alignment alignment,
    double size,
    double angle,
    Color color,
    double opacity,
  ) {
    return _positioned(
      alignment: alignment,
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: size,
          height: size * 0.52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(size),
              bottomRight: Radius.circular(size),
              topRight: Radius.circular(size * 0.18),
              bottomLeft: Radius.circular(size * 0.18),
            ),
            border: Border.all(color: color.withValues(alpha: opacity), width: 1.0),
            gradient: LinearGradient(
              colors: <Color>[
                color.withValues(alpha: opacity * 0.52),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _vein(
    Alignment alignment,
    double size,
    double angle,
    Color color,
    double opacity,
  ) {
    return _positioned(
      alignment: alignment,
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: size,
          height: 2,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            gradient: LinearGradient(
              colors: <Color>[
                Colors.transparent,
                color.withValues(alpha: opacity),
                Colors.white.withValues(alpha: opacity * 0.55),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  _GameplayPalette _paletteFor(GameThemeData theme) {
    return switch (theme.material) {
      ThemeMaterial.glass => const _GameplayPalette(
          Color(0xFF0E3144), Color(0xFF092532), Color(0xFF04151E), Color(0xFF6EE8FF)),
      ThemeMaterial.crystal => const _GameplayPalette(
          Color(0xFF241C50), Color(0xFF17163B), Color(0xFF0A0A20), Color(0xFF9AA8FF)),
      ThemeMaterial.stone => const _GameplayPalette(
          Color(0xFF303A45), Color(0xFF202832), Color(0xFF11171E), Color(0xFFB8C6D2)),
      ThemeMaterial.wood => const _GameplayPalette(
          Color(0xFF412916), Color(0xFF29180E), Color(0xFF140B06), Color(0xFFD79B61)),
      ThemeMaterial.leaf => const _GameplayPalette(
          Color(0xFF153D29), Color(0xFF102B20), Color(0xFF071710), Color(0xFF78D998)),
      ThemeMaterial.marble => const _GameplayPalette(
          Color(0xFF332B24), Color(0xFF211C19), Color(0xFF100D0B), Color(0xFFE5C788)),
    };
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: <Color>[color, Colors.transparent],
        ),
      ),
    );
  }
}

class _GameplayPalette {
  const _GameplayPalette(this.top, this.middle, this.bottom, this.accent);

  final Color top;
  final Color middle;
  final Color bottom;
  final Color accent;
}
