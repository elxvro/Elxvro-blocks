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
            f'v0.22 patch anchor mismatch: {rel}: expected 1, found {count}: {old[:120]!r}'
        )
    write(rel, text.replace(old, new, 1))

def replace_min(rel: str, old: str, new: str, minimum: int = 1) -> None:
    text = read(rel)
    count = text.count(old)
    if count < minimum:
        raise SystemExit(
            f'v0.22 patch missing anchor: {rel}: expected >= {minimum}, found {count}: {old[:120]!r}'
        )
    write(rel, text.replace(old, new))

# ---------------------------------------------------------------------------
# Home: Turkish / English labels driven by persisted AppState language.
# ---------------------------------------------------------------------------
replace_once(
    'lib/screens/home_screen.dart',
    "import '../app_state.dart';\n",
    "import '../app_state.dart';\nimport '../l10n/app_strings.dart';\n",
)
replace_once(
    'lib/screens/home_screen.dart',
    "    final selectedTheme = gameThemes.firstWhere(\n",
    "    final l = AppStrings(appState.languageCode);\n"
    "    final selectedTheme = gameThemes.firstWhere(\n",
)
for old, new in [
    ("'EN YÜKSEK  ${appState.bestScore}'", " '${l.t('home.best')}  ${appState.bestScore}'"),
    ("label: 'OYNA'", "label: l.t('home.play')"),
    ("label: 'MODLAR'", "label: l.t('home.modes')"),
    ("label: 'GÜNLÜK ÖDÜL'", "label: l.t('home.daily')"),
    ("label: 'MAĞAZA'", "label: l.t('home.store')"),
    ("label: 'TEMALAR'", "label: l.t('home.themes')"),
    ("label: 'GÖREVLER'", "label: l.t('home.missions')"),
    ("label: 'BAŞARIMLAR'", "label: l.t('home.achievements')"),
    ("label: 'AYARLAR'", "label: l.t('home.settings')"),
    ("badge: 'v0.10.1'", "badge: 'v0.22.0'"),
]:
    replace_once('lib/screens/home_screen.dart', old, new)

# ---------------------------------------------------------------------------
# Settings: language selector + localized core settings labels.
# ---------------------------------------------------------------------------
replace_once(
    'lib/screens/settings_screen.dart',
    "import '../app_state.dart';\n",
    "import '../app_state.dart';\nimport '../l10n/app_strings.dart';\n",
)
replace_once(
    'lib/screens/settings_screen.dart',
    "            builder: (context, _) {\n              return Column(",
    "            builder: (context, _) {\n"
    "              final l = AppStrings(appState.languageCode);\n"
    "              return Column(",
)
replace_once(
    'lib/screens/settings_screen.dart',
    """                        const Expanded(
                          child: Text(
                            'AYARLAR',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFFFFD98B),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                        ),""",
    """                        Expanded(
                          child: Text(
                            l.t('settings.title'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFFFD98B),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                        ),""",
)
replace_once(
    'lib/screens/settings_screen.dart',
    "                      children: <Widget>[\n                        _SettingCard(",
    """                      children: <Widget>[
                        _LanguageCard(
                          title: l.t('settings.language'),
                          subtitle: l.t('settings.language_subtitle'),
                          selected: appState.languageCode,
                          turkishLabel: l.t('settings.turkish'),
                          englishLabel: l.t('settings.english'),
                          onChanged: appState.setLanguage,
                        ),
                        const SizedBox(height: 12),
                        _SettingCard(""",
)
for old, new in [
    ("title: 'ARKA PLAN MÜZİĞİ'", "title: l.t('settings.music')"),
    ("subtitle: 'Cozy Puzzle • bestelenmiş, sakin ve melodik oyun müziği'", "subtitle: l.t('settings.music_subtitle')"),
    ("title: 'MÜZİK SEVİYESİ'", "title: l.t('settings.music_level')"),
    ("title: 'SES EFEKTLERİ'", "title: l.t('settings.sfx')"),
    ("subtitle: 'Temaya özel yumuşak yerleştirme, temizleme ve combo sesleri'", "subtitle: l.t('settings.sfx_subtitle')"),
    ("title: 'EFEKT SEVİYESİ'", "title: l.t('settings.sfx_level')"),
    ("title: 'ARAYÜZ SESLERİ'", "title: l.t('settings.ui')"),
    ("subtitle: 'Menü ve butonlarda yumuşak dokunuş sesleri'", "subtitle: l.t('settings.ui_subtitle')"),
    ("title: 'ARAYÜZ SES SEVİYESİ'", "title: l.t('settings.ui_level')"),
    ("title: 'TİTREŞİM'", "title: l.t('settings.haptics')"),
    ("subtitle: 'Yerleştirme ve temizleme haptikleri'", "subtitle: l.t('settings.haptics_subtitle')"),
    ("title: 'PERFORMANS MODU'", "title: l.t('settings.performance')"),
    ("subtitle: '2D kırılma, toz, yaprak ve combo efektlerini azaltır; düşük güçlü cihazlarda daha akıcıdır'", "subtitle: l.t('settings.performance_subtitle')"),
    ("title: 'EĞİTİMİ TEKRAR GÖSTER'", "title: l.t('settings.tutorial')"),
    ("subtitle: 'Bir sonraki oyunda başlangıç eğitimini yeniden aç'", "subtitle: l.t('settings.tutorial_subtitle')"),
]:
    replace_once('lib/screens/settings_screen.dart', old, new)

