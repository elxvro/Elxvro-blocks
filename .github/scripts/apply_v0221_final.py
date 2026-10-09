#!/usr/bin/env python3
from pathlib import Path
import sys

ROOT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path('.')

def patch(rel, replacements):
    p = ROOT / rel
    text = p.read_text(encoding='utf-8')
    for old, new in replacements:
        text = text.replace(old, new)
    p.write_text(text, encoding='utf-8')

# Home: remaining badges and dynamic labels after v0.22 localization.
patch('lib/screens/home_screen.dart', [
    ("badge: 'YENİ'", "badge: AppStrings.current.f('YENİ', 'NEW')"),
    ("badge: appState.dailyRewardAvailable ? 'HAZIR' : '${appState.loginStreak}. GÜN'",
     "badge: appState.dailyRewardAvailable ? AppStrings.current.f('HAZIR', 'READY') : AppStrings.current.f('${appState.loginStreak}. GÜN', 'DAY ${appState.loginStreak}')"),
    ("label: 'İSTATİSTİK'", "label: AppStrings.current.f('İSTATİSTİK', 'STATISTICS')"),
    ("label: 'LİDERLİK MERKEZİ'", "label: AppStrings.current.f('LİDERLİK MERKEZİ', 'LEADERBOARD HUB')"),
    ("badge: appState.weeklyRewardAvailable ? 'ÖDÜL HAZIR' : 'HAFTALIK'",
     "badge: appState.weeklyRewardAvailable ? AppStrings.current.f('ÖDÜL HAZIR', 'REWARD READY') : AppStrings.current.f('HAFTALIK', 'WEEKLY')"),
    ("label: 'PROFİL & SEVİYE'", "label: AppStrings.current.f('PROFİL & SEVİYE', 'PROFILE & LEVEL')"),
    ("'SEVİYE ${appState.playerLevel}'", "AppStrings.current.f('SEVİYE ${appState.playerLevel}', 'LEVEL ${appState.playerLevel}')"),
])

# Modes: remaining descriptive copy.
patch('lib/screens/modes_screen.dart', [
    ("'Macera, Combo Rush, günlük challenge, Klasik, Zen ve Zor mod ile farklı hedeflerde ilerle.'",
     "AppStrings.current.f('Macera, Combo Rush, günlük challenge, Klasik, Zen ve Zor mod ile farklı hedeflerde ilerle.', 'Choose Adventure, Combo Rush, Daily Challenge, Classic, Zen or Hard mode.')"),
    ("'Arcade • düşür • döndür • çizgi temizle'",
     "AppStrings.current.f('Arcade • düşür • döndür • çizgi temizle', 'Arcade • drop • rotate • clear lines')"),
    ("'Klasik düşen blok mantığında ayrı 10×20 bölüm. Hız giderek artar.'",
     "AppStrings.current.f('Klasik düşen blok mantığında ayrı 10×20 bölüm. Hız giderek artar.', 'A dedicated 10×20 falling block mode where speed increases over time.')"),
])

# Themes: unlock feedback and preview label.
patch('lib/screens/themes_screen.dart', [
    ("'GERÇEK MATERYAL ÖNİZLEME'", "AppStrings.current.f('GERÇEK MATERYAL ÖNİZLEME', 'REAL MATERIAL PREVIEW')"),
    ("? '${theme.name} teması açıldı.'", "? (AppStrings.current.isEnglish ? 'Theme unlocked.' : '${theme.name} teması açıldı.')"),
])

# Adventure: difficulty label line.
patch('lib/screens/adventure_screen.dart', [
    ("'BÖLÜM ${level.chapter} • ${level.difficultyLabel}'",
     "AppStrings.current.f('BÖLÜM ${level.chapter} • ${level.difficultyLabel}', 'LEVEL ${level.chapter} • ${level.difficultyLabel}')"),
])

