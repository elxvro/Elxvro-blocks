#!/usr/bin/env python3
from pathlib import Path
import sys

ROOT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path('.')

def read(rel):
    return (ROOT / rel).read_text(encoding='utf-8')

def write(rel, text):
    (ROOT / rel).write_text(text, encoding='utf-8')

def replace_if(rel, old, new):
    text = read(rel)
    if old in text:
        write(rel, text.replace(old, new))
        return True
    return False

def replace_once(rel, old, new):
    text = read(rel)
    count = text.count(old)
    if count != 1:
        raise SystemExit(f'v0.22.1 anchor mismatch {rel}: expected 1 got {count}: {old[:120]!r}')
    write(rel, text.replace(old, new, 1))

def ensure_import(rel):
    text = read(rel)
    imp = "import '../l10n/app_strings.dart';\n"
    if imp in text:
        return
    anchor = "import '../app_state.dart';\n"
    if anchor not in text:
        raise SystemExit(f'missing app_state import in {rel}')
    write(rel, text.replace(anchor, anchor + imp, 1))

def deconst_dynamic(rel):
    text = read(rel)
    for old, new in [
        ('const Text(', 'Text('),
        ('const Expanded(', 'Expanded('),
        ('const Column(', 'Column('),
        ('const Row(', 'Row('),
        ('const _SectionTitle(', '_SectionTitle('),
        ('children: const <Widget>[', 'children: <Widget>['),
    ]:
        text = text.replace(old, new)
    write(rel, text)

# ---------------------------------------------------------------------------
# Complete English coverage for screens not fully localized in v0.22.0.
# ---------------------------------------------------------------------------

# Rewards
rel='lib/screens/rewards_screen.dart'
ensure_import(rel)
replace_if(rel, "      builder: (context, _) {\n        final selectedTheme", "      builder: (context, _) {\n        final l = AppStrings(appState.languageCode);\n        final selectedTheme")
deconst_dynamic(rel)
for tr,en in [
 ('GÜNLÜK ÖDÜL','DAILY REWARD'),
 ('Her gün gel, seriyi büyüt','Come back every day and grow your streak'),
 ('GÜNLÜK SERİ','DAY STREAK'),
 ("Bugünün ödülü hazır.","Today's reward is ready."),
 ("Bugünün ödülünü aldın. Yarın tekrar gel.","You claimed today's reward. Come back tomorrow."),
 ('BUGÜN ALINDI','CLAIMED TODAY'),
]:
    replace_if(rel, f"'{tr}'", f"l.f('{tr}', '{en}')")
replace_if(rel, "'$day. GÜN'", "l.f('$day. GÜN', 'DAY $day')")
replace_if(rel, "'+$amount coin hesabına eklendi.'", "l.f('+$amount coin hesabına eklendi.', '+$amount coins added to your account.')")

# Store
rel='lib/screens/store_screen.dart'
ensure_import(rel)
replace_if(rel, "      builder: (context, _) {\n        final selectedTheme", "      builder: (context, _) {\n        final l = AppStrings(appState.languageCode);\n        final selectedTheme")
deconst_dynamic(rel)
for tr,en in [
 ('MAĞAZA','STORE'), ('Coinlerini güçlere dönüştür','Turn your coins into power-ups'),
 ('Geri Al Paketi','Undo Pack'), ('3 ekstra geri al hakkı','3 extra undo uses'),
 ('Yenile Paketi','Refresh Pack'), ('3 ekstra blok yenileme hakkı','3 extra piece refreshes'),
 ('Özel Blok Paketi','Special Block Pack'), ('3 kez anında özel blok üret','Create a special block instantly 3 times'),
 ('Usta Paketi','Master Pack'), ('5 geri al + 5 yenile + 2 özel blok','5 undo + 5 refresh + 2 special blocks'),
 ('Coinler yalnızca oyun içi ilerleme ile kazanılır. Bu sürümde gerçek para ile satın alma yoktur.','Coins are earned only through gameplay. This version has no real-money purchases.'),
 ('GERİ AL','UNDO'), ('YENİLE','REFRESH'), ('ÖZEL','SPECIAL'), ('Satın alındı.','Purchased.'),
]:
    replace_if(rel, f"'{tr}'", f"l.f('{tr}', '{en}')")

