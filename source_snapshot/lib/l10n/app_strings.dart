class AppStrings {
  const AppStrings(this.languageCode);

  final String languageCode;

  bool get isEnglish => languageCode == 'en';

  String t(String key) {
    final pair = _values[key];
    if (pair == null) return key;
    return isEnglish ? pair.$2 : pair.$1;
  }

  static const Map<String, (String, String)> _values = <String, (String, String)>{
    'settings.title': ('AYARLAR', 'SETTINGS'),
    'settings.language': ('DİL', 'LANGUAGE'),
    'settings.language_subtitle': ('Uygulama dilini seç', 'Choose the app language'),
    'settings.turkish': ('Türkçe', 'Turkish'),
    'settings.english': ('İngilizce', 'English'),
    'settings.music': ('ARKA PLAN MÜZİĞİ', 'BACKGROUND MUSIC'),
    'settings.music_subtitle': ('Sakin ve melodik oyun müziği', 'Calm and melodic game music'),
    'settings.music_level': ('MÜZİK SEVİYESİ', 'MUSIC LEVEL'),
    'settings.sfx': ('SES EFEKTLERİ', 'SOUND EFFECTS'),
    'settings.sfx_subtitle': ('Temaya özel yerleştirme, kırılma ve combo sesleri', 'Theme-specific placement, break and combo sounds'),
    'settings.sfx_level': ('EFEKT SEVİYESİ', 'EFFECT LEVEL'),
    'settings.ui': ('ARAYÜZ SESLERİ', 'UI SOUNDS'),
    'settings.ui_subtitle': ('Menü ve buton dokunuş sesleri', 'Menu and button touch sounds'),
    'settings.ui_level': ('ARAYÜZ SES SEVİYESİ', 'UI SOUND LEVEL'),
    'settings.haptics': ('TİTREŞİM', 'HAPTICS'),
    'settings.haptics_subtitle': ('Yerleştirme ve temizleme titreşimleri', 'Placement and clear haptics'),
    'settings.performance': ('PERFORMANS MODU', 'PERFORMANCE MODE'),
    'settings.performance_subtitle': ('Efekt yükünü azaltarak daha akıcı çalışır', 'Reduces effect load for smoother performance'),
    'settings.tutorial': ('EĞİTİMİ TEKRAR GÖSTER', 'SHOW TUTORIAL AGAIN'),
    'settings.tutorial_subtitle': ('Bir sonraki oyunda eğitimi yeniden aç', 'Show the tutorial in the next game'),
    'settings.ready': ('HAZIR', 'READY'),
    'settings.preview': ('Sesi dene', 'Preview sound'),

    'home.play': ('OYNA', 'PLAY'),
    'home.modes': ('MODLAR', 'MODES'),
    'home.daily': ('GÜNLÜK ÖDÜL', 'DAILY REWARD'),
    'home.store': ('MAĞAZA', 'STORE'),
    'home.themes': ('TEMALAR', 'THEMES'),
    'home.missions': ('GÖREVLER', 'MISSIONS'),
    'home.achievements': ('BAŞARIMLAR', 'ACHIEVEMENTS'),
    'home.settings': ('AYARLAR', 'SETTINGS'),
    'home.best': ('EN YÜKSEK', 'BEST'),

    'modes.title': ('OYUN MODLARI', 'GAME MODES'),
    'modes.adventure': ('MACERA', 'ADVENTURE'),
    'modes.adventure_subtitle': ('60 bölüm • düşen blok macerası', '60 levels • falling-block adventure'),
    'modes.adventure_description': ('Her bölümde puan hedefi yükselir; hız, başlangıç zorluğu ve renk paleti değişir.', 'Every level raises the score target; speed, opening difficulty and colors change.'),
    'modes.falling': ('DÜŞEN BLOKLAR', 'FALLING BLOCKS'),
    'modes.completed': ('TAMAMLANAN', 'COMPLETED'),
    'modes.record': ('REKOR', 'BEST'),

    'themes.title': ('TEMALAR', 'THEMES'),
    'themes.subtitle': ('Coin ile aç, kalıcı olarak kullan', 'Unlock with coins and keep permanently'),
    'themes.preview': ('GERÇEK MATERYAL ÖNİZLEME', 'REAL MATERIAL PREVIEW'),
    'themes.unlocked': ('teması açıldı.', 'theme unlocked.'),
    'themes.no_coins': ('Yeterli coin yok.', 'Not enough coins.'),

    'adventure.title': ('MACERA', 'ADVENTURE'),
    'adventure.journey': ('60 BÖLÜMLÜK YOLCULUK', '60-LEVEL JOURNEY'),
    'adventure.description': ('Her bölümde hedef puan yükselir, düşüş hızlanır, başlangıç alanı zorlaşır ve renk paleti değişir.', 'Each level raises the target score, speeds up falling blocks, increases opening difficulty and changes the color palette.'),
    'adventure.level': ('BÖLÜM', 'LEVEL'),
    'adventure.score': ('PUAN', 'SCORE'),

    'falling.rotate': ('DÖNDÜR', 'ROTATE'),
    'falling.drop': ('HIZLI İNDİR', 'HARD DROP'),
    'falling.drag_hint': ('Sağa/sola sürükle • Aşağı kaydır', 'Swipe left/right • Swipe down'),
    'falling.paused': ('DURAKLATILDI', 'PAUSED'),
    'falling.score': ('SKOR', 'SCORE'),
    'falling.lines': ('ÇİZGİ', 'LINES'),
    'falling.difficulty': ('ZORLUK', 'DIFFICULTY'),
    'falling.speed': ('HIZ', 'SPEED'),
    'falling.target': ('Hedef', 'Target'),
    'falling.level_done': ('BÖLÜM TAMAMLANDI', 'LEVEL COMPLETE'),
    'falling.level_failed': ('BÖLÜM BAŞARISIZ', 'LEVEL FAILED'),
    'falling.levels': ('BÖLÜMLER', 'LEVELS'),
    'falling.modes': ('MODLAR', 'MODES'),
    'falling.next': ('SONRAKİ', 'NEXT'),
    'falling.retry': ('TEKRAR OYNA', 'PLAY AGAIN'),

    'game.undo': ('GERİ AL', 'UNDO'),
    'game.refresh': ('YENİLE', 'REFRESH'),
    'game.special': ('ÖZEL', 'SPECIAL'),
    'game.score': ('SKOR', 'SCORE'),
    'game.lines': ('ÇİZGİ', 'LINES'),
    'game.block': ('BLOK', 'BLOCK'),
    'game.pause': ('OYUN DURAKLATILDI', 'GAME PAUSED'),
    'game.resume': ('DEVAM ET', 'RESUME'),
    'game.restart': ('YENİDEN', 'RESTART'),
    'game.home': ('ANA MENÜ', 'MAIN MENU'),
    'game.help': ('HIZLI EĞİTİM', 'QUICK TUTORIAL'),
    'game.start': ('OYUNA BAŞLA', 'START GAME'),
    'game.game_over': ('OYUN BİTTİ', 'GAME OVER'),
    'game.new_record': ('YENİ REKOR!', 'NEW RECORD!'),
    'game.play_again': ('TEKRAR OYNA', 'PLAY AGAIN'),
  };
}