# Falling Blocks: result copy that was not part of v0.22 base localization.
patch('lib/screens/falling_blocks_screen.dart', [
    ("? 'Hedef $_targetScore puan  •  $_lines çizgi'",
     "? AppStrings.current.f('Hedef $_targetScore puan  •  $_lines çizgi', 'Target $_targetScore score  •  $_lines lines')"),
    (": '$_lines çizgi  •  Seviye $_arcadeLevel\\n'",
     ": AppStrings.current.f('$_lines çizgi  •  Seviye $_arcadeLevel\\n', '$_lines lines  •  Level $_arcadeLevel\\n')"),
    ("'En iyi: ${widget.appState.fallingBlocksBestScore}'",
     "AppStrings.current.f('En iyi: ${widget.appState.fallingBlocksBestScore}', 'Best: ${widget.appState.fallingBlocksBestScore}')"),
    ("'MACERA • BÖLÜM ${widget.adventureLevel!.number}'",
     "AppStrings.current.f('MACERA • BÖLÜM ${widget.adventureLevel!.number}', 'ADVENTURE • LEVEL ${widget.adventureLevel!.number}')"),
])

# Main puzzle gameplay: dialogs, event banners, tutorial and end-game copy.
patch('lib/screens/game_screen.dart', [
    ("'Bölüm ${adventure.chapter} • ${adventure.difficultyLabel}'",
     "AppStrings.current.f('Bölüm ${adventure.chapter} • ${adventure.difficultyLabel}', 'Level ${adventure.chapter} • ${adventure.difficultyLabel}')"),
    ("'BÖLÜM TAMAM'", "AppStrings.current.f('BÖLÜM TAMAM', 'LEVEL COMPLETE')"),
    ("'İLK REKORUNU YAZ'", "AppStrings.current.f('İLK REKORUNU YAZ', 'SET YOUR FIRST RECORD')"),
    ("'YENİ REKOR'", "AppStrings.current.f('YENİ REKOR', 'NEW RECORD')"),
    ("'SÜRE DOLDU'", "AppStrings.current.f('SÜRE DOLDU', 'TIME UP')"),
    ("'OYUNA DEVAM EDİLDİ'", "AppStrings.current.f('OYUNA DEVAM EDİLDİ', 'GAME RESUMED')"),
    ("'TEMİZLEME'", "AppStrings.current.f('TEMİZLEME', 'CLEAR')"),
    ("'YENİ REKOR  •  ${_score}'", "AppStrings.current.f('YENİ REKOR  •  ${_score}', 'NEW RECORD  •  ${_score}')"),
    ("'KRİTİK HAMLE • GÜÇ KULLAN'", "AppStrings.current.f('KRİTİK HAMLE • GÜÇ KULLAN', 'CRITICAL MOVE • USE A POWER')"),
    ("'HAMLE KALMADI'", "AppStrings.current.f('HAMLE KALMADI', 'NO MOVES LEFT')"),
    ("'ZEN NEFESİ • TAHTA RAHATLADI'", "AppStrings.current.f('ZEN NEFESİ • TAHTA RAHATLADI', 'ZEN BREATH • BOARD RELIEVED')"),
    ("'YENİ KİŞİSEL REKOR'", "AppStrings.current.f('YENİ KİŞİSEL REKOR', 'NEW PERSONAL BEST')"),
    ("'BÖLÜM HEDEFİ  ${adventure.targetScore}'", "AppStrings.current.f('BÖLÜM HEDEFİ  ${adventure.targetScore}', 'LEVEL TARGET  ${adventure.targetScore}')"),
    ("'SEVİYE ${progression.levelAfter}'", "AppStrings.current.f('SEVİYE ${progression.levelAfter}', 'LEVEL ${progression.levelAfter}')"),
    ("'+${progression.milestoneSpecials} ÖZEL'", "AppStrings.current.f('+${progression.milestoneSpecials} ÖZEL', '+${progression.milestoneSpecials} SPECIAL')"),
    ("'+$modeReward COIN KAZANDIN'", "AppStrings.current.f('+$modeReward COIN KAZANDIN', '+$modeReward COINS EARNED')"),
    ("'TAHTA DOLUYOR • ALAN AÇ'", "AppStrings.current.f('TAHTA DOLUYOR • ALAN AÇ', 'BOARD FILLING • MAKE SPACE')"),
    ("const _Rule(text: '1. Bloğu sürükle; hayalet alan nereye oturacağını gösterir.')",
     "_Rule(text: AppStrings.current.f('1. Bloğu sürükle; hayalet alan nereye oturacağını gösterir.', '1. Drag a block; the ghost shows where it will land.'))"),
    ("const _Rule(text: '2. Dolu satır veya sütunları temizleyerek combo yap.')",
     "_Rule(text: AppStrings.current.f('2. Dolu satır veya sütunları temizleyerek combo yap.', '2. Clear full rows or columns to build combos.'))"),
    ("const _Rule(text: '3. Özel bloklar yalnızca ÖZEL hakkını kullandığında devreye girer.')",
     "_Rule(text: AppStrings.current.f('3. Özel bloklar yalnızca ÖZEL hakkını kullandığında devreye girer.', '3. Special blocks appear when you use a SPECIAL charge.'))"),
    ("const _Rule(text: '4. Her oyunda 1 ücretsiz Geri Al ve 1 Yenile hakkın var.')",
     "_Rule(text: AppStrings.current.f('4. Her oyunda 1 ücretsiz Geri Al ve 1 Yenile hakkın var.', '4. Every game gives 1 free Undo and 1 free Refresh.'))"),
    ("const _Rule(text: '5. Mağazadan ekstra hak ve Özel Blok gücü alabilirsin.')",
     "_Rule(text: AppStrings.current.f('5. Mağazadan ekstra hak ve Özel Blok gücü alabilirsin.', '5. Buy extra charges and Special Block power from the Store.'))"),
    ("const _Rule(text: '6. Mod hedefini tamamla veya mümkün olan en iyi skoru yap.')",
     "_Rule(text: AppStrings.current.f('6. Mod hedefini tamamla veya mümkün olan en iyi skoru yap.', '6. Complete the objective or chase your best score.'))"),
])