# Daily missions
rel='lib/screens/daily_missions_screen.dart'
ensure_import(rel)
replace_if(rel, "      builder: (context, _) {\n        final selectedTheme", "      builder: (context, _) {\n        final l = AppStrings(appState.languageCode);\n        final selectedTheme")
deconst_dynamic(rel)
for tr,en in [
 ("Bugünün Oyunu","Today's Game"), ('1 oyun tamamla','Complete 1 game'),
 ('Temizlik Serisi','Clear Streak'), ('8 satır veya sütun temizle','Clear 8 rows or columns'),
 ('Skor Avcısı','Score Hunter'), ('Tek oyunda 2.500 puan yap','Score 2,500 points in one game'),
 ('GÜNLÜK GÖREVLER','DAILY MISSIONS'), ('Tamamla, coin ödülünü al','Complete missions and claim coin rewards'),
 ('DEVAM','GO'),
]:
    replace_if(rel, f"'{tr}'", f"l.f('{tr}', '{en}')")
replace_if(rel, "'+${mission.reward} coin kazandın.'", "l.f('+${mission.reward} coin kazandın.', '+${mission.reward} coins earned.')")

# Achievements: localize displayed item text by id.
rel='lib/screens/achievements_screen.dart'
ensure_import(rel)
replace_if(rel, "      builder: (context, _) {\n        final selectedTheme", "      builder: (context, _) {\n        final l = AppStrings(appState.languageCode);\n        final selectedTheme")
deconst_dynamic(rel)
replace_if(rel, "'BAŞARIMLAR'", "l.f('BAŞARIMLAR', 'ACHIEVEMENTS')")
replace_if(rel, "'${appState.unlockedAchievements}/${_items.length} açıldı'", "l.f('${appState.unlockedAchievements}/${_items.length} açıldı', '${appState.unlockedAchievements}/${_items.length} unlocked')")
replace_if(rel, "                          accent: selectedTheme.blockAccent,\n", "                          accent: selectedTheme.blockAccent,\n                          languageCode: appState.languageCode,\n")
replace_if(rel, "'+${item.reward} coin kazandın.'", "l.f('+${item.reward} coin kazandın.', '+${item.reward} coins earned.')")
replace_if(rel, "    required this.accent,\n    required this.onClaim,", "    required this.accent,\n    required this.languageCode,\n    required this.onClaim,")
replace_if(rel, "  final Color accent;\n  final VoidCallback onClaim;", "  final Color accent;\n  final String languageCode;\n  final VoidCallback onClaim;")
replace_if(rel, "  Widget build(BuildContext context) {\n    return Container(", "  Widget build(BuildContext context) {\n    final l = AppStrings(languageCode);\n    return Container(")
replace_if(rel, "                  item.title,", "                  _achievementTitle(item.id, item.title, l),")
replace_if(rel, "                  item.subtitle,", "                  _achievementSubtitle(item.id, item.subtitle, l),")
text=read(rel)
if '_achievementTitle(item.id' not in text:
    raise SystemExit('achievement display patch missing')
if 'String _achievementTitle' not in text:
    text += """
String _achievementTitle(String id, String fallback, AppStrings l) {
  if (!l.isEnglish) return fallback;
  return switch (id) {
    'first_game' => 'First Step',
    'score_1000' => 'Warm-Up',
    'combo_3' => 'Combo Master',
    'lines_25' => 'Board Cleaner',
    'games_10' => 'Experienced',
    'blocks_250' => 'Block Collector',
    'score_10000' => 'Legend',
    'level_5' => 'Rising Star',
    'perfect_3' => 'Flawless',
    'level_15' => 'ELXVRO Master',
    _ => fallback,
  };
}

String _achievementSubtitle(String id, String fallback, AppStrings l) {
  if (!l.isEnglish) return fallback;
  return switch (id) {
    'first_game' => 'Complete your first game',
    'score_1000' => 'Reach 1,000 points in one game',
    'combo_3' => 'Reach a x3 combo',
    'lines_25' => 'Clear 25 rows or columns in total',
    'games_10' => 'Complete 10 games',
    'blocks_250' => 'Place 250 pieces',
    'score_10000' => 'Reach 10,000 points in one game',
    'level_5' => 'Reach level 5',
    'perfect_3' => 'Complete 3 Perfect Clears',
    'level_15' => 'Reach level 15',
    _ => fallback,
  };
}
"""
    write(rel,text)

