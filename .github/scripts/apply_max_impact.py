#!/usr/bin/env python3
from pathlib import Path
import sys

ROOT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path('.')


def read(rel: str) -> str:
    return (ROOT / rel).read_text(encoding='utf-8')


def write(rel: str, text: str) -> None:
    (ROOT / rel).write_text(text, encoding='utf-8')


def replace_once(rel: str, old: str, new: str) -> None:
    text = read(rel)
    count = text.count(old)
    if count != 1:
        raise SystemExit(
            f'MAX IMPACT anchor mismatch: {rel}: expected 1, found {count}: {old[:100]!r}'
        )
    write(rel, text.replace(old, new, 1))


# ---------------------------------------------------------------------------
# Fracture MAX IMPACT: more pieces, larger debris, faster travel, stronger
# shake and a longer visible lifetime. Performance mode remains capped.
# ---------------------------------------------------------------------------
replace_once(
    'lib/effects/fracture_effect.dart',
    "  final performanceFactor = performanceMode ? 0.42 : 1.0;\n"
    "  final maxParticles = performanceMode ? 72 : 180;",
    "  final performanceFactor = performanceMode ? 0.55 : 1.95;\n"
    "  final maxParticles = performanceMode ? 96 : 340;",
)
replace_once(
    'lib/effects/fracture_effect.dart',
    "      final speed = profile.speed * (0.72 + random.nextDouble() * 0.58);\n"
    "      final angle = -pi * (0.12 + random.nextDouble() * 0.76);",
    "      final motionScale = performanceMode ? 0.88 : 1.72;\n"
    "      final sizeScale = performanceMode ? 0.95 : 1.42;\n"
    "      final lifetimeScale = performanceMode ? 0.92 : 1.10;\n"
    "      final speed = profile.speed * motionScale *\n"
    "          (0.72 + random.nextDouble() * 0.58);\n"
    "      final angle = -pi * (0.08 + random.nextDouble() * 0.84);",
)
replace_once(
    'lib/effects/fracture_effect.dart',
    "          vy: sin(angle) * speed - profile.lift * random.nextDouble(),\n"
    "          size: profile.size * (0.72 + random.nextDouble() * 0.52),",
    "          vy: sin(angle) * speed -\n"
    "              profile.lift * motionScale * random.nextDouble(),\n"
    "          size: profile.size * sizeScale *\n"
    "              (0.72 + random.nextDouble() * 0.52),",
)
replace_once(
    'lib/effects/fracture_effect.dart',
    "          lifetimeMs: (profile.lifetimeMs * (0.86 + random.nextDouble() * 0.28)).round(),",
    "          lifetimeMs: (profile.lifetimeMs * lifetimeScale *\n"
    "                  (0.86 + random.nextDouble() * 0.28))\n"
    "              .round(),",
)
replace_once(
    'lib/effects/fracture_effect.dart',
    "  final shakeScale = performanceMode ? 0.45 : 1.0;",
    "  final shakeScale = performanceMode ? 0.42 : 1.62;",
)

# ---------------------------------------------------------------------------
# Stronger block light: bright face, much stronger specular highlights and a
# soft halo outside each tile. This intentionally does not change dimensions.
# ---------------------------------------------------------------------------
replace_once(
    'lib/widgets/themed_block_tile.dart',
    "    _paintContactShadow(canvas, size, depth);\n"
    "    _paintDepthFaces(canvas, size, depth);",
    "    _paintOuterGlow(canvas, size);\n"
    "    _paintContactShadow(canvas, size, depth);\n"
    "    _paintDepthFaces(canvas, size, depth);",
)
replace_once(
    'lib/widgets/themed_block_tile.dart',
    "  void _paintContactShadow(Canvas canvas, Size size, double depth) {",
    "  void _paintOuterGlow(Canvas canvas, Size size) {\n"
    "    final strength = switch (material) {\n"
    "      ThemeMaterial.crystal => 0.72,\n"
    "      ThemeMaterial.glass => 0.64,\n"
    "      ThemeMaterial.marble => 0.48,\n"
    "      ThemeMaterial.wood => 0.34,\n"
    "      ThemeMaterial.stone => 0.30,\n"
    "      ThemeMaterial.leaf => 0.28,\n"
    "    };\n"
    "    final blurRadius = math.max(3.0, size.shortestSide * 0.24);\n"
    "    final rr = RRect.fromRectAndRadius(\n"
    "      Rect.fromLTWH(1.5, 1.5, size.width - 3, size.height - 3),\n"
    "      Radius.circular(size.shortestSide * 0.18),\n"
    "    );\n"
    "    canvas.drawRRect(\n"
    "      rr,\n"
    "      Paint()\n"
    "        ..style = PaintingStyle.stroke\n"
    "        ..strokeWidth = math.max(1.4, size.shortestSide * 0.055)\n"
    "        ..color = accent.withValues(alpha: strength)\n"
    "        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadius),\n"
    "    );\n"
    "    canvas.drawRRect(\n"
    "      rr,\n"
    "      Paint()\n"
    "        ..style = PaintingStyle.stroke\n"
    "        ..strokeWidth = math.max(0.8, size.shortestSide * 0.025)\n"
    "        ..color = Colors.white.withValues(alpha: strength * 0.42),\n"
    "    );\n"
    "  }\n\n"
    "  void _paintContactShadow(Canvas canvas, Size size, double depth) {",
)
replace_once(
    'lib/widgets/themed_block_tile.dart',
    "            Colors.white.withValues(alpha: 0.27),",
    "            Colors.white.withValues(alpha: 0.46),",
)
replace_once(
    'lib/widgets/themed_block_tile.dart',
    "      ThemeMaterial.glass => 0.44,\n"
    "      ThemeMaterial.crystal => 0.49,\n"
    "      ThemeMaterial.marble => 0.32,",
    "      ThemeMaterial.glass => 0.68,\n"
    "      ThemeMaterial.crystal => 0.74,\n"
    "      ThemeMaterial.marble => 0.50,",
)
replace_once(
    'lib/widgets/themed_block_tile.dart',
    "        ThemeMaterial.glass => 0.58,\n"
    "        ThemeMaterial.crystal => 0.62,\n"
    "        ThemeMaterial.marble => 0.42,\n"
    "        ThemeMaterial.stone => 0.30,\n"
    "        ThemeMaterial.wood => 0.34,\n"
    "        ThemeMaterial.leaf => 0.28,",
    "        ThemeMaterial.glass => 0.90,\n"
    "        ThemeMaterial.crystal => 0.96,\n"
    "        ThemeMaterial.marble => 0.72,\n"
    "        ThemeMaterial.stone => 0.55,\n"
    "        ThemeMaterial.wood => 0.60,\n"
    "        ThemeMaterial.leaf => 0.50,",
)
replace_once(
    'lib/widgets/themed_block_tile.dart',
    "          ..color = accent.withValues(alpha: 0.78 * flash),",
    "          ..color = accent.withValues(alpha: 0.98 * flash),",
)