# Settings: remaining system feedback.
patch('lib/screens/settings_screen.dart', [
    ("'Eğitim bir sonraki oyunda gösterilecek.'",
     "AppStrings.current.f('Eğitim bir sonraki oyunda gösterilecek.', 'The tutorial will be shown in the next game.')"),
    ("'Altyapı hazır • Play Console bağlantısı sonraki sürümde açılabilir'",
     "AppStrings.current.f('Altyapı hazır • Play Console bağlantısı sonraki sürümde açılabilir', 'Infrastructure ready • Play Console connection can be enabled later')"),
    ("'HAZIRLIK'", "AppStrings.current.f('HAZIRLIK', 'PREPARING')"),
])


# Extra gameplay dialog/tutorial strings and const cleanup.
patch('lib/screens/game_screen.dart', [
    ("'HIZLI EĞİTİM'", "AppStrings.current.f('HIZLI EĞİTİM', 'QUICK TUTORIAL')"),
    ("'SÜRÜKLE & BIRAK'", "AppStrings.current.f('SÜRÜKLE & BIRAK', 'DRAG & DROP')"),
    ("'Alttaki blokları tahtadaki hayalet konuma bırak.'", "AppStrings.current.f('Alttaki blokları tahtadaki hayalet konuma bırak.', 'Drag the blocks onto the ghost position.')"),
    ("'ÇİZGİLERİ TEMİZLE'", "AppStrings.current.f('ÇİZGİLERİ TEMİZLE', 'CLEAR LINES')"),
    ("'Dolu satır ve sütunlar temizlenir; seri yaparsan combo büyür.'", "AppStrings.current.f('Dolu satır ve sütunlar temizlenir; seri yaparsan combo büyür.', 'Full rows and columns clear. Consecutive clears grow the combo.')"),
    ("'Tahtayı tamamen boşaltırsan +1000 skor ve bonus coin kazanırsın.'", "AppStrings.current.f('Tahtayı tamamen boşaltırsan +1000 skor ve bonus coin kazanırsın.', 'Clear the full board to earn +1000 score and bonus coins.')"),
    ("'GÜÇLER'", "AppStrings.current.f('GÜÇLER', 'POWER UPS')"),
    ("'Geri Al, Yenile ve Özel blok haklarını kritik anda kullan.'", "AppStrings.current.f('Geri Al, Yenile ve Özel blok haklarını kritik anda kullan.', 'Use Undo, Refresh and Special Block charges at critical moments.')"),
    ("'OYUNA BAŞLA'", "AppStrings.current.f('OYUNA BAŞLA', 'START GAME')"),
    ("'Ses efektleri'", "AppStrings.current.f('Ses efektleri', 'Sound effects')"),
    ("'Müzik'", "AppStrings.current.f('Müzik', 'Music')"),
    ("'Titreşim'", "AppStrings.current.f('Titreşim', 'Haptics')"),
    ("'YENİ REKOR!'", "AppStrings.current.f('YENİ REKOR!', 'NEW RECORD!')"),
    ("'OYUN BİTTİ'", "AppStrings.current.f('OYUN BİTTİ', 'GAME OVER')"),
    ("'BÖLÜM TAMAMLANDI'", "AppStrings.current.f('BÖLÜM TAMAMLANDI', 'LEVEL COMPLETE')"),
    ("'BÖLÜM BAŞARISIZ'", "AppStrings.current.f('BÖLÜM BAŞARISIZ', 'LEVEL FAILED')"),
    ("'HEDEF TAMAMLANDI'", "AppStrings.current.f('HEDEF TAMAMLANDI', 'TARGET COMPLETE')"),
    ("'CHALLENGE BİTTİ'", "AppStrings.current.f('CHALLENGE BİTTİ', 'CHALLENGE OVER')"),
    ("'ZOR MOD BİTTİ'", "AppStrings.current.f('ZOR MOD BİTTİ', 'HARD MODE OVER')"),
    ("'ZEN OTURUMU'", "AppStrings.current.f('ZEN OTURUMU', 'ZEN SESSION')"),
    ("'ÇİZGİ'", "AppStrings.current.f('ÇİZGİ', 'LINES')"),
    ("'BLOK'", "AppStrings.current.f('BLOK', 'BLOCK')"),
    ("'ANA MENÜ'", "AppStrings.current.f('ANA MENÜ', 'MAIN MENU')"),
    ("'YENİDEN'", "AppStrings.current.f('YENİDEN', 'RESTART')"),
    ("'DEVAM ET'", "AppStrings.current.f('DEVAM ET', 'RESUME')"),
    ("'GERİ AL'", "AppStrings.current.f('GERİ AL', 'UNDO')"),
    ("'YENİLE'", "AppStrings.current.f('YENİLE', 'REFRESH')"),
    ("'ÖZEL'", "AppStrings.current.f('ÖZEL', 'SPECIAL')"),
    ("'Nasıl oynanır?'", "AppStrings.current.f('Nasıl oynanır?', 'How to play?')"),
])