# Stats
rel='lib/screens/stats_screen.dart'
ensure_import(rel)
replace_if(rel, "  Widget build(BuildContext context) {\n    final selectedTheme", "  Widget build(BuildContext context) {\n    final l = AppStrings(appState.languageCode);\n    final selectedTheme")
deconst_dynamic(rel)
for tr,en in [
 ('Oyuncu Seviyesi','Player Level'), ('Toplam XP','Total XP'), ('En Yüksek Skor','Best Score'),
 ('Oynanan Oyun','Games Played'), ('Maksimum Combo','Max Combo'), ('Toplam Puan','Total Score'),
 ('Temizlenen Çizgi','Lines Cleared'), ('Yerleştirilen Parça','Pieces Placed'),
 ('2 Dakika Rekoru','2-Minute Best'), ('Hedef 5000 Rekoru','Target 5000 Best'),
 ('Günlük Rekor','Daily Best'), ('Zen Rekoru','Zen Best'), ('Zor Mod Rekoru','Hard Mode Best'),
 ('İSTATİSTİKLER','STATISTICS'),
]:
    replace_if(rel, f"'{tr}'", f"l.f('{tr}', '{en}')")

# Social hub
rel='lib/screens/social_hub_screen.dart'
ensure_import(rel)
replace_if(rel, "  Widget build(BuildContext context) {\n    final selectedTheme", "  Widget build(BuildContext context) {\n    final l = AppStrings(appState.languageCode);\n    final selectedTheme")
replace_if(rel, "            builder: (context, _) {\n              return Column(", "            builder: (context, _) {\n              return Column(")
deconst_dynamic(rel)
for tr,en in [
 ('LİDERLİK MERKEZİ','LEADERBOARD HUB'), ('KİŞİSEL REKORLAR','PERSONAL BESTS'), ('BU HAFTA','THIS WEEK'),
 ('Play Console yapılandırıldığında bu ekran global sıralama ve başarımları aynı kayıt mimarisi üzerinden gösterecek. Şimdilik hiçbir çevrimiçi sıralama taklit edilmez.','When Play Console is configured, this screen will show global leaderboards and achievements through the same data model. No online ranking is simulated for now.'),
]:
    replace_if(rel, f"'{tr}'", f"l.f('{tr}', '{en}')")
# pass language to sub-widgets
replace_if(rel, "_PlayerCard(appState: appState)", "_PlayerCard(appState: appState, languageCode: appState.languageCode)")
replace_if(rel, "_RecordGrid(appState: appState)", "_RecordGrid(appState: appState, languageCode: appState.languageCode)")
replace_if(rel, "_WeeklyCard(appState: appState)", "_WeeklyCard(appState: appState, languageCode: appState.languageCode)")
replace_if(rel, "_ConnectionCard(service: socialService)", "_ConnectionCard(service: socialService, languageCode: appState.languageCode)")

# Social subwidgets get local language through constructor using tolerant structural replacements.
for cls in ['_PlayerCard','_RecordGrid','_WeeklyCard','_ConnectionCard']:
    text=read(rel)
    marker=f'class {cls} '
    if marker not in text:
        continue
# targeted constructor/field patches
replace_if(rel, "const _PlayerCard({required this.appState});", "const _PlayerCard({required this.appState, required this.languageCode});")
replace_if(rel, "final AppState appState;\n\n  @override\n  Widget build(BuildContext context) {", "final AppState appState;\n  final String languageCode;\n\n  @override\n  Widget build(BuildContext context) {\n    final l = AppStrings(languageCode);",)
# Remaining widgets are patched through direct inline language checks at their constructors if anchors exist.
replace_if(rel, "const _RecordGrid({required this.appState});", "const _RecordGrid({required this.appState, required this.languageCode});")
replace_if(rel, "const _WeeklyCard({required this.appState});", "const _WeeklyCard({required this.appState, required this.languageCode});")
replace_if(rel, "const _ConnectionCard({required this.service});", "const _ConnectionCard({required this.service, required this.languageCode});")
# broad field insertions for repeated AppState subwidgets
text=read(rel)
text=text.replace("class _RecordGrid extends StatelessWidget {\n  const _RecordGrid({required this.appState, required this.languageCode});\n\n  final AppState appState;",
"""class _RecordGrid extends StatelessWidget {
  const _RecordGrid({required this.appState, required this.languageCode});

  final AppState appState;
  final String languageCode;""")