replace_once(
    'lib/screens/settings_screen.dart',
    "                                'v0.21.0  •  Real Materials + Adventure 2.0',",
    "                                'v0.22.0  •  Languages + Themed Gameplay',",
)
replace_once(
    'lib/screens/settings_screen.dart',
    "class _VolumeCard extends StatelessWidget {",
    """class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.turkishLabel,
    required this.englishLabel,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final String selected;
  final String turkishLabel;
  final String englishLabel;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.065)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.language_rounded, color: Color(0xFFFFCF7A)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              segments: <ButtonSegment<String>>[
                ButtonSegment<String>(
                  value: 'tr',
                  label: Text(turkishLabel),
                  icon: const Text('TR'),
                ),
                ButtonSegment<String>(
                  value: 'en',
                  label: Text(englishLabel),
                  icon: const Text('EN'),
                ),
              ],
              selected: <String>{selected},
              onSelectionChanged: (value) {
                if (value.isNotEmpty) onChanged(value.first);
              },
              showSelectedIcon: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _VolumeCard extends StatelessWidget {""",
)

# ---------------------------------------------------------------------------
# Modes: localize the hub and core mode names.
# ---------------------------------------------------------------------------
replace_once(
    'lib/screens/modes_screen.dart',
    "import '../app_state.dart';\n",
    "import '../app_state.dart';\nimport '../l10n/app_strings.dart';\n",
)
replace_once(
    'lib/screens/modes_screen.dart',
    "    final selectedTheme = gameThemes.firstWhere(\n",
    "    final l = AppStrings(appState.languageCode);\n"
    "    final selectedTheme = gameThemes.firstWhere(\n",
)
replace_once('lib/screens/modes_screen.dart', "'OYUN MODLARI'", "l.t('modes.title')")
replace_once('lib/screens/modes_screen.dart', "title: 'MACERA'", "title: l.t('modes.adventure')")
replace_once('lib/screens/modes_screen.dart', "subtitle: '60 bölüm • düşen blok macerası'", "subtitle: l.t('modes.adventure_subtitle')")
replace_once(
    'lib/screens/modes_screen.dart',
    "                            'Her bölümde puan hedefi yükselir; hız, başlangıç zorluğu ve renk paleti değişir.',",
    "                            l.t('modes.adventure_description'),",
)
replace_once('lib/screens/modes_screen.dart', "bestLabel: 'TAMAMLANAN'", "bestLabel: l.t('modes.completed')")
replace_once('lib/screens/modes_screen.dart', "title: 'DÜŞEN BLOKLAR'", "title: l.t('modes.falling')")
replace_once(
    'lib/screens/modes_screen.dart',
    "                      title: data.title,",
    "                      title: _localizedModeTitle(mode, data.title, l),",
)
replace_once(
    'lib/screens/modes_screen.dart',
    "class _ModeCard extends StatelessWidget {",
    """String _localizedModeTitle(GameMode mode, String fallback, AppStrings l) {
  if (!l.isEnglish) return fallback;
  return switch (mode) {
    GameMode.classic => 'CLASSIC',
    GameMode.timed => 'TIMED',
    GameMode.comboRush => 'COMBO RUSH',
    GameMode.target => 'TARGET',
    GameMode.daily => 'DAILY CHALLENGE',
    GameMode.zen => 'ZEN',
    GameMode.hard => 'HARD',
  };
}

class _ModeCard extends StatelessWidget {""",
)

