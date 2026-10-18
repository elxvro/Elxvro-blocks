import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:elxvro_blocks/app_state.dart';
import 'package:elxvro_blocks/screens/falling_blocks_screen.dart';
import 'package:elxvro_blocks/screens/animal_adventure_screen.dart';
import 'package:elxvro_blocks/services/animal_match_progress.dart';
import 'package:elxvro_blocks/widgets/themed_block_tile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('falling board must render tiles, not black ErrorWidget',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app=AppState();
    await app.load();
    await tester.pumpWidget(MaterialApp(home:FallingBlocksScreen(appState:app)));
    await tester.pump();
    expect(find.byType(GridView), findsOneWidget);
    expect(find.byType(ThemedBlockTile), findsWidgets);
    expect(find.byType(ErrorWidget), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 950));
    expect(tester.takeException(), isNull);
  });

  test('corrupt saved progress types do not block the map or erase coins', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'animal_match_unlocked_v1':'corrupted',
      'animal_match_stars_v1':300,
      'animal_match_completed_v1':<String>['1','oops','999'],
      'coins':92,
    });
    final progress=AnimalMatchProgress();
    await progress.load();
    expect(progress.unlocked,2);
    expect(progress.stars,isEmpty);
    expect(progress.completed,contains(1));
    final prefs=await SharedPreferences.getInstance();
    expect(prefs.get('animal_match_unlocked_v1'),'corrupted');
    expect(prefs.getInt('coins'),92);
  });

  testWidgets('animal stage list appears instead of an endless spinner',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360,780));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app=AppState();
    await app.load();
    await tester.pumpWidget(MaterialApp(home:AnimalAdventureScreen(appState:app)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('Tilki'),findsWidgets);
    expect(find.byType(CircularProgressIndicator),findsNothing);
    expect(tester.takeException(),isNull);
  });
}