text=text.replace("class _WeeklyCard extends StatelessWidget {\n  const _WeeklyCard({required this.appState, required this.languageCode});\n\n  final AppState appState;",
"""class _WeeklyCard extends StatelessWidget {
  const _WeeklyCard({required this.appState, required this.languageCode});

  final AppState appState;
  final String languageCode;""")
text=text.replace("class _ConnectionCard extends StatelessWidget {\n  const _ConnectionCard({required this.service, required this.languageCode});\n\n  final SocialService service;",
"""class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({required this.service, required this.languageCode});

  final SocialService service;
  final String languageCode;""")
# Add local l inside builds for these classes where unique class sections exist.
for cls,nextcls in [('_RecordGrid','_RecordCard'),('_WeeklyCard','_ProgressRow'),('_ConnectionCard','_ConnectionStatus')]:
    start=text.find(f'class {cls} ')
    if start>=0:
        end=text.find(f'class {nextcls} ', start)
        if end<0: end=len(text)
        section=text[start:end]
        needle="  Widget build(BuildContext context) {"
        if needle in section and "final l = AppStrings(languageCode);" not in section:
            section=section.replace(needle, needle+"\n    final l = AppStrings(languageCode);",1)
            text=text[:start]+section+text[end:]
write(rel,text)
for tr,en in [
 ('KLASİK','CLASSIC'), ('2 DAKİKA','2 MINUTES'), ('HEDEF','TARGET'), ('GÜNLÜK','DAILY'), ('ZOR','HARD'),
 ('HAFTALIK HEDEF','WEEKLY TARGET'), ('OYUN','GAMES'), ('EN İYİ','BEST'), ('ÖDÜL','REWARD'),
 ('+250 coin haftalık ödül alındı.','+250 coin weekly reward claimed.'),
 ('HEDEFİ TAMAMLA','COMPLETE TARGET'), ('BAĞLI','CONNECTED'), ('ÇEVRİMDIŞI','OFFLINE'),
 ('Bağlantı durumu kontrol ediliyor...','Checking connection status...'), ('PLAY CONSOLE SONRASI AKTİF','ACTIVE AFTER PLAY CONSOLE'),
]:
    replace_if(rel, f"'{tr}'", f"l.f('{tr}', '{en}')")

# Profile
rel='lib/screens/profile_screen.dart'
ensure_import(rel)
# Dialog uses direct AppStrings because outside build
replace_if(rel, "  Future<void> _editName(BuildContext context) async {\n    final controller", "  Future<void> _editName(BuildContext context) async {\n    final l = AppStrings(appState.languageCode);\n    final controller")
deconst_dynamic(rel)
for tr,en in [('OYUNCU ADI','PLAYER NAME'),('İPTAL','CANCEL'),('KAYDET','SAVE')]:
    replace_if(rel, f"'{tr}'", f"l.f('{tr}', '{en}')")
replace_if(rel, "  Widget build(BuildContext context) {\n    final selectedTheme", "  Widget build(BuildContext context) {\n    final l = AppStrings(appState.languageCode);\n    final selectedTheme")
for tr,en in [
 ('PROFİL','PROFILE'), ('Oyuncu adını değiştir','Change player name'), ('EN İYİ','BEST'),
 ('SEVİYE ÖDÜLLERİ','LEVEL REWARDS'),
 ('Her 5 seviyede coin + 2 özel blok kazanırsın. Seviye 5, 10, 15, 20 ve 25 ilerlemelerinde premium temalar da otomatik açılır.','Every 5 levels you earn coins + 2 special blocks. Premium themes also unlock automatically at levels 5, 10, 15, 20 and 25.'),
 ('ATEŞ TEMASI','FIRE THEME'), ('DOĞA TEMASI','NATURE THEME'), ('PREMIUM ÖDÜL','PREMIUM REWARD'),
]:
    replace_if(rel, f"'{tr}'", f"l.f('{tr}', '{en}')")
replace_if(rel, "'SEVİYE ${appState.playerLevel}'", "l.f('SEVİYE ${appState.playerLevel}', 'LEVEL ${appState.playerLevel}')")
replace_if(rel, "'SEVİYE $level ÖDÜLÜ'", "l.f('SEVİYE $level ÖDÜLÜ', 'LEVEL $level REWARD')")
replace_if(rel, "'+$coinReward coin  •  +2 özel blok  •  $themeName'", "l.f('+$coinReward coin  •  +2 özel blok  •  $themeName', '+$coinReward coins  •  +2 special blocks  •  $themeName')")