for rel in [
    'lib/screens/game_screen.dart',
    'lib/screens/settings_screen.dart',
    'lib/screens/home_screen.dart',
    'lib/screens/modes_screen.dart',
    'lib/screens/themes_screen.dart',
    'lib/screens/adventure_screen.dart',
    'lib/screens/falling_blocks_screen.dart',
]:
    p = ROOT / rel
    text = p.read_text(encoding='utf-8')
    text = text.replace('const Text(', 'Text(')
    text = text.replace('const Column(', 'Column(')
    text = text.replace('const Expanded(', 'Expanded(')
    text = text.replace('children: const <Widget>[', 'children: <Widget>[')
    text = text.replace('const _TutorialLine(', '_TutorialLine(')
    text = text.replace('const _StatusCard(', '_StatusCard(')
    text = text.replace('const SnackBar(', 'SnackBar(')
    p.write_text(text, encoding='utf-8')


# Final 7 Turkish UI strings found by validation.
patch('lib/screens/modes_screen.dart', [
    ("_Badge(label: 'ÖDÜL HAZIR', accent: accent)",
     "_Badge(label: AppStrings.current.f('ÖDÜL HAZIR', 'REWARD READY'), accent: accent)"),
])

patch('lib/screens/themes_screen.dart', [
    ("'Bu tema için Macera’da $adventureRequirement bölüm tamamla.'",
     "AppStrings.current.f('Bu tema için Macera’da $adventureRequirement bölüm tamamla.', 'Complete $adventureRequirement Adventure levels to unlock this theme.')"),
])