# ---------------------------------------------------------------------------
# Themes: localized navigation copy.
# ---------------------------------------------------------------------------
replace_once(
    'lib/screens/themes_screen.dart',
    "import '../app_state.dart';\n",
    "import '../app_state.dart';\nimport '../l10n/app_strings.dart';\n",
)
replace_once(
    'lib/screens/themes_screen.dart',
    "      builder: (context, _) {\n        final selected = gameThemes.firstWhere(",
    "      builder: (context, _) {\n"
    "        final l = AppStrings(appState.languageCode);\n"
    "        final selected = gameThemes.firstWhere(",
)
replace_once(
    'lib/screens/themes_screen.dart',
    """                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'TEMALAR',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2.5,
                                  color: Color(0xFFFFD99A),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Coin ile aç, kalıcı olarak kullan',
                                style: TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                            ],
                          ),
                        ),""",
    """                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                l.t('themes.title'),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2.5,
                                  color: Color(0xFFFFD99A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l.t('themes.subtitle'),
                                style: const TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                            ],
                          ),
                        ),""",
)

# ---------------------------------------------------------------------------
# Adventure: localized hub + card labels.
# ---------------------------------------------------------------------------
replace_once(
    'lib/screens/adventure_screen.dart',
    "import '../app_state.dart';\n",
    "import '../app_state.dart';\nimport '../l10n/app_strings.dart';\n",
)
replace_once(
    'lib/screens/adventure_screen.dart',
    "      builder: (context, _) {\n        final theme = gameThemes.firstWhere(",
    "      builder: (context, _) {\n"
    "        final l = AppStrings(appState.languageCode);\n"
    "        final theme = gameThemes.firstWhere(",
)
replace_once('lib/screens/adventure_screen.dart', "'MACERA'", "l.t('adventure.title')")
replace_once(
    'lib/screens/adventure_screen.dart',
    """                              const Expanded(
                                child: Text(
                                  '60 BÖLÜMLÜK YOLCULUK',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),""",
    """                              Expanded(
                                child: Text(
                                  l.t('adventure.journey'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),""",
)
replace_once(
    'lib/screens/adventure_screen.dart',
    "                            'Her bölümde hedef puan yükselir, düşüş hızlanır, başlangıç alanı zorlaşır ve renk paleti değişir.',",
    "                            l.t('adventure.description'),",
)
replace_once(
    'lib/screens/adventure_screen.dart',
    "                          onTap: unlocked",
    "                          languageCode: appState.languageCode,\n"
    "                          onTap: unlocked",
)
replace_once(
    'lib/screens/adventure_screen.dart',
    "    required this.surface,\n    required this.onTap,",
    "    required this.surface,\n    required this.languageCode,\n    required this.onTap,",
)
replace_once(
    'lib/screens/adventure_screen.dart',
    "  final Color surface;\n  final VoidCallback? onTap;",
    "  final Color surface;\n  final String languageCode;\n  final VoidCallback? onTap;",
)
replace_once(
    'lib/screens/adventure_screen.dart',
    "    final foreground = unlocked ? Colors.white : Colors.white30;",
    "    final foreground = unlocked ? Colors.white : Colors.white30;\n"
    "    final l = AppStrings(languageCode);",
)
replace_once(
    'lib/screens/adventure_screen.dart',
    "'BÖLÜM ${level.chapter} • ${level.difficultyLabel}'",
    "'${l.t('adventure.level')} ${level.chapter} • ${level.difficultyLabel}'",
)
replace_once('lib/screens/adventure_screen.dart', "'PUAN'", "l.t('adventure.score')")

