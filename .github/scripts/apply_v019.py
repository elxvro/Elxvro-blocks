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
            f'v0.19 patch anchor mismatch: {rel}: expected 1, found {count}: {old[:110]!r}'
        )
    write(rel, text.replace(old, new, 1))


def replace_block(rel: str, start: str, end: str, new_block: str) -> None:
    text = read(rel)
    if text.count(start) != 1:
        raise SystemExit(f'v0.19 block start mismatch: {rel}: {start!r}')
    start_i = text.index(start)
    end_i = text.find(end, start_i + len(start))
    if end_i < 0:
        raise SystemExit(f'v0.19 block end missing: {rel}: {end!r}')
    write(rel, text[:start_i] + new_block + text[end_i:])


# ---------------------------------------------------------------------------
# v0.19 progression: Falling Blocks record + Adventure-locked themes.
# ---------------------------------------------------------------------------
replace_once(
    'lib/app_state.dart',
    "  static const String _adventureBestScoresKey = 'adventure_best_scores';\n",
    "  static const String _adventureBestScoresKey = 'adventure_best_scores';\n"
    "  static const String _fallingBlocksBestScoreKey = 'falling_blocks_best_score';\n",
)

replace_once(
    'lib/app_state.dart',
    "  int adventureUnlockedLevel = 1;\n",
    "  int adventureUnlockedLevel = 1;\n"
    "  int fallingBlocksBestScore = 0;\n",
)

replace_once(
    'lib/app_state.dart',
    "      _adventureBestScores.clear();\n",
    "      fallingBlocksBestScore = prefs.getInt(_fallingBlocksBestScoreKey) ?? 0;\n"
    "      _adventureBestScores.clear();\n",
)

replace_once(
    'lib/app_state.dart',
    "  bool isThemeUnlocked(String id) => _unlockedThemes.contains(id);\n",
    "  int themeAdventureRequirement(String id) {\n"
    "    switch (id) {\n"
    "      case 'obsidian':\n"
    "        return 15;\n"
    "      case 'polar_aurora':\n"
    "        return 30;\n"
    "      case 'magma':\n"
    "        return 45;\n"
    "      default:\n"
    "        return 0;\n"
    "    }\n"
    "  }\n\n"
    "  bool isThemeUnlocked(String id) {\n"
    "    if (_unlockedThemes.contains(id)) return true;\n"
    "    final requirement = themeAdventureRequirement(id);\n"
    "    return requirement > 0 && adventureCompletedCount >= requirement;\n"
    "  }\n",
)

replace_once(
    'lib/app_state.dart',
    "      case 'aurora':\n"
    "        return 1000;\n"
    "      default:\n",
    "      case 'aurora':\n"
    "        return 1000;\n"
    "      case 'obsidian':\n"
    "      case 'polar_aurora':\n"
    "      case 'magma':\n"
    "        return 0;\n"
    "      default:\n",
)

replace_once(
    'lib/app_state.dart',
    "    if (isThemeUnlocked(id)) {\n"
    "      await setTheme(id);\n"
    "      return true;\n"
    "    }\n"
    "    final price = themePrice(id);\n",
    "    if (isThemeUnlocked(id)) {\n"
    "      await setTheme(id);\n"
    "      return true;\n"
    "    }\n"
    "    if (themeAdventureRequirement(id) > 0) {\n"
    "      return false;\n"
    "    }\n"
    "    final price = themePrice(id);\n",
)

replace_once(
    'lib/app_state.dart',
    "  int get adventureCompletedCount => _adventureCompleted.length;\n",
    "  Future<void> recordFallingBlocksScore(int score) async {\n"
    "    if (score <= fallingBlocksBestScore) return;\n"
    "    fallingBlocksBestScore = score;\n"
    "    notifyListeners();\n"
    "    try {\n"
    "      final prefs = await SharedPreferences.getInstance();\n"
    "      await prefs.setInt(_fallingBlocksBestScoreKey, fallingBlocksBestScore);\n"
    "    } catch (error) {\n"
    "      debugPrint('ELXVRO Falling Blocks record save failed: $error');\n"
    "    }\n"
    "  }\n\n"
    "  int get adventureCompletedCount => _adventureCompleted.length;\n",
)


# ---------------------------------------------------------------------------
# Brighter existing themes + three new premium Adventure themes.
# ---------------------------------------------------------------------------
replace_once(
    'lib/models/game_theme.dart',
    "    block: Color(0xFF63DDF7),\n"
    "    blockAccent: Color(0xFFE8FCFF),\n",
    "    block: Color(0xFF74ECFF),\n"
    "    blockAccent: Color(0xFFF7FFFF),\n",
)

