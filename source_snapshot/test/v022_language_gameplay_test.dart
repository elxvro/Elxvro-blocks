import 'package:flutter/material.dart';
import 'dart:io';\n\nimport 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:elxvro_blocks/app_state.dart';
import 'package:elxvro_blocks/l10n/app_strings.dart';
import 'package:elxvro_blocks/models/game_theme.dart';
import 'package:elxvro_blocks/widgets/gameplay_background.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('language selection persists and falls back safely', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final state = AppState();
    await state.load();

    expect(state.languageCode, 'tr');
    await state.setLanguage('en');
    expect(state.languageCode, 'en');

    final restored = AppState();
    await restored.load();
    expect(restored.languageCode, 'en');

    await restored.setLanguage('de');
    expect(restored.languageCode, 'tr');
  });

  test('core Turkish and English labels are available', () {
    expect(const AppStrings('tr').t('home.play'), 'OYNA');
    expect(const AppStrings('en').t('home.play'), 'PLAY');
    expect(const AppStrings('en').t('falling.rotate'), 'ROTATE');
  });

  test('v0.22 build patch enlarges both gameplay boards', () {
    final patch = File('../../.github/scripts/apply_v022.py').readAsStringSync();
    expect(patch, contains('constraints.maxWidth - 12'));
    expect(patch, contains('clamp(228.0, 448.0)'));
    expect(patch, contains('GameplayBackground'));
  });

  testWidgets('gameplay background renders for themed gameplay', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GameplayBackground(
          theme: gameThemes.first,
          child: const SizedBox.expand(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(GameplayBackground), findsOneWidget);
  });
}