# ---------------------------------------------------------------------------
# Falling Blocks: themed gameplay background, larger field, core language.
# ---------------------------------------------------------------------------
replace_once(
    'lib/screens/falling_blocks_screen.dart',
    "import '../app_state.dart';\n",
    "import '../app_state.dart';\nimport '../l10n/app_strings.dart';\n",
)
replace_once(
    'lib/screens/falling_blocks_screen.dart',
    "import '../widgets/premium_background.dart';\n",
    "import '../widgets/gameplay_background.dart';\n",
)
replace_once(
    'lib/screens/falling_blocks_screen.dart',
    "    if (_finishing) return;\n    _finishing = true;",
    "    if (_finishing) return;\n"
    "    final l = AppStrings(widget.appState.languageCode);\n"
    "    _finishing = true;",
)
replace_once(
    'lib/screens/falling_blocks_screen.dart',
    "_isAdventure\n                ? success\n                    ? 'BÖLÜM TAMAMLANDI'\n                    : 'BÖLÜM BAŞARISIZ'\n                : 'DÜŞEN BLOKLAR'",
    "_isAdventure\n                ? success\n                    ? l.t('falling.level_done')\n                    : l.t('falling.level_failed')\n                : l.t('modes.falling')",
)
replace_once(
    'lib/screens/falling_blocks_screen.dart',
    "              child: Text(_isAdventure ? 'BÖLÜMLER' : 'MODLAR'),",
    "              child: Text(_isAdventure ? l.t('falling.levels') : l.t('falling.modes')),",
)
replace_once(
    'lib/screens/falling_blocks_screen.dart',
    "              child: Text(canGoNext ? 'SONRAKİ' : 'TEKRAR OYNA'),",
    "              child: Text(canGoNext ? l.t('falling.next') : l.t('falling.retry')),",
)
replace_once(
    'lib/screens/falling_blocks_screen.dart',
    "    final active = _activeCells;\n    final ghost = _ghostCells;",
    "    final l = AppStrings(widget.appState.languageCode);\n"
    "    final active = _activeCells;\n    final ghost = _ghostCells;",
)
replace_once(
    'lib/screens/falling_blocks_screen.dart',
    """      body: PremiumBackground(
        top: _theme.backgroundTop,
        bottom: _theme.backgroundBottom,
        material: _theme.material,
        accent: _theme.blockAccent,
        child: SafeArea(""",
    """      body: GameplayBackground(
        theme: _theme,
        child: SafeArea(""",
)
replace_once(
    'lib/screens/falling_blocks_screen.dart',
    "                targetScore: _targetScore,\n                level: _difficultyLevel,",
    "                targetScore: _targetScore,\n                level: _difficultyLevel,\n                l: l,",
)
replace_once(
    'lib/screens/falling_blocks_screen.dart',
    "                    final widthByScreen = constraints.maxWidth - 16;\n                    final widthByHeight = constraints.maxHeight / 2;\n                    final boardWidth =\n                        min(widthByScreen, widthByHeight).clamp(220.0, 420.0);",
    "                    final widthByScreen = constraints.maxWidth - 6;\n"
    "                    final widthByHeight = (constraints.maxHeight + 18) / 2;\n"
    "                    final boardWidth =\n"
    "                        min(widthByScreen, widthByHeight).clamp(228.0, 448.0);",
)
replace_once(
    'lib/screens/falling_blocks_screen.dart',
    "                    'DURAKLATILDI',",
    "                    l.t('falling.paused'),",
)
replace_once(
    'lib/screens/falling_blocks_screen.dart',
    "                  'Sağa/sola sürükle • Aşağı kaydır',",
    "                  l.t('falling.drag_hint'),",
)
replace_once(
    'lib/screens/falling_blocks_screen.dart',
    "                onRotate: _rotate,\n                onDrop: _hardDrop,",
    "                onRotate: _rotate,\n                onDrop: _hardDrop,\n                l: l,",
)
replace_once(
    'lib/screens/falling_blocks_screen.dart',
    "    required this.onPause,\n  });",
    "    required this.onPause,\n    required this.l,\n  });",
)
replace_once(
    'lib/screens/falling_blocks_screen.dart',
    "  final VoidCallback onPause;",
    "  final VoidCallback onPause;\n  final AppStrings l;",
)
replace_once(
    'lib/screens/falling_blocks_screen.dart',
    """                  targetScore > 0
                      ? 'SKOR $score/$targetScore  •  ÇİZGİ $lines  •  ZORLUK $level'
                      : 'SKOR $score  •  ÇİZGİ $lines  •  HIZ $level',""",
    """                  targetScore > 0
                      ? '${l.t('falling.score')} $score/$targetScore  •  ${l.t('falling.lines')} $lines  •  ${l.t('falling.difficulty')} $level'
                      : '${l.t('falling.score')} $score  •  ${l.t('falling.lines')} $lines  •  ${l.t('falling.speed')} $level',""",
)
replace_once(
    'lib/screens/falling_blocks_screen.dart',
    "    required this.onDrop,\n  });",
    "    required this.onDrop,\n    required this.l,\n  });",
)
replace_once(
    'lib/screens/falling_blocks_screen.dart',
    "  final VoidCallback onDrop;",
    "  final VoidCallback onDrop;\n  final AppStrings l;",
)
replace_once(
    'lib/screens/falling_blocks_screen.dart',
    "          button(Icons.rotate_right_rounded, 'DÖNDÜR', onRotate),",
    "          button(Icons.rotate_right_rounded, l.t('falling.rotate'), onRotate),",
)
replace_once(
    'lib/screens/falling_blocks_screen.dart',
    """          button(
            Icons.vertical_align_bottom_rounded,
            'HIZLI İNDİR',
            onDrop,
            emphasized: true,
          ),""",
    """          button(
            Icons.vertical_align_bottom_rounded,
            l.t('falling.drop'),
            onDrop,
            emphasized: true,
          ),""",
)