replace_once(
    'lib/models/game_theme.dart',
    "    block: Color(0xFF62D17E),\n"
    "    blockAccent: Color(0xFFD7FFB6),\n",
    "    block: Color(0xFF72EA90),\n"
    "    blockAccent: Color(0xFFE8FFC9),\n",
)

replace_once(
    'lib/models/game_theme.dart',
    "    block: Color(0xFF9B8CFF),\n"
    "    blockAccent: Color(0xFF92F6FF),\n",
    "    block: Color(0xFFB49DFF),\n"
    "    blockAccent: Color(0xFFB2FCFF),\n",
)

replace_once(
    'lib/models/game_theme.dart',
    "    block: Color(0xFFE8C77A),\n"
    "    blockAccent: Color(0xFFFFF0BE),\n"
    "  ),\n"
    "];\n",
    "    block: Color(0xFFFFD989),\n"
    "    blockAccent: Color(0xFFFFF7D6),\n"
    "  ),\n"
    "  GameThemeData(\n"
    "    id: 'obsidian',\n"
    "    name: 'Obsidyen',\n"
    "    subtitle: 'Siyah kristal • altın kırık damarlar • Macera 15',\n"
    "    material: ThemeMaterial.crystal,\n"
    "    audioProfile: 'stone',\n"
    "    backgroundTop: Color(0xFF20222A),\n"
    "    backgroundBottom: Color(0xFF050608),\n"
    "    board: Color(0xF21A1C22),\n"
    "    cell: Color(0xFF30333D),\n"
    "    block: Color(0xFF2D303A),\n"
    "    blockAccent: Color(0xFFFFD76A),\n"
    "  ),\n"
    "  GameThemeData(\n"
    "    id: 'polar_aurora',\n"
    "    name: 'Aurora',\n"
    "    subtitle: 'Elektrik moru • kutup cyanı • Macera 30',\n"
    "    material: ThemeMaterial.crystal,\n"
    "    audioProfile: 'crystal',\n"
    "    backgroundTop: Color(0xFF352B8F),\n"
    "    backgroundBottom: Color(0xFF061D33),\n"
    "    board: Color(0xE5213262),\n"
    "    cell: Color(0xFF344A78),\n"
    "    block: Color(0xFF8E7CFF),\n"
    "    blockAccent: Color(0xFF76FFF3),\n"
    "  ),\n"
    "  GameThemeData(\n"
    "    id: 'magma',\n"
    "    name: 'Magma',\n"
    "    subtitle: 'Volkan taşı • sıcak lava ışığı • Macera 45',\n"
    "    material: ThemeMaterial.stone,\n"
    "    audioProfile: 'stone',\n"
    "    backgroundTop: Color(0xFF7A2918),\n"
    "    backgroundBottom: Color(0xFF170706),\n"
    "    board: Color(0xEE412018),\n"
    "    cell: Color(0xFF633025),\n"
    "    block: Color(0xFFFF713B),\n"
    "    blockAccent: Color(0xFFFFE16B),\n"
    "  ),\n"
    "];\n",
)


# ---------------------------------------------------------------------------
# Theme store: show Adventure requirements instead of misleading coin prices.
# ---------------------------------------------------------------------------
replace_once(
    'lib/screens/themes_screen.dart',
    "                        final price = appState.themePrice(theme.id);\n"
    "                        return _ThemeCard(\n",
    "                        final price = appState.themePrice(theme.id);\n"
    "                        final adventureRequirement =\n"
    "                            appState.themeAdventureRequirement(theme.id);\n"
    "                        return _ThemeCard(\n",
)

replace_once(
    'lib/screens/themes_screen.dart',
    "                          price: price,\n"
    "                          onTap: () async {\n",
    "                          price: price,\n"
    "                          unlockLabel: adventureRequirement > 0\n"
    "                              ? 'MACERA $adventureRequirement'\n"
    "                              : null,\n"
    "                          onTap: () async {\n",
)

