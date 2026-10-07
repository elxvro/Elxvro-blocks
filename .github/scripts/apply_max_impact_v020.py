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
# Fracture MAX IMPACT / Smooth Impact: keep the debris large and fast, but
# bound the amount of work created by a single clear. Performance mode has a
# much tighter budget. This avoids a raster/paint spike on large clears.
# ---------------------------------------------------------------------------
replace_once(
    'lib/effects/fracture_effect.dart',
    "  final performanceFactor = performanceMode ? 0.42 : 1.0;\n"
    "  final maxParticles = performanceMode ? 72 : 180;",
    "  final performanceFactor = performanceMode ? 0.45 : 1.35;\n"
    "  final maxParticles = performanceMode ? 72 : 220;",
)
replace_once(
    'lib/effects/fracture_effect.dart',
    "      final speed = profile.speed * (0.72 + random.nextDouble() * 0.58);\n"
    "      final angle = -pi * (0.12 + random.nextDouble() * 0.76);",
    "      final motionScale = performanceMode ? 0.86 : 1.55;\n"
    "      final sizeScale = performanceMode ? 0.92 : 1.35;\n"
    "      final lifetimeScale = performanceMode ? 0.88 : 0.98;\n"
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
    "  final shakeScale = performanceMode ? 0.40 : 1.30;",
)

# ---------------------------------------------------------------------------
# v0.20 uses its own physical material renderer. Do not rewrite block surfaces
# here; preserve MAX IMPACT only for fracture and board-impact behavior.
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Board impact: cap particles actually painted at once. Large clears need fewer
# simultaneous sprites because shockwave + flash already communicate impact.
# ---------------------------------------------------------------------------
replace_once(
    'lib/screens/game_screen.dart',
    "    final particles = burst.particles.map((particle) {",
    "    final maxVisibleParticles = widget.appState.performanceMode\n"
    "        ? 42\n"
    "        : cells.length >= 18\n"
    "            ? 110\n"
    "            : 150;\n"
    "    final particles = burst.particles.take(maxVisibleParticles).map((particle) {",
)
replace_once(
    'lib/screens/game_screen.dart',
    "        milliseconds: widget.appState.performanceMode ? 430 : 780,",
    "        milliseconds: widget.appState.performanceMode ? 420 : 820,",
)
replace_once(
    'lib/screens/game_screen.dart',
    "        vx: particle.vx * 0.11,\n"
    "        vy: particle.vy * 0.11,\n"
    "        radius: particle.size * (perfect ? 4.4 : 3.2),",
    "        vx: particle.vx * 0.15,\n"
    "        vy: particle.vy * 0.15,\n"
    "        radius: particle.size * (perfect ? 6.0 : 4.6),",
)
replace_once(
    'lib/screens/game_screen.dart',
    "                                    min(8.5, 1.28 * _impactLevel) *",
    "                                    min(10.5, 1.55 * _impactLevel) *",
)
replace_once(
    'lib/screens/game_screen.dart',
    "                                    min(3.4, 0.46 * _impactLevel) *",
    "                                    min(4.8, 0.66 * _impactLevel) *",
)
replace_once(
    'lib/screens/game_screen.dart',
    "                                    0.0018 *",
    "                                    0.0024 *",
)
replace_once(
    'lib/screens/game_screen.dart',
    "                                        0.0065 *",
    "                                        0.0085 *",
)
replace_once(
    'lib/screens/game_screen.dart',
    "                                                  : _theme.blockAccent.withValues(alpha: 0.14),",
    "                                                  : _theme.blockAccent.withValues(alpha: 0.25),",
)
replace_once(
    'lib/screens/game_screen.dart',
    "        ..strokeWidth = 2.0 + impact * 0.18\n"
    "        ..color = color.withValues(alpha: 0.24 * alpha);",
    "        ..strokeWidth = 2.8 + impact * 0.26\n"
    "        ..color = color.withValues(alpha: 0.40 * alpha);",
)
replace_once(
    'lib/screens/game_screen.dart',
    "        ..color = Colors.white.withValues(alpha: 0.72 * alpha);",
    "        ..color = Colors.white.withValues(alpha: 0.90 * alpha);",
)
replace_once(
    'lib/screens/game_screen.dart',
    "        (0.05 + 0.23 * Curves.easeOutCubic.transform(ringPhase));",
    "        (0.06 + 0.34 * Curves.easeOutCubic.transform(ringPhase));",
)
replace_once(
    'lib/screens/game_screen.dart',
    "        ..color = color.withValues(alpha: 0.42 * ringFade),",
    "        ..color = color.withValues(alpha: 0.62 * ringFade),",
)
replace_once(
    'lib/screens/game_screen.dart',
    "        (0.10 + 0.32 * Curves.easeOutQuart.transform(widePhase));",
    "        (0.13 + 0.43 * Curves.easeOutQuart.transform(widePhase));",
)

print('ELXVRO Blocks Smooth MAX IMPACT patch applied successfully.')