# ---------------------------------------------------------------------------
# Main screens: finish English translation after v0.22 patch.
# ---------------------------------------------------------------------------

# Home remaining badges/sections.
rel='lib/screens/home_screen.dart'
replace_if(rel, "badge: 'YENİ'", "badge: l.f('YENİ', 'NEW')")
replace_if(rel, "badge: appState.dailyRewardAvailable ? 'HAZIR' : '${appState.loginStreak}. GÜN'", "badge: appState.dailyRewardAvailable ? l.f('HAZIR', 'READY') : l.f('${appState.loginStreak}. GÜN', 'DAY ${appState.loginStreak}')")
replace_if(rel, "label: 'İSTATİSTİK'", "label: l.f('İSTATİSTİK', 'STATISTICS')")
replace_if(rel, "label: 'LİDERLİK MERKEZİ'", "label: l.f('LİDERLİK MERKEZİ', 'LEADERBOARD HUB')")
replace_if(rel, "badge: appState.weeklyRewardAvailable ? 'ÖDÜL HAZIR' : 'HAFTALIK'", "badge: appState.weeklyRewardAvailable ? l.f('ÖDÜL HAZIR', 'REWARD READY') : l.f('HAFTALIK', 'WEEKLY')")
replace_if(rel, "label: 'PROFİL & SEVİYE'", "label: l.f('PROFİL & SEVİYE', 'PROFILE & LEVEL')")
replace_if(rel, "'SEVİYE ${appState.playerLevel}'", "l.f('SEVİYE ${appState.playerLevel}', 'LEVEL ${appState.playerLevel}')")

# Modes: descriptions/subtitles from model.
rel='lib/screens/modes_screen.dart'
replace_if(rel, "                      subtitle: data.subtitle,", "                      subtitle: _localizedModeSubtitle(mode, data.subtitle, l),")
replace_if(rel, "                      description: data.description,", "                      description: _localizedModeDescription(mode, data.description, l),")
text=read(rel)
if 'String _localizedModeSubtitle' not in text:
    marker='class _ModeCard extends StatelessWidget {'
    add="""String _localizedModeSubtitle(GameMode mode, String fallback, AppStrings l) {
  if (!l.isEnglish) return fallback;
  return switch (mode) {
    GameMode.classic => 'No timer • build your best score',
    GameMode.timed => '2 minutes • score fast',
    GameMode.comboRush => 'Keep the combo alive',
    GameMode.target => 'Reach the target score',
    GameMode.daily => 'One challenge every day',
    GameMode.zen => 'Relaxed session',
    GameMode.hard => 'Tough pieces • higher pressure',
  };
}

String _localizedModeDescription(GameMode mode, String fallback, AppStrings l) {
  if (!l.isEnglish) return fallback;
  return switch (mode) {
    GameMode.classic => 'Place blocks, clear rows and columns, and chase your personal best.',
    GameMode.timed => 'Score as much as possible before the timer reaches zero.',
    GameMode.comboRush => 'Clear repeatedly to grow your combo and multiply the action.',
    GameMode.target => 'Reach the score target before you run out of moves.',
    GameMode.daily => 'Play today\'s seeded challenge and earn the daily reward.',
    GameMode.zen => 'Play without pressure and keep the board flowing.',
    GameMode.hard => 'Harder pieces and a tighter starting board test your planning.',
  };
}

"""
    text=text.replace(marker,add+marker,1)
    write(rel,text)
replace_if(rel, "'Macera, Combo Rush, günlük challenge, Klasik, Zen ve Zor mod ile farklı hedeflerde ilerle.'", "l.f('Macera, Combo Rush, günlük challenge, Klasik, Zen ve Zor mod ile farklı hedeflerde ilerle.', 'Choose Adventure, Combo Rush, Daily Challenge, Classic, Zen or Hard mode.')")
replace_if(rel, "'Arcade • düşür • döndür • çizgi temizle'", "l.f('Arcade • düşür • döndür • çizgi temizle', 'Arcade • drop • rotate • clear lines')")
replace_if(rel, "'Klasik düşen blok mantığında ayrı 10×20 bölüm. Hız giderek artar.'", "l.f('Klasik düşen blok mantığında ayrı 10×20 bölüm. Hız giderek artar.', 'A dedicated 10×20 falling-block mode where speed increases over time.')")

