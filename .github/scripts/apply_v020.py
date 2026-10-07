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
            f'v0.20 patch anchor mismatch: {rel}: expected 1, found {count}: {old[:120]!r}'
        )
    write(rel, text.replace(old, new, 1))


def replace_block(rel: str, start: str, end: str, new_block: str) -> None:
    text = read(rel)
    if text.count(start) != 1:
        raise SystemExit(f'v0.20 block start mismatch: {rel}: {start!r}')
    start_i = text.index(start)
    end_i = text.find(end, start_i + len(start))
    if end_i < 0:
        raise SystemExit(f'v0.20 block end missing: {rel}: {end!r}')
    write(rel, text[:start_i] + new_block + text[end_i:])


# ---------------------------------------------------------------------------
# Audio 4.0: upbeat CC0 playlist, playful menu chimes, material break layers.
# ---------------------------------------------------------------------------
replace_once(
    'lib/services/audio_service.dart',
    "  static const List<String> _musicTracks = <String>[\n"
    "    'audio/bgm_magic_puzzle.ogg',\n"
    "    'audio/bgm_cozy_puzzle_3.ogg',\n"
    "    'audio/bgm_out_in_space.ogg',\n"
    "  ];\n",
    "  static const List<String> _musicTracks = <String>[\n"
    "    'audio/bgm_magic_puzzle.ogg',\n"
    "    'audio/bgm_cozy_puzzle_1.ogg',\n"
    "    'audio/bgm_cozy_puzzle_3.ogg',\n"
    "    'audio/bgm_platformer_alt.ogg',\n"
    "    'audio/bgm_othercenter.ogg',\n"
    "    'audio/bgm_cozy_title.ogg',\n"
    "  ];\n",
)

replace_once(
    'lib/services/audio_service.dart',
    "    'audio/firework_combo.wav': Duration(milliseconds: 1550),\n",
    "    'audio/firework_combo.wav': Duration(milliseconds: 1550),\n"
    "    'audio/firework_combo_v1.wav': Duration(milliseconds: 1550),\n"
    "    'audio/firework_combo_v2.wav': Duration(milliseconds: 1550),\n"
    "    'audio/firework_combo_v3.wav': Duration(milliseconds: 1550),\n"
    "    'audio/cc0_glass_break.wav': Duration(milliseconds: 1350),\n"
    "    'audio/cc0_wood_break.wav': Duration(milliseconds: 1350),\n"
    "    'audio/cc0_stone_break.wav': Duration(milliseconds: 1350),\n"
    "    'audio/menu_fun_v1.wav': Duration(milliseconds: 260),\n"
    "    'audio/menu_fun_v2.wav': Duration(milliseconds: 260),\n"
    "    'audio/menu_fun_v3.wav': Duration(milliseconds: 280),\n",
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
    "    final safe = _safeProfile(profile);\n"
    "    final breakAsset = switch (safe) {\n"
    "      'glass' || 'crystal' => 'audio/cc0_glass_break.wav',\n"
    "      'wood' || 'leaf' => 'audio/cc0_wood_break.wav',\n"
    "      _ => 'audio/cc0_stone_break.wav',\n"
    "    };\n\n"
    "    final fractureDelay = switch (safe) {\n"
    "      'glass' || 'crystal' => const Duration(milliseconds: 14),\n"
    "      'wood' || 'leaf' => const Duration(milliseconds: 30),\n"
    "      _ => const Duration(milliseconds: 42),\n"
    "    };\n\n"
    "    final strong = lineCount >= 3 || combo >= 4;\n"
    "    final medium = lineCount >= 2 || combo >= 2;\n"
    "    if (strong || medium) {\n"
    "      unawaited(\n"
    "        _duckMusic(\n"
    "          factor: strong ? 0.18 : 0.34,\n"
    "          duration: Duration(milliseconds: strong ? 1280 : 820),\n"
    "        ),\n"
    "      );\n"
    "    }\n\n"
    "    unawaited(_playVariant(safe, 'clear', 3, strong ? 0.90 : 0.78));\n"
    "    await Future<void>.delayed(fractureDelay);\n"
    "    unawaited(_play(breakAsset, strong ? 0.94 : medium ? 0.78 : 0.58));\n\n"
    "    if (strong) {\n"
    "      unawaited(_play('audio/\${safe}_combo.wav', 0.86));\n"
    "      await Future<void>.delayed(const Duration(milliseconds: 62));\n"
    "      final firework = 1 + _random.nextInt(3);\n"
    "      await _play('audio/firework_combo_v\$firework.wav', 0.92);\n"
    "      return;\n"
    "    }\n\n"
    "    if (medium && combo >= 3) {\n"
    "      final firework = 1 + _random.nextInt(3);\n"
    "      await _play('audio/firework_combo_v\$firework.wav', 0.70);\n"
    "    }\n"
    "  }\n\n",
)

replace_once(
    'lib/services/audio_service.dart',
    "  Future<void> playCombo(String profile) =>\n"
    "      _play('audio/\${_safeProfile(profile)}_combo.wav', 0.74);\n",
    "  Future<void> playCombo(String profile) async {\n"
    "    final safe = _safeProfile(profile);\n"
    "    unawaited(_play('audio/\${safe}_combo.wav', 0.82));\n"
    "    final firework = 1 + _random.nextInt(3);\n"
    "    await _play('audio/firework_combo_v\$firework.wav', 0.68);\n"
    "  }\n",
)

replace_once(
    'lib/services/audio_service.dart',
    "      'audio/fracture_impact.wav',\n"
    "      'audio/firework_combo.wav',\n"
    "    ]) {\n",
    "      'audio/fracture_impact.wav',\n"
    "      'audio/firework_combo.wav',\n"
    "      'audio/firework_combo_v1.wav',\n"
    "      'audio/firework_combo_v2.wav',\n"
    "      'audio/firework_combo_v3.wav',\n"
    "      'audio/cc0_glass_break.wav',\n"
    "      'audio/cc0_wood_break.wav',\n"
    "      'audio/cc0_stone_break.wav',\n"
    "      'audio/menu_fun_v1.wav',\n"
    "      'audio/menu_fun_v2.wav',\n"
    "      'audio/menu_fun_v3.wav',\n"
    "    ]) {\n",
)

replace_once(
    'lib/services/audio_service.dart',
    "      'audio/ui_tap_v\$variant.wav',\n"
    "      (_uiVolume * 0.68).clamp(0.0, 1.0).toDouble(),\n",
    "      'audio/menu_fun_v\$variant.wav',\n"
    "      (_uiVolume * 0.76).clamp(0.0, 1.0).toDouble(),\n",
)

# Modes copy: make it explicit that Adventure now uses Falling Blocks.
replace_once(
    'lib/screens/modes_screen.dart',
    "                        subtitle: '60 bölüm • kalıcı ilerleme',\n"
    "                        description:\n"
    "                            'Bölümleri sırayla aç, hız ve zor görevleri tamamla, ilk bitirişte coin kazan.',\n",
    "                        subtitle: '60 bölüm • düşen blok macerası',\n"
    "                        description:\n"
    "                            'Sürükleyerek kontrol et; her bölüm hızlanır, hedef ve renk düzeni değişir.',\n",
)

print('ELXVRO Blocks v0.20.0 campaign + Audio 4.0 patch applied successfully.')
