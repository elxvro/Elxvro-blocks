import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:elxvro_blocks/app_state.dart';
import 'package:elxvro_blocks/main.dart';
import 'package:elxvro_blocks/screens/main_hub_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Arabic home and game tabs keep the original physical order',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final state = AppState();
    await state.load();
    await state.setLanguage('ar');
    await tester.pumpWidget(ElxvroBlocksApp(appState: state));
    await tester.pump();

    final hub = find.byType(MainHubScreen);
    expect(hub, findsOneWidget);
    expect(Localizations.localeOf(tester.element(hub)).languageCode, 'ar');
    expect(Directionality.of(tester.element(hub)), TextDirection.ltr);

    final home = find.byKey(const ValueKey<String>('tab_home'));
    final game = find.byKey(const ValueKey<String>('tab_game'));
    final settings = find.byKey(const ValueKey<String>('tab_settings'));
    expect(tester.getTopLeft(home).dx, lessThan(tester.getTopLeft(game).dx));
    expect(tester.getTopLeft(game).dx, lessThan(tester.getTopLeft(settings).dx));

    await tester.tap(game);
    await tester.pump();
    expect(find.byKey(const ValueKey<String>('game_classic')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('game_falling')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('game_adventure')), findsOneWidget);
    expect(Directionality.of(tester.element(hub)), TextDirection.ltr);
    expect(tester.takeException(), isNull);

    await tester.tap(settings);
    await tester.pump();
    expect(Directionality.of(tester.element(hub)), TextDirection.ltr);
    expect(Localizations.localeOf(tester.element(hub)).languageCode, 'ar');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Switching Arabic to Turkish and back never mirrors the game',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final state = AppState();
    await state.load();
    await state.setLanguage('ar');
    await tester.pumpWidget(ElxvroBlocksApp(appState: state));
    await tester.pump();

    final hub = find.byType(MainHubScreen);
    expect(Directionality.of(tester.element(hub)), TextDirection.ltr);
    await state.setLanguage('tr');
    await tester.pump();
    expect(Localizations.localeOf(tester.element(hub)).languageCode, 'tr');
    expect(Directionality.of(tester.element(hub)), TextDirection.ltr);
    await state.setLanguage('ar');
    await tester.pump();
    expect(Localizations.localeOf(tester.element(hub)).languageCode, 'ar');
    expect(Directionality.of(tester.element(hub)), TextDirection.ltr);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