# ---------------------------------------------------------------------------
# Board impact: larger visual debris, longer animation and stronger physical
# camera impulse. The line-clear engine itself is untouched.
# ---------------------------------------------------------------------------
replace_once(
    'lib/screens/game_screen.dart',
    "        milliseconds: widget.appState.performanceMode ? 430 : 780,",
    "        milliseconds: widget.appState.performanceMode ? 430 : 980,",
)
replace_once(
    'lib/screens/game_screen.dart',
    "        vx: particle.vx * 0.11,\n"
    "        vy: particle.vy * 0.11,\n"
    "        radius: particle.size * (perfect ? 4.4 : 3.2),",
    "        vx: particle.vx * 0.17,\n"
    "        vy: particle.vy * 0.17,\n"
    "        radius: particle.size * (perfect ? 6.8 : 5.2),",
)
replace_once(
    'lib/screens/game_screen.dart',
    "                                    min(8.5, 1.28 * _impactLevel) *",
    "                                    min(15.0, 2.10 * _impactLevel) *",
)
replace_once(
    'lib/screens/game_screen.dart',
    "                                    min(3.4, 0.46 * _impactLevel) *",
    "                                    min(7.0, 0.92 * _impactLevel) *",
)
replace_once(
    'lib/screens/game_screen.dart',
    "                                    0.0018 *",
    "                                    0.0034 *",
)
replace_once(
    'lib/screens/game_screen.dart',
    "                                        0.0065 *",
    "                                        0.0120 *",
)
replace_once(
    'lib/screens/game_screen.dart',
    "                                                  : _theme.blockAccent.withValues(alpha: 0.14),",
    "                                                  : _theme.blockAccent.withValues(alpha: 0.30),",
)
replace_once(
    'lib/screens/game_screen.dart',
    "        ..strokeWidth = 2.0 + impact * 0.18\n"
    "        ..color = color.withValues(alpha: 0.24 * alpha);",
    "        ..strokeWidth = 3.2 + impact * 0.32\n"
    "        ..color = color.withValues(alpha: 0.46 * alpha);",
)
replace_once(
    'lib/screens/game_screen.dart',
    "        ..color = Colors.white.withValues(alpha: 0.72 * alpha);",
    "        ..color = Colors.white.withValues(alpha: 0.95 * alpha);",
)
replace_once(
    'lib/screens/game_screen.dart',
    "        (0.05 + 0.23 * Curves.easeOutCubic.transform(ringPhase));",
    "        (0.06 + 0.38 * Curves.easeOutCubic.transform(ringPhase));",
)
replace_once(
    'lib/screens/game_screen.dart',
    "        ..color = color.withValues(alpha: 0.42 * ringFade),",
    "        ..color = color.withValues(alpha: 0.70 * ringFade),",
)
replace_once(
    'lib/screens/game_screen.dart',
    "        (0.10 + 0.32 * Curves.easeOutQuart.transform(widePhase));",
    "        (0.14 + 0.48 * Curves.easeOutQuart.transform(widePhase));",
)

print('ELXVRO Blocks MAX IMPACT patch applied successfully.')