# Themes: names, subtitles, preview/snackbar.
rel='lib/screens/themes_screen.dart'
replace_if(rel, "                  theme.name.toUpperCase(),", "                  _localizedThemeName(theme, l).toUpperCase(),")
replace_if(rel, "                  theme.subtitle,", "                  _localizedThemeSubtitle(theme, l),")
replace_if(rel, "                      theme.name,", "                      _localizedThemeName(theme, l),")
# _ThemeCard needs languageCode
replace_if(rel, "                          onTap: () async {", "                          languageCode: appState.languageCode,\n                          onTap: () async {")
replace_if(rel, "    required this.onTap,\n  });", "    required this.languageCode,\n    required this.onTap,\n  });")
replace_if(rel, "  final VoidCallback onTap;", "  final String languageCode;\n  final VoidCallback onTap;")
replace_if(rel, "  Widget build(BuildContext context) {\n    return Material(", "  Widget build(BuildContext context) {\n    final l = AppStrings(languageCode);\n    return Material(")
replace_if(rel, "                      theme.name,", "                      _localizedThemeName(theme, l),")
replace_if(rel, "                      theme.subtitle,", "                      _localizedThemeSubtitle(theme, l),")
replace_if(rel, "                                      ? '${theme.name} teması açıldı.'\n                                      : 'Yeterli coin yok.',", "                                      ? '${_localizedThemeName(theme, l)} ${l.t('themes.unlocked')}'\n                                      : l.t('themes.no_coins'),")
text=read(rel)
if 'String _localizedThemeName' not in text:
    text += """
String _localizedThemeName(GameThemeData theme, AppStrings l) {
  if (!l.isEnglish) return theme.name;
  return switch (theme.id) {
    'classic' => 'Glass',
    'night' => 'Branch',
    'marble' => 'Stone',
    'fire' => 'Leaf',
    'nature' => 'Crystal',
    'aurora' => 'Golden Marble',
    _ => theme.name,
  };
}

String _localizedThemeSubtitle(GameThemeData theme, AppStrings l) {
  if (!l.isEnglish) return theme.subtitle;
  return switch (theme.id) {
    'classic' => 'Glossy frosted glass • crystal tone',
    'night' => 'Warm wood • natural branch texture',
    'marble' => 'Carved rock • heavy and powerful',
    'fire' => 'Living green • soft natural feel',
    'nature' => 'Purple-blue refraction • bright surface',
    'aurora' => 'Black marble • warm golden veins',
    _ => theme.subtitle,
  };
}
"""
    write(rel,text)

# Adventure difficulty.
rel='lib/screens/adventure_screen.dart'
replace_if(rel, "'${l.t('adventure.level')} ${level.chapter} • ${level.difficultyLabel}'", "'${l.t('adventure.level')} ${level.chapter} • ${_difficultyLabel(level, l)}'")
text=read(rel)
if 'String _difficultyLabel' not in text:
    text += """
String _difficultyLabel(AdventureLevel level, AppStrings l) {
  if (!l.isEnglish) return level.difficultyLabel;
  if (level.hardPieces) return 'HARD';
  if (level.durationSeconds != null) return 'SPEED';
  return 'CLASSIC';
}
"""
    write(rel,text)

# Falling Blocks remaining dynamic Turkish.
rel='lib/screens/falling_blocks_screen.dart'
replace_if(rel, "'MACERA • BÖLÜM ${widget.adventureLevel!.number}'", "l.f('MACERA • BÖLÜM ${widget.adventureLevel!.number}', 'ADVENTURE • LEVEL ${widget.adventureLevel!.number}')")
replace_if(rel, "'Hedef $_targetScore puan  •  $_lines çizgi'", "l.f('Hedef $_targetScore puan  •  $_lines çizgi', 'Target $_targetScore score  •  $_lines lines')")
replace_if(rel, "'$_lines çizgi  •  Seviye $_arcadeLevel\\n'", "l.f('$_lines çizgi  •  Seviye $_arcadeLevel\\n', '$_lines lines  •  Level $_arcadeLevel\\n')")
replace_if(rel, "'En iyi: ${widget.appState.fallingBlocksBestScore}'", "l.f('En iyi: ${widget.appState.fallingBlocksBestScore}', 'Best: ${widget.appState.fallingBlocksBestScore}')")

