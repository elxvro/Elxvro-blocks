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
            f'v0.21 patch anchor mismatch: {rel}: expected 1, found {count}: {old[:120]!r}'
        )
    write(rel, text.replace(old, new, 1))

def replace_all_expected(rel: str, old: str, new: str, expected: int) -> None:
    text = read(rel)
    count = text.count(old)
    if count != expected:
        raise SystemExit(
            f'v0.21 patch count mismatch: {rel}: expected {expected}, found {count}: {old[:120]!r}'
        )
    write(rel, text.replace(old, new))

def replace_block(rel: str, start: str, end: str, block: str) -> None:
    text = read(rel)
    si = text.find(start)
    if si < 0 or text.find(start, si + 1) >= 0:
        raise SystemExit(f'v0.21 block start mismatch: {rel}: {start!r}')
    ei = text.find(end, si + len(start))
    if ei < 0:
        raise SystemExit(f'v0.21 block end missing: {rel}: {end!r}')
    write(rel, text[:si] + block + text[ei:])

# Audio 5.0: material-specific real break layers + multi-stage combo fireworks.
replace_once(
    'lib/services/audio_service.dart',
    "  Future<void> playPlace(String profile) =>\n"
    "      _playVariant(_safeProfile(profile), 'place', 3, 0.70);",
    "  Future<void> playPlace(String profile) =>\n"
    "      _playVariant(_safeProfile(profile), 'place', 3, 0.78);",
)

replace_block(
    'lib/services/audio_service.dart',
    "  Future<void> playClearTier(\n",
    "  Future<void> playCombo(String profile)",
    """  Future<void> playClearTier(
    String profile, {
    required int lineCount,
    required int combo,
  }) async {
    final safe = _safeProfile(profile);
    final proBreak = switch (safe) {
      'glass' => 'audio/pro_glass_break.wav',
      'crystal' => 'audio/pro_crystal_break.wav',
      'wood' => 'audio/pro_wood_break.wav',
      'leaf' => 'audio/pro_leaf_break.wav',
      'stone' => 'audio/pro_stone_break.wav',
      'marble' => 'audio/pro_marble_break.wav',
      _ => 'audio/pro_glass_break.wav',
    };
    final delay = switch (safe) {
      'glass' || 'crystal' => const Duration(milliseconds: 14),
      'wood' || 'leaf' => const Duration(milliseconds: 28),
      _ => const Duration(milliseconds: 38),
    };

    final strong = lineCount >= 3 || combo >= 4;
    final huge = lineCount >= 4 || combo >= 5;
    final medium = lineCount >= 2 || combo >= 2;

    if (strong || medium) {
      unawaited(
        _duckMusic(
          factor: strong ? 0.14 : 0.30,
          duration: Duration(milliseconds: strong ? 1480 : 900),
        ),
      );
    }

    unawaited(_playVariant(safe, 'clear', 3, strong ? 0.88 : medium ? 0.80 : 0.70));
    await Future<void>.delayed(delay);
    unawaited(_play(proBreak, strong ? 0.98 : medium ? 0.84 : 0.58));

    if (!medium) return;

    await Future<void>.delayed(const Duration(milliseconds: 34));
    unawaited(_play('audio/${safe}_combo.wav', strong ? 0.90 : 0.72));

    if (strong) {
      await Future<void>.delayed(const Duration(milliseconds: 54));
      final firework = 1 + _random.nextInt(3);
      unawaited(_play('audio/firework_combo_v$firework.wav', 0.94));
      if (huge) {
        await Future<void>.delayed(const Duration(milliseconds: 150));
        var second = 1 + _random.nextInt(3);
        if (second == firework) second = (second % 3) + 1;
        await _play('audio/firework_combo_v$second.wav', 0.76);
      }
    }
  }

""",
)

replace_block(
    'lib/services/audio_service.dart',
    "  Future<void> playCombo(String profile)",
    "  Future<void> playPerfect(String profile)",
    """  Future<void> playCombo(String profile) async {
    final safe = _safeProfile(profile);
    final proBreak = switch (safe) {
      'glass' => 'audio/pro_glass_break.wav',
      'crystal' => 'audio/pro_crystal_break.wav',
      'wood' => 'audio/pro_wood_break.wav',
      'leaf' => 'audio/pro_leaf_break.wav',
      'stone' => 'audio/pro_stone_break.wav',
      'marble' => 'audio/pro_marble_break.wav',
      _ => 'audio/pro_glass_break.wav',
    };
    unawaited(_duckMusic(factor: 0.24, duration: const Duration(milliseconds: 960)));
    unawaited(_play(proBreak, 0.72));
    unawaited(_play('audio/${safe}_combo.wav', 0.88));
    await Future<void>.delayed(const Duration(milliseconds: 62));
    final firework = 1 + _random.nextInt(3);
    await _play('audio/firework_combo_v$firework.wav', 0.78);
  }

""",
)

