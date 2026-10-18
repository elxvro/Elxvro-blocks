import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:elxvro_blocks/game/adventure_specials.dart';
import 'package:elxvro_blocks/game/adventure_quest.dart';

void main() {
  test('special stones are distributed by adventure world', () {
    expect(AdventureStone.forWorld(0, 0), AdventureStone.pulse);
    expect(AdventureStone.forWorld(1, 0), AdventureStone.shield);
    expect(AdventureStone.forWorld(3, 1), AdventureStone.ember);
    expect(AdventureStone.forWorld(4, 1), AdventureStone.pulse);
    expect(AdventureStone.forWorld(5, 0), AdventureStone.ember);
    expect(AdventureStone.forWorld(0, 10), isNull);
    expect(AdventureStone.forWorld(5, -1), isNull);
  });

  test('power stones grant bonuses without capping score', () {
    final stones = <int>[
      AdventureStone.pulse, AdventureStone.ember,
      AdventureStone.shield, AdventureSpecial.ice,
    ];
    expect(AdventureStone.bonusScore(stones), 400);
    expect(AdventureStone.shields(stones), 1);
    expect(AdventureStone.bonusScore(List<int>.filled(100, AdventureStone.ember)), 25000);
  });

  test('pulse clears neighbors but retains full rows for normal clearing', () {
    final board = <List<int>>[
      <int>[1, 2, 3, 4, -1],
      <int>[0, 1, AdventureStone.pulse, 2, 3],
      <int>[3, 4, 5, 6, -1],
      <int>[1, -1, -1, -1, 1],
    ];
    expect(AdventureStone.discharge(board, <int>[1]), 6);
    expect(board[0], <int>[1, -1, -1, -1, -1]);
    expect(board[1][2], AdventureStone.pulse);
    expect(board[2], <int>[3, -1, -1, -1, -1]);
  });

  test('edge pulses are bounded', () {
    final board = <List<int>>[
      <int>[1, 1, 1],
      <int>[AdventureStone.pulse, 2, 3],
      <int>[4, 5, 6],
    ];
    expect(AdventureStone.discharge(board, <int>[0, 1]), 2);
    expect(board[0], <int>[1, 1, 1]);
    expect(board[2], <int>[-1, -1, 6]);
  });

  test('completed mission remains an ongoing run until defeat', () {
    final quest = AdventureQuestProgress(AdventureMission.forLevel(1));
    quest.onClearedRows(count: 4, removedCells: const <int>[], combo: 1);
    expect(quest.completed, isTrue);
    final source = File('lib/screens/falling_blocks_screen.dart').readAsStringSync();
    expect(source, isNot(contains('if (_quest?.completed == true)')));
    expect(source, contains('final completed = _isAdventure ? _quest!.completed : success;'));
    expect(source, contains('AdventureStone.discharge(_board, cleared)'));
    expect(source, contains('AdventureWorldBackdrop(world: _quest!.mission.world'));
    expect(source, contains('AdventureSpecialTile('));
    expect(source, contains('_shieldCharges--'));
  });

  test('player themes and classic save are still intact', () {
    final classic = File('lib/screens/game_screen.dart').readAsStringSync();
    expect(classic, isNot(contains('AdventureStone')));
    expect(File('lib/game/classic_session_store.dart').readAsStringSync(),
      contains('ClassicSessionStore'));
    expect(File('pubspec.yaml').readAsStringSync(), contains('version: 0.31.1+77'));
  });
}
