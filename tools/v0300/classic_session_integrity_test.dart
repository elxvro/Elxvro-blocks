import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:elxvro_blocks/game/classic_session_store.dart';

const sampleBoard =
    '00100110010010011001001001100100100110010010011001'
    '00100110010010011001001001100100100110010010011001';

ClassicSessionSnapshot sample({int score = 123}) =>
    ClassicSessionSnapshot(
      board: sampleBoard,
      pieces: const <String>['square_2', '-', 'line_3_h'],
      score: score, combo: 2, bestCombo: 4, clearedLines: 7,
      placedBlocks: 19, perfectClears: 1,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('single complete record persists all game fields', () async {
    final store = ClassicSessionStore();
    await store.save(sample());
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(ClassicSessionStore.snapshotKey);
    expect(raw, isNotNull);
    expect(jsonDecode(raw!)['schema'], 1);
    expect(prefs.getString('active_game_board_v0161'), isNull);
    final restored = await ClassicSessionStore().load();
    expect(restored?.score, 123);
    expect(restored?.board, sampleBoard);
    expect(restored?.pieces.last, 'line_3_h');
    expect(restored?.perfectClears, 1);
  });

  test('save / reset / new save cannot restore the old game', () async {
    final store = ClassicSessionStore();
    final earlier = store.save(sample(score: 7));
    final reset = store.clear();
    final latest = store.save(sample(score: 999));
    await Future.wait(<Future<void>>[earlier, reset, latest]);
    expect((await ClassicSessionStore().load())?.score, 999);
    await store.clear();
    expect(await store.load(), isNull);
  });

  test('earlier saves from v0.16.1 to v0.29.9 are read', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'active_game_valid_v0161': true,
      'active_game_board_v0161': sampleBoard,
      'active_game_pieces_v0161': 'square_2,-,line_3_h',
      'active_game_score_v0161': 515,
      'active_game_combo_v0161': 2,
      'active_game_best_combo_v0161': 3,
      'active_game_lines_v0161': 4,
      'active_game_blocks_v0161': 13,
      'active_game_perfect_v0161': 1,
    });
    final store = ClassicSessionStore();
    expect((await store.load())?.score, 515);
    await store.save(sample(score: 616));
    expect((await store.load())?.score, 616);
    await store.clear();
    expect(await store.load(), isNull);
  });

  test('corrupt and unknown schema saves are safely cleared', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ClassicSessionStore.snapshotKey, '{bad');
    expect(await ClassicSessionStore().load(), isNull);
    expect(prefs.getString(ClassicSessionStore.snapshotKey), isNull);
    await prefs.setString(ClassicSessionStore.snapshotKey,
        jsonEncode(<String, Object>{...sample().toJson(), 'schema': 99}));
    expect(await ClassicSessionStore().load(), isNull);
    await prefs.setString(ClassicSessionStore.snapshotKey, jsonEncode(
        <String, Object>{
          ...sample().toJson(),
          'board': List<String>.filled(100, '2').join(),
        }));
    expect(await ClassicSessionStore().load(), isNull);
  });

  test('incomplete or negative progress cannot be saved', () async {
    final store = ClassicSessionStore();
    expect(() => store.save(ClassicSessionSnapshot(
      board: sampleBoard,
      pieces: const <String>['square_2', '-', 'line_3_h'],
      score: -1, combo: 0, bestCombo: 0,
      clearedLines: 0, placedBlocks: 0, perfectClears: 0,
    )), throwsArgumentError);
    expect(await store.load(), isNull);
  });

  test('other game modes cannot clear Classic mode and input is guarded', () {
    final source = File('lib/screens/game_screen.dart').readAsStringSync();
    final start = source.indexOf('Future<void> _clearSavedClassicGame()');
    expect(start, greaterThan(0));
    final end = source.indexOf('void _resetGame()', start);
    final method = source.substring(start, end);
    expect(method, contains('widget.mode != GameMode.classic'));
    expect(method, contains('await _classicSessionStore.clear()'));
    expect(source, contains('bool _restoringClassicSession = false;'));
    expect(source, contains('|| _restoringClassicSession) return;'));
    expect(source, contains('await _classicSessionStore.load()'));
  });
}