# Prewarm processed material break layers to avoid a first-hit latency spike.
replace_once(
    'lib/services/audio_service.dart',
    "      'audio/menu_fun_v3.wav',\n"
    "    ]) {\n",
    "      'audio/menu_fun_v3.wav',\n"
    "      'audio/pro_glass_break.wav',\n"
    "      'audio/pro_crystal_break.wav',\n"
    "      'audio/pro_wood_break.wav',\n"
    "      'audio/pro_leaf_break.wav',\n"
    "      'audio/pro_stone_break.wav',\n"
    "      'audio/pro_marble_break.wav',\n"
    "    ]) {\n",
)

# Modes: every card gets a live material mini-board instead of a flat icon tile.
replace_once(
    'lib/screens/modes_screen.dart',
    "import '../widgets/premium_background.dart';\n",
    "import '../widgets/premium_background.dart';\n"
    "import '../widgets/themed_block_tile.dart';\n",
)
replace_all_expected(
    'lib/screens/modes_screen.dart',
    "surface: selectedTheme.board,\n",
    "surface: selectedTheme.board,\n"
    "                        material: selectedTheme.material,\n"
    "                        block: selectedTheme.block,\n"
    "                        blockAccent: selectedTheme.blockAccent,\n",
    3,
)
replace_once(
    'lib/screens/modes_screen.dart',
    "    required this.surface,\n"
    "    required this.onTap,",
    "    required this.surface,\n"
    "    required this.material,\n"
    "    required this.block,\n"
    "    required this.blockAccent,\n"
    "    required this.onTap,",
)
replace_once(
    'lib/screens/modes_screen.dart',
    "  final Color surface;\n"
    "  final VoidCallback onTap;",
    "  final Color surface;\n"
    "  final ThemeMaterial material;\n"
    "  final Color block;\n"
    "  final Color blockAccent;\n"
    "  final VoidCallback onTap;",
)
replace_once(
    'lib/screens/modes_screen.dart',
    """              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(17),
                  color: accent.withValues(alpha: 0.11),
                  border: Border.all(color: accent.withValues(alpha: 0.18)),
                ),
                child: Icon(icon, color: accent, size: 28),
              ),""",
    """              _ModeMaterialPreview(
                icon: icon,
                material: material,
                base: block,
                accent: blockAccent,
                surface: surface,
              ),""",
)
replace_once(
    'lib/screens/modes_screen.dart',
    "class _Badge extends StatelessWidget {",
    """class _ModeMaterialPreview extends StatelessWidget {
  const _ModeMaterialPreview({
    required this.icon,
    required this.material,
    required this.base,
    required this.accent,
    required this.surface,
  });

  final IconData icon;
  final ThemeMaterial material;
  final Color base;
  final Color accent;
  final Color surface;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 66,
      height: 66,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color.lerp(surface, accent, 0.12)!,
            Color.lerp(surface, Colors.black, 0.22)!,
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
        boxShadow: <BoxShadow>[
          BoxShadow(color: accent.withValues(alpha: 0.12), blurRadius: 16),
        ],
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            left: 2,
            top: 2,
            width: 29,
            height: 29,
            child: ThemedBlockTile(material: material, base: base, accent: accent),
          ),
          Positioned(
            right: 2,
            bottom: 2,
            width: 29,
            height: 29,
            child: ThemedBlockTile(
              material: material,
              base: Color.lerp(base, accent, 0.20)!,
              accent: Colors.white,
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.58),
                border: Border.all(color: accent.withValues(alpha: 0.34)),
              ),
              child: Icon(icon, color: accent, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {""",
)

replace_once(
    'lib/screens/modes_screen.dart',
    "                            'Sürükleyerek kontrol et; her bölüm hızlanır, hedef ve renk düzeni değişir.',\n",
    "                            'Her bölümde puan hedefi yükselir; hız, başlangıç zorluğu ve renk paleti değişir.',\n",
)

# Theme screen copy and live preview become more material-focused.
replace_once(
    'lib/screens/themes_screen.dart',
    "      height: 158,",
    "      height: 190,",
)
replace_once(
    'lib/screens/themes_screen.dart',
    "                  'CANLI ÖNİZLEME',",
    "                  'GERÇEK MATERYAL ÖNİZLEME',",
)
replace_all_expected(
    'lib/screens/themes_screen.dart',
    "                  width: 52,\n                  height: 52,",
    "                  width: 58,\n                  height: 58,",
    3,
)

print('ELXVRO Blocks v0.21.0 Real Materials + Adventure 2.0 patch applied successfully.')