# Game screen: full user-facing English by direct language-aware phrases.
rel='lib/screens/game_screen.dart'
# static strings used across methods
pairs=[
 ('SÜRE DOLDU','TIME UP'), ('OYUNA DEVAM EDİLDİ','GAME RESUMED'), ('TEMİZLEME','CLEAR'),
 ('HEDEF TAMAMLANDI','TARGET COMPLETE'), ('KRİTİK HAMLE • GÜÇ KULLAN','CRITICAL MOVE • USE A POWER-UP'),
 ('HAMLE KALMADI','NO MOVES LEFT'), ('ZEN NEFESİ • TAHTA RAHATLADI','ZEN BREATH • BOARD RELIEVED'),
 ('YENİ REKOR!','NEW RECORD!'), ('OYUN BİTTİ','GAME OVER'), ('BÖLÜM TAMAMLANDI','LEVEL COMPLETE'),
 ('BÖLÜM BAŞARISIZ','LEVEL FAILED'), ('CHALLENGE BİTTİ','CHALLENGE OVER'), ('ZOR MOD BİTTİ','HARD MODE OVER'),
 ('ZEN OTURUMU','ZEN SESSION'), ('YENİ KİŞİSEL REKOR','NEW PERSONAL BEST'), ('ÇİZGİ','LINES'), ('BLOK','BLOCK'),
 ('Nasıl oynanır?','How to play?'), ('GERİ AL','UNDO'), ('YENİLE','REFRESH'), ('ÖZEL','SPECIAL'),
]
for tr,en in pairs:
    replace_if(rel, f"'{tr}'", f"AppStrings(widget.appState.languageCode).f('{tr}', '{en}')")
# tutorial and pause dynamic text
for tr,en in [
 ('HIZLI EĞİTİM','QUICK TUTORIAL'), ('SÜRÜKLE & BIRAK','DRAG & DROP'),
 ('Alttaki blokları tahtadaki hayalet konuma bırak.','Drag the blocks below onto the ghost position on the board.'),
 ('ÇİZGİLERİ TEMİZLE','CLEAR LINES'),
 ('Dolu satır ve sütunlar temizlenir; seri yaparsan combo büyür.','Full rows and columns clear; consecutive clears grow your combo.'),
 ('Tahtayı tamamen boşaltırsan +1000 skor ve bonus coin kazanırsın.','Clear the entire board to earn +1000 score and bonus coins.'),
 ('GÜÇLER','POWER-UPS'), ('Geri Al, Yenile ve Özel blok haklarını kritik anda kullan.','Use Undo, Refresh and Special Block charges at critical moments.'),
 ('OYUNA BAŞLA','START GAME'), ('Ses efektleri','Sound effects'), ('Müzik','Music'), ('Titreşim','Haptics'),
]:
    replace_if(rel, f"'{tr}'", f"AppStrings(widget.appState.languageCode).f('{tr}', '{en}')")