replace_once(
    'lib/screens/themes_screen.dart',
    "                            final ok = await appState.unlockTheme(theme.id);\n"
    "                            if (!context.mounted) return;\n",
    "                            if (adventureRequirement > 0 &&\n"
    "                                appState.adventureCompletedCount <\n"
    "                                    adventureRequirement) {\n"
    "                              if (!context.mounted) return;\n"
    "                              ScaffoldMessenger.of(context).showSnackBar(\n"
    "                                SnackBar(\n"
    "                                  content: Text(\n"
    "                                    'Bu tema için Macera’da $adventureRequirement bölüm tamamla.',\n"
    "                                  ),\n"
    "                                ),\n"
    "                              );\n"
    "                              return;\n"
    "                            }\n"
    "                            final ok = await appState.unlockTheme(theme.id);\n"
    "                            if (!context.mounted) return;\n",
)

replace_once(
    'lib/screens/themes_screen.dart',
    "    required this.price,\n"
    "    required this.onTap,\n",
    "    required this.price,\n"
    "    this.unlockLabel,\n"
    "    required this.onTap,\n",
)

replace_once(
    'lib/screens/themes_screen.dart',
    "  final int price;\n"
    "  final VoidCallback onTap;\n",
    "  final int price;\n"
    "  final String? unlockLabel;\n"
    "  final VoidCallback onTap;\n",
)

replace_once(
    'lib/screens/themes_screen.dart',
    "                    if (!unlocked) ...<Widget>[\n"
    "                      const SizedBox(height: 8),\n"
    "                      Row(\n"
    "                        mainAxisSize: MainAxisSize.min,\n"
    "                        children: <Widget>[\n"
    "                          const Icon(\n"
    "                            Icons.monetization_on_rounded,\n"
    "                            color: Color(0xFFFFC86E),\n"
    "                            size: 15,\n"
    "                          ),\n"
    "                          const SizedBox(width: 4),\n"
    "                          Text(\n"
    "                            '$price',\n"
    "                            style: const TextStyle(\n"
    "                              color: Color(0xFFFFD98B),\n"
    "                              fontWeight: FontWeight.w900,\n"
    "                              fontSize: 12,\n"
    "                            ),\n"
    "                          ),\n"
    "                        ],\n"
    "                      ),\n"
    "                    ],\n",
    "                    if (!unlocked) ...<Widget>[\n"
    "                      const SizedBox(height: 8),\n"
    "                      Row(\n"
    "                        mainAxisSize: MainAxisSize.min,\n"
    "                        children: <Widget>[\n"
    "                          Icon(\n"
    "                            unlockLabel != null\n"
    "                                ? Icons.map_rounded\n"
    "                                : Icons.monetization_on_rounded,\n"
    "                            color: const Color(0xFFFFC86E),\n"
    "                            size: 15,\n"
    "                          ),\n"
    "                          const SizedBox(width: 4),\n"
    "                          Text(\n"
    "                            unlockLabel ?? '$price',\n"
    "                            style: const TextStyle(\n"
    "                              color: Color(0xFFFFD98B),\n"
    "                              fontWeight: FontWeight.w900,\n"
    "                              fontSize: 12,\n"
    "                            ),\n"
    "                          ),\n"
    "                        ],\n"
    "                      ),\n"
    "                    ],\n",
)


# ---------------------------------------------------------------------------
# Modes hub: dedicated Falling Blocks arcade card.
# ---------------------------------------------------------------------------
replace_once(
    'lib/screens/modes_screen.dart',
    "import 'game_screen.dart';\n",
    "import 'falling_blocks_screen.dart';\n"
    "import 'game_screen.dart';\n",
)

replace_once(
    'lib/screens/modes_screen.dart',
    "                  itemCount: GameMode.values.length + 1,\n",
    "                  itemCount: GameMode.values.length + 2,\n",
)

replace_once(
    'lib/screens/modes_screen.dart',
    "                    final mode = GameMode.values[index - 1];\n",
    "                    if (index == 1) {\n"
    "                      return _ModeCard(\n"
    "                        icon: Icons.view_module_rounded,\n"
    "                        title: 'DÜŞEN BLOKLAR',\n"
    "                        subtitle: 'Arcade • düşür • döndür • çizgi temizle',\n"
    "                        description:\n"
    "                            'Klasik düşen blok mantığında ayrı 10×20 bölüm. Hız giderek artar.',\n"
    "                        best: appState.fallingBlocksBestScore,\n"
    "                        reward: 0,\n"
    "                        rewardReady: false,\n"
    "                        accent: accent,\n"
    "                        surface: selectedTheme.board,\n"
    "                        onTap: () {\n"
    "                          Navigator.of(context).push(\n"
    "                            MaterialPageRoute<void>(\n"
    "                              builder: (_) => FallingBlocksScreen(\n"
    "                                appState: appState,\n"
    "                              ),\n"
    "                            ),\n"
    "                          );\n"
    "                        },\n"
    "                      );\n"
    "                    }\n\n"
    "                    final mode = GameMode.values[index - 2];\n",
)


