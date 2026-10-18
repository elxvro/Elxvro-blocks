import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:elxvro_blocks/app_state.dart';
import 'package:elxvro_blocks/game/adventure_rise_rules.dart';
import 'package:elxvro_blocks/models/adventure_level.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('rising does not move the active piece or mutate board in place', () {
    final board = <List<int>>[
      <int>[-1, -1, -1, -1],
      <int>[-1, -1, -1, -1],
      <int>[-1, 1, -1, -1],
      <int>[1, -1, -1, 2],
    ];
    final before = board.map((row) => List<int>.from(row)).toList();
    const cells = <(int, int)>[(0, 0), (0, 1)];
    final result = planAdventureRise(
      board: board, activeCells: cells,
      activeRow: 0, activeCol: 0, incomingRow: <int>[2, 2, -1, 2],
    );
    expect(result.outcome, AdventureRiseOutcome.rise);
    expect(result.board, <List<int>>[
      <int>[-1, -1, -1, -1],
      <int>[-1, 1, -1, -1],
      <int>[1, -1, -1, 2],
      <int>[2, 2, -1, 2],
    ]);
    expect(board, before);
  });

  test('rise collision requests locking before board rises', () {
    final board = <List<int>>[
      <int>[-1, -1, -1],
      <int>[-1, -1, -1],
      <int>[-1, 3, -1],
      <int>[-1, -1, -1],
    ];
    final original = board.map((row) => List<int>.from(row)).toList();
    final result = planAdventureRise(
      board: board, activeCells: <(int, int)>[(0, 0)],
      activeRow: 1, activeCol: 1, incomingRow: <int>[2, -1, 2],
    );
    expect(result.outcome, AdventureRiseOutcome.lockActivePiece);
    expect(result.board, isNull);
    expect(board, original);
  });

  test('rising into occupied top row ends round without board mutation', () {
    final board = <List<int>>[
      <int>[1, -1],
      <int>[-1, 2],
      <int>[-1, -1],
    ];
    final result = planAdventureRise(
      board: board, activeCells: <(int, int)>[(0, 0)],
      activeRow: 0, activeCol: 1, incomingRow: <int>[2, -1],
    );
    expect(result.outcome, AdventureRiseOutcome.overflow);
    expect(result.board, isNull);
    expect(board.first, <int>[1, -1]);
  });

  test('partially offscreen spawning piece does not spuriously collide', () {
    final result = planAdventureRise(
      board: <List<int>>[
        <int>[-1, -1],
        <int>[-1, -1],
        <int>[1, -1],
      ],
      activeCells: <(int, int)>[(0, 0), (1, 0)],
      activeRow: -2, activeCol: 0, incomingRow: <int>[1, -1],
    );
    expect(result.outcome, AdventureRiseOutcome.rise);
  });

  test('loss unlocks next stage without completion stars or coins', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final state = AppState();
    await state.load();
    final originalCoins = state.coins;
    final level = adventureLevelFor(1);
    final earned = await state.completeAdventureLevel(
      level: 1, reward: level.reward, score: 50, completed: false,
    );
    expect(earned, 0);
    expect(state.coins, originalCoins);
    expect(state.adventureUnlockedLevel, 2);
    expect(state.adventureCompletedCount, 0);
    expect(state.adventureStarsForLevel(1), 0);
    expect(state.adventureBestScoreForLevel(1), 50);

    final reloaded = AppState();
    await reloaded.load();
    expect(reloaded.adventureUnlockedLevel, 2);
    expect(reloaded.adventureCompletedCount, 0);
    expect(reloaded.adventureBestScoreForLevel(1), 50);
  });

  test('first successful target score earns reward once and persists', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final state = AppState();
    await state.load();
    final initial = state.coins;
    final level = adventureLevelFor(1);
    await state.completeAdventureLevel(
      level: 1, reward: level.reward, score: 90, completed: false,
    );
    final earned = await state.completeAdventureLevel(
      level: 1, reward: level.reward,
      score: level.targetScore, completed: true,
    );
    expect(earned, level.reward);
    expect(state.coins, initial + level.reward);
    expect(state.adventureCompletedCount, 1);
    expect(state.adventureStarsForLevel(1), 1);
    final second = await state.completeAdventureLevel(
      level: 1, reward: level.reward,
      score: level.targetScore * 2, completed: true,
    );
    expect(second, 0);
    expect(state.coins, initial + level.reward);
    final restored = AppState();
    await restored.load();
    expect(restored.adventureCompletedCount, 1);
    expect(restored.coins, initial + level.reward);
    expect(restored.adventureStarsForLevel(1), 3);
  });

  test('UI locks all movements during asynchronous piece settling', () {
    final source = File('lib/screens/falling_blocks_screen.dart').readAsStringSync();
    for (final method in <String>[
      'void _move(int delta)', 'void _rotate()',
      'void _hardDrop()', 'void _onPanUpdate(DragUpdateDetails details)',
    ]) {
      final start = source.indexOf(method);
      expect(start, greaterThanOrEqualTo(0), reason: method);
      expect(source.substring(start, start + 170),
          contains('_locking'), reason: method);
    }
    expect(source, contains('planAdventureRise('));
    expect(source, contains('completed: completed'));
    expect(source, contains('reward: completed ? level.reward : 0'));
  });
}
