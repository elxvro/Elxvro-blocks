import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:elxvro_blocks/app_state.dart';
import 'package:elxvro_blocks/screens/modes_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('Adventure mode, battle source and art are removed from shipping project', () {
    final modes = File('lib/screens/modes_screen.dart').readAsStringSync();
    final arcade = File('lib/screens/falling_blocks_screen.dart').readAsStringSync();
    final assets = File('pubspec.yaml').readAsStringSync();
    expect(modes, isNot(contains('AdventureScreen')));
    expect(modes, isNot(contains("modes.adventure")));
    expect(modes, contains('GameMode.values.length + 2'));
    expect(arcade, isNot(contains('_isAdventure')));
    expect(arcade, isNot(contains('AdventureResultDialog')));
    expect(arcade, contains('recordFallingBlocksScore(_score)'));
    expect(File('lib/screens/adventure_screen.dart').existsSync(), isFalse);
    expect(File('lib/screens/adventure_combat_screen.dart').existsSync(), isFalse);
    expect(Directory('assets/images/adventure_battles').existsSync(), isFalse);
    expect(Directory('assets/images/adventure_worlds').existsSync(), isFalse);
    expect(assets, isNot(contains('assets/images/adventure_')));
    expect(assets, contains('version: 0.32.1+82'));
  });

  testWidgets('only existing non-adventure modes are accessible', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = AppState();
    await app.load();
    await tester.pumpWidget(MaterialApp(theme: ThemeData.dark(),
        home: ModesScreen(appState: app)));
    await tester.pump();
    expect(find.text('MACERA'), findsNothing);
    expect(find.text('ADVENTURE'), findsNothing);
    expect(find.textContaining('DÜŞEN BLOKLAR'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  test('saved coins, player level and legacy-theme rights survive removal', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'coins': 815,
      'adventure_completed': List<String>.generate(15,(index) => '${index + 1}'),
      'theme_id': 'obsidian',
    });
    final app = AppState();
    await app.load();
    expect(app.coins, 815);
    expect(app.isThemeUnlocked('obsidian'), isTrue);
    expect(app.themeId, 'obsidian');
    expect(app.isAchievementClaimed('adventure_10'), isFalse);
  });
}