# ---------------------------------------------------------------------------
# Audio 3.0: louder realistic fracture layering + fireworks on strong combos.
# ---------------------------------------------------------------------------
replace_once(
    'lib/services/audio_service.dart',
    "    'audio/game_over.wav': Duration(milliseconds: 1300),\n",
    "    'audio/game_over.wav': Duration(milliseconds: 1300),\n"
    "    'audio/fracture_impact.wav': Duration(milliseconds: 1150),\n"
    "    'audio/firework_combo.wav': Duration(milliseconds: 1550),\n",
)

replace_block(
    'lib/services/audio_service.dart',
    "  Future<void> playClearTier(\n",
    "  Future<void> playCombo(String profile)",
    "  Future<void> playClearTier(\n"
    "    String profile, {\n"
    "    required int lineCount,\n"
    "    required int combo,\n"
    "  }) async {\n"
    "    final safe = _safeProfile(profile);\n\n"
    "    Duration fractureDelay() {\n"
    "      switch (safe) {\n"
    "        case 'glass':\n"
    "          return const Duration(milliseconds: 16);\n"
    "        case 'crystal':\n"
    "          return const Duration(milliseconds: 14);\n"
    "        case 'wood':\n"
    "          return const Duration(milliseconds: 32);\n"
    "        case 'stone':\n"
    "          return const Duration(milliseconds: 45);\n"
    "        case 'marble':\n"
    "          return const Duration(milliseconds: 42);\n"
    "        case 'leaf':\n"
    "          return const Duration(milliseconds: 26);\n"
    "        default:\n"
    "          return const Duration(milliseconds: 28);\n"
    "      }\n"
    "    }\n\n"
    "    if (lineCount >= 3 || combo >= 4) {\n"
    "      unawaited(\n"
    "        _duckMusic(\n"
    "          factor: 0.22,\n"
    "          duration: const Duration(milliseconds: 1200),\n"
    "        ),\n"
    "      );\n"
    "      unawaited(_playVariant(safe, 'clear', 3, 0.86));\n"
    "      unawaited(_play('audio/fracture_impact.wav', 0.82));\n"
    "      await Future<void>.delayed(fractureDelay());\n"
    "      unawaited(_play('audio/${safe}_combo.wav', 0.90));\n"
    "      await Future<void>.delayed(const Duration(milliseconds: 72));\n"
    "      await _play('audio/firework_combo.wav', 0.88);\n"
    "      return;\n"
    "    }\n\n"
    "    if (lineCount >= 2 || combo >= 2) {\n"
    "      unawaited(\n"
    "        _duckMusic(\n"
    "          factor: 0.38,\n"
    "          duration: const Duration(milliseconds: 780),\n"
    "        ),\n"
    "      );\n"
    "      unawaited(_playVariant(safe, 'clear', 3, 0.78));\n"
    "      await Future<void>.delayed(fractureDelay());\n"
    "      unawaited(_play('audio/fracture_impact.wav', 0.64));\n"
    "      if (combo >= 3) {\n"
    "        await Future<void>.delayed(const Duration(milliseconds: 60));\n"
    "        await _play('audio/firework_combo.wav', 0.70);\n"
    "      }\n"
    "      return;\n"
    "    }\n\n"
    "    await _playVariant(safe, 'clear', 3, 0.72);\n"
    "  }\n\n",
)

replace_once(
    'lib/services/audio_service.dart',
    "      'audio/game_over.wav',\n"
    "    ]) {\n",
    "      'audio/game_over.wav',\n"
    "      'audio/fracture_impact.wav',\n"
    "      'audio/firework_combo.wav',\n"
    "    ]) {\n",
)


# ---------------------------------------------------------------------------
# Legacy regression test compatibility: v0.19 expands theme catalog 6 -> 9.
# ---------------------------------------------------------------------------
theme_test = ROOT / 'test/theme_refresh_test.dart'
if theme_test.exists():
    text = theme_test.read_text(encoding='utf-8')
    text = text.replace('expect(gameThemes.length, 6);', 'expect(gameThemes.length, 9);')
    theme_test.write_text(text, encoding='utf-8')

print('ELXVRO Blocks v0.19.0 themes + audio + Falling Blocks patch applied successfully.')