# Remove const where dynamic AppStrings got inserted
deconst_dynamic(rel)
# Dynamic labels/statuses
replace_if(rel, "'Bölüm ${adventure.chapter} • ${adventure.difficultyLabel}'", "AppStrings(widget.appState.languageCode).f('Bölüm ${adventure.chapter} • ${adventure.difficultyLabel}', 'Level ${adventure.chapter} • ${adventure.hardPieces ? 'HARD' : adventure.durationSeconds != null ? 'SPEED' : 'CLASSIC'}')")
replace_if(rel, "'BÖLÜM TAMAM'", "AppStrings(widget.appState.languageCode).f('BÖLÜM TAMAM', 'LEVEL COMPLETE')")
replace_if(rel, "'İLK REKORUNU YAZ'", "AppStrings(widget.appState.languageCode).f('İLK REKORUNU YAZ', 'SET YOUR FIRST RECORD')")
replace_if(rel, "'YENİ REKOR'", "AppStrings(widget.appState.languageCode).f('YENİ REKOR', 'NEW RECORD')")
replace_if(rel, "'${_formatTime(_secondsLeft)}  •  HEDEF $target'", "AppStrings(widget.appState.languageCode).f('${_formatTime(_secondsLeft)}  •  HEDEF $target', '${_formatTime(_secondsLeft)}  •  TARGET $target')")
replace_if(rel, "'HEDEF $target'", "AppStrings(widget.appState.languageCode).f('HEDEF $target', 'TARGET $target')")
replace_if(rel, "'ZORLUK x1.35'", "AppStrings(widget.appState.languageCode).f('ZORLUK x1.35', 'DIFFICULTY x1.35')")
replace_if(rel, "'YENİ REKOR  •  ${_score}'", "AppStrings(widget.appState.languageCode).f('YENİ REKOR  •  ${_score}', 'NEW RECORD  •  ${_score}')")
replace_if(rel, "'BÖLÜM HEDEFİ  ${adventure.targetScore}'", "AppStrings(widget.appState.languageCode).f('BÖLÜM HEDEFİ  ${adventure.targetScore}', 'LEVEL TARGET  ${adventure.targetScore}')")
replace_if(rel, "'MOD REKORU  ${max(_modeBest, _score)}'", "AppStrings(widget.appState.languageCode).f('MOD REKORU  ${max(_modeBest, _score)}', 'MODE BEST  ${max(_modeBest, _score)}')")
replace_if(rel, "'SEVİYE ${progression.levelAfter}'", "AppStrings(widget.appState.languageCode).f('SEVİYE ${progression.levelAfter}', 'LEVEL ${progression.levelAfter}')")
replace_if(rel, "'+${progression.milestoneSpecials} ÖZEL'", "AppStrings(widget.appState.languageCode).f('+${progression.milestoneSpecials} ÖZEL', '+${progression.milestoneSpecials} SPECIAL')")
replace_if(rel, "'+$modeReward COIN KAZANDIN'", "AppStrings(widget.appState.languageCode).f('+$modeReward COIN KAZANDIN', '+$modeReward COINS EARNED')")
replace_if(rel, "'TAHTA DOLUYOR • ALAN AÇ'", "AppStrings(widget.appState.languageCode).f('TAHTA DOLUYOR • ALAN AÇ', 'BOARD FILLING • MAKE SPACE')")
replace_if(rel, "'MEGA SERİ x$combo'", "AppStrings(widget.appState.languageCode).f('MEGA SERİ x$combo', 'MEGA STREAK x$combo')")
replace_if(rel, "'SERİ x$combo'", "AppStrings(widget.appState.languageCode).f('SERİ x$combo', 'STREAK x$combo')")
# how-to-play numbered lines
for tr,en in [
 ('1. Bloğu sürükle; hayalet alan nereye oturacağını gösterir.','1. Drag a block; the ghost area shows where it will land.'),
 ('2. Dolu satır veya sütunları temizleyerek combo yap.','2. Clear full rows or columns to build combos.'),
 ('3. Özel bloklar yalnızca ÖZEL hakkını kullandığında devreye girer.','3. Special blocks appear only when you use a SPECIAL charge.'),
 ('4. Her oyunda 1 ücretsiz Geri Al ve 1 Yenile hakkın var.','4. Every game gives you 1 free Undo and 1 free Refresh.'),
 ('5. Mağazadan ekstra hak ve Özel Blok gücü alabilirsin.','5. Buy extra charges and Special Block power from the Store.'),
 ('6. Mod hedefini tamamla veya mümkün olan en iyi skoru yap.','6. Complete the mode objective or chase your best possible score.'),
]:
    replace_if(rel, f"'{tr}'", f"AppStrings(widget.appState.languageCode).f('{tr}', '{en}')")

# Settings remaining status/snackbar.
rel='lib/screens/settings_screen.dart'
replace_if(rel, "'Eğitim bir sonraki oyunda gösterilecek.'", "l.f('Eğitim bir sonraki oyunda gösterilecek.', 'The tutorial will be shown in the next game.')")
replace_if(rel, "'Altyapı hazır • Play Console bağlantısı sonraki sürümde açılabilir'", "l.f('Altyapı hazır • Play Console bağlantısı sonraki sürümde açılabilir', 'Infrastructure ready • Play Console connection can be enabled later')")
replace_if(rel, "'HAZIRLIK'", "l.f('HAZIRLIK', 'PREPARING')")
replace_if(rel, "tooltip: 'Sesi dene'", "tooltip: l.t('settings.preview')")

print('ELXVRO Blocks v0.22.1 full-English and no-canvas gameplay patch applied.')