patch('lib/screens/falling_blocks_screen.dart', [
    (": 'DÜŞEN BLOKLAR',",
     ": AppStrings.current.f('DÜŞEN BLOKLAR', 'FALLING BLOCKS'),"),
])

patch('lib/screens/game_screen.dart', [
    ("text: 'Tahtayı tamamen boşaltırsan +1000 skor, +100 coin ve +75 XP kazanırsın.'",
     "text: AppStrings.current.f('Tahtayı tamamen boşaltırsan +1000 skor, +100 coin ve +75 XP kazanırsın.', 'Clear the entire board to earn +1000 score, +100 coins and +75 XP.')"),
    ("title = widget.mode == GameMode.comboRush ? 'COMBO RUSH BİTTİ' : reason;",
     "title = widget.mode == GameMode.comboRush ? AppStrings.current.f('COMBO RUSH BİTTİ', 'COMBO RUSH OVER') : reason;"),
    ("if (combo >= 5) return 'MEGA SERİ x$combo';",
     "if (combo >= 5) return AppStrings.current.f('MEGA SERİ x$combo', 'MEGA STREAK x$combo');"),
    ("return 'SERİ x$combo';",
     "return AppStrings.current.f('SERİ x$combo', 'STREAK x$combo');"),
])


# Preserve cumulative AppState features added by older patches while syncing language globally.
app_state = ROOT / 'lib/app_state.dart'
text = app_state.read_text(encoding='utf-8')
if "import 'l10n/app_strings.dart';" not in text:
    text = text.replace(
        "import 'package:shared_preferences/shared_preferences.dart';\n",
        "import 'package:shared_preferences/shared_preferences.dart';\n\nimport 'l10n/app_strings.dart';\n",
        1,
    )
text = text.replace(
    "      languageCode = savedLanguage == 'en' ? 'en' : 'tr';",
    "      languageCode = savedLanguage == 'en' ? 'en' : 'tr';\n      AppStrings.setCurrentLanguage(languageCode);",
)
text = text.replace(
    "    languageCode = normalized;\n    notifyListeners();",
    "    languageCode = normalized;\n    AppStrings.setCurrentLanguage(languageCode);\n    notifyListeners();",
)
app_state.write_text(text, encoding='utf-8')

# Repair Falling Blocks ternaries where localized function calls broke adjacent string concatenation.
patch('lib/screens/falling_blocks_screen.dart', [
    (
        "AppStrings.current.f('Hedef $_targetScore puan  •  $_lines çizgi', 'Target $_targetScore score  •  $_lines lines')\n"
        "                        '${earned > 0 ? '  •  +$earned coin' : ''}'",
        "AppStrings.current.f("
        "'Hedef $_targetScore puan  •  $_lines çizgi${earned > 0 ? '  •  +$earned coin' : ''}', "
        "'Target $_targetScore score  •  $_lines lines${earned > 0 ? '  •  +$earned coin' : ''}')",
    ),
    (
        "AppStrings.current.f('$_lines çizgi  •  Seviye $_arcadeLevel\\n', '$_lines lines  •  Level $_arcadeLevel\\n')\n"
        "                        'En iyi: ${widget.appState.fallingBlocksBestScore}'",
        "AppStrings.current.f("
        "'$_lines çizgi  •  Seviye $_arcadeLevel\\nEn iyi: ${widget.appState.fallingBlocksBestScore}', "
        "'$_lines lines  •  Level $_arcadeLevel\\nBest: ${widget.appState.fallingBlocksBestScore}')",
    ),
])

# Only widget constructor const markers are removed where localization is dynamic.
for rel in ['lib/screens/game_screen.dart', 'lib/screens/falling_blocks_screen.dart']:
    p = ROOT / rel
    text = p.read_text(encoding='utf-8')
    text = text.replace('const Text(AppStrings.current.f(', 'Text(AppStrings.current.f(')
    text = text.replace('const SnackBar(content: Text(AppStrings.current.f(', 'SnackBar(content: Text(AppStrings.current.f(')
    p.write_text(text, encoding='utf-8')

print('v0.22.1 final localization patch applied')