# ---------------------------------------------------------------------------
# Main block puzzle gameplay: themed atmosphere + larger board + key labels.
# ---------------------------------------------------------------------------
replace_once(
    'lib/screens/game_screen.dart',
    "import '../app_state.dart';\n",
    "import '../app_state.dart';\nimport '../l10n/app_strings.dart';\n",
)
replace_once(
    'lib/screens/game_screen.dart',
    "import '../widgets/premium_background.dart';\n",
    "import '../widgets/gameplay_background.dart';\n",
)
replace_once(
    'lib/screens/game_screen.dart',
    "  Future<void> _showPauseMenu() async {\n    if (_finishing || _paused) return;",
    "  Future<void> _showPauseMenu() async {\n"
    "    if (_finishing || _paused) return;\n"
    "    final l = AppStrings(widget.appState.languageCode);",
)
replace_once(
    'lib/screens/game_screen.dart',
    "              title: const Text(\n                'OYUN DURAKLATILDI',",
    "              title: Text(\n                l.t('game.pause'),",
)
replace_once(
    'lib/screens/game_screen.dart',
    "                  child: Text(widget.adventureLevel != null ? 'BÖLÜMLER' : 'ANA MENÜ'),",
    "                  child: Text(widget.adventureLevel != null ? l.t('falling.levels') : l.t('game.home')),",
)
replace_once(
    'lib/screens/game_screen.dart',
    "                  child: const Text('YENİDEN'),",
    "                  child: Text(l.t('game.restart')),",
)
replace_once(
    'lib/screens/game_screen.dart',
    "                  child: const Text('DEVAM ET'),",
    "                  child: Text(l.t('game.resume')),",
)
replace_once(
    'lib/screens/game_screen.dart',
    "  Widget build(BuildContext context) {\n    return Scaffold(",
    "  Widget build(BuildContext context) {\n"
    "    final l = AppStrings(widget.appState.languageCode);\n"
    "    return Scaffold(",
)
replace_once(
    'lib/screens/game_screen.dart',
    """      body: PremiumBackground(
        top: _theme.backgroundTop,
        bottom: _theme.backgroundBottom,
        material: _theme.material,
        accent: _theme.blockAccent,
        child: SafeArea(""",
    """      body: GameplayBackground(
        theme: _theme,
        child: SafeArea(""",
)
replace_once(
    'lib/screens/game_screen.dart',
    "              final heightLimited = max(232.0, constraints.maxHeight - 282);\n"
    "              final boardExtent = min(\n"
    "                constraints.maxWidth - 28,\n"
    "                min(430.0, heightLimited),\n"
    "              );",
    "              final heightLimited = max(238.0, constraints.maxHeight - 252);\n"
    "              final boardExtent = min(\n"
    "                constraints.maxWidth - 12,\n"
    "                min(456.0, heightLimited),\n"
    "              );",
)
replace_once('lib/screens/game_screen.dart', "label: 'GERİ AL'", "label: l.t('game.undo')")
replace_once('lib/screens/game_screen.dart', "label: 'YENİLE'", "label: l.t('game.refresh')")
replace_once('lib/screens/game_screen.dart', "label: 'ÖZEL'", "label: l.t('game.special')")

print('ELXVRO Blocks v0.22.0 Languages + Themed Gameplay patch applied successfully.')
