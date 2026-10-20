"""v0.37.2: restore the verified v0.36.2 screen architecture on v0.37.1.

Changes ONLY the presentation root and matching obsolete regression fixtures.
Game logic, world progress, coin wallet, icon, audio and Android channels stay untouched.
"""
from pathlib import Path
import shutil
import sys

root = Path(sys.argv[1]).resolve() if len(sys.argv)>1 else Path('.').resolve()

main_file = root/'lib/main.dart'
main = main_file.read_text()
old_import = "import 'screens/premium_navigation_shell.dart';"
old_home = 'home: PremiumNavigationShell(appState: widget.appState),'
assert main.count(old_import) == 1, 'Unexpected root import: refusing partial downgrade'
assert main.count(old_home) == 1, 'Unexpected root route: refusing partial downgrade'
main = main.replace(old_import, "import 'screens/launch_screen.dart';")
main = main.replace(old_home, 'home: LaunchScreen(appState: widget.appState),')
main_file.write_text(main)

pubspec = root/'pubspec.yaml'
spec = pubspec.read_text()
assert spec.count('version: 0.37.1+99') == 1, 'Unexpected version'
spec = spec.replace('version: 0.37.1+99', 'version: 0.37.2+100')
assert '    - assets/images/premium_navigation/\n' in spec
spec = spec.replace('    - assets/images/premium_navigation/\n', '')
pubspec.write_text(spec)

shell = root/'lib/screens/premium_navigation_shell.dart'
assert shell.exists(), 'Expected replaced dashboard screen'
shell.unlink()
shutil.rmtree(root/'assets/images/premium_navigation')

for name in ('v0370_reference_navigation_test.dart','v0371_compact_menu_audit_test.dart'):
    p = root/'test'/name
    assert p.is_file(), f'Missing previous UI-specific test {name}'
    p.unlink()

for p in (root/'test').glob('*.dart'):
    old = p.read_text()
    new = old.replace('version: 0.37.1+99', 'version: 0.37.2+100')
    if old != new:
        p.write_text(new)

# The integration widget test must verify actual launch / gameplay navigation,
# not the retired four-tab dashboard.
widget = root/'test/widget_test.dart'
widget.write_text('''import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:elxvro_blocks/app_state.dart';
import 'package:elxvro_blocks/main.dart';
import 'package:elxvro_blocks/screens/launch_screen.dart';
import 'package:elxvro_blocks/screens/home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('v0.37.2 restores the classic introduction and home menu', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final state = AppState();
    await state.load();
    await tester.pumpWidget(ElxvroBlocksApp(appState: state));
    expect(find.byType(LaunchScreen), findsOneWidget);
    expect(find.text('ELXVRO BLOCKS'), findsOneWidget);
    expect(find.text('MACERA DÜNYALARININ SIRASI'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('premium_nav_0')), findsNothing);
    await tester.ensureVisible(find.byKey(const ValueKey<String>('intro_play')));
    await tester.tap(find.byKey(const ValueKey<String>('intro_play')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('ELXVRO'), findsOneWidget);
    expect(find.text('OYNA'), findsOneWidget);
    expect(find.text('MODLAR'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
''')

(root/'test/v0372_classic_theme_restoration_test.dart').write_text('''import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:elxvro_blocks/app_state.dart';
import 'package:elxvro_blocks/screens/launch_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('classic-theme rollback preserves world assets and native-save channels', () {
    final root = Directory.current;
    final main = File('${root.path}/lib/main.dart').readAsStringSync();
    final pubspec = File('${root.path}/pubspec.yaml').readAsStringSync();
    expect(main, contains('home: LaunchScreen(appState: widget.appState)'));
    expect(main, isNot(contains('PremiumNavigationShell')));
    expect(pubspec, contains('version: 0.37.2+100'));
    expect(File('${root.path}/lib/screens/animal_adventure_screen.dart').existsSync(), isTrue);
    expect(File('${root.path}/lib/services/world_match_progress.dart').existsSync(), isTrue);
    expect(File('${root.path}/tool/install_animal_save_channel.py').existsSync(), isTrue);
    expect(File('${root.path}/tool/install_world_save_channel.py').existsSync(), isTrue);
    expect(File('${root.path}/assets/images/app_icon.png').existsSync(), isTrue);
    expect(Directory('${root.path}/assets/images/premium_navigation').existsSync(), isFalse);
  });
  testWidgets('classic launch renders on compact devices without retired nav', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final app = AppState();
    await app.load();
    await tester.pumpWidget(MaterialApp(home: LaunchScreen(appState: app)));
    expect(find.byKey(const ValueKey<String>('intro_scroll')), findsOneWidget);
    expect(find.text('ELXVRO BLOCKS'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('premium_journey')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
''')
(root/'V0372_RELEASE_NOTES.md').write_text('''# ELXVRO Blocks v0.37.2 — Klasik Tema Geri Dönüşü

- v0.36.2 koyu lacivert, turkuaz ve altın ELXVRO açılış/ana menü düzeni geri getirildi.
- v0.37.0–v0.37.1 fantastik görsel şeritli dört sekmeli menü kapatıldı.
- Eski açılış açıklaması, asıl OYNA düğmesi, MODLAR, ödüller, mağaza ve ayarlar yeniden kullanılıyor.
- 300 bölümlü beş dünya, sıra kilitleri, kayıt sistemi, coin ve güçlendiriciler korundu.
- Uygulama ikonu aynı kaldı; sürüm kodu 100, mevcut APK üzerinde yükseltilebilir.
- Eski tema testleri, dar ekran testi ve kayıt dosyası koruma kontrolleri eklendi.
- Oyuncunun kayıtlı verileri silinmez; uygulamayı kaldırmadan güncelleyin.
''')

assert (root/'lib/screens/launch_screen.dart').is_file()
assert (root/'lib/screens/home_screen.dart').is_file()
assert (root/'lib/screens/settings_screen.dart').is_file()
assert (root/'lib/screens/animal_adventure_screen.dart').is_file()
print('v0.37.2 classic theme restored. Original saves/gameplay untouched.')