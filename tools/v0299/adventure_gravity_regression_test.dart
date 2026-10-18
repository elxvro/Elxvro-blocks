import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:elxvro_blocks/game/adventure_rise_rules.dart';

void main() {
  test('deferred rise neither locks a midair piece nor mutates the board', () {
    final board = <List<int>>[
      <int>[-1, -1, -1, -1],
      <int>[-1, -1, -1, -1],
      <int>[-1, 1, -1, -1],
      <int>[2, -1, 1, -1],
    ];
    final before = board.map((row) => List<int>.of(row)).toList();
    final decision = planAdventureRise(
      board: board,
      activeCells: <(int, int)>[(0, 0), (0, 1)],
      activeRow: 1,
      activeCol: 1,
      incomingRow: <int>[1, -1, 2, 2],
    );
    expect(decision.outcome, AdventureRiseOutcome.defer);
    expect(decision.board, isNull);
    expect(board, before);
  });

  test('a deferred rise succeeds after active piece moves out of the way', () {
    final board = <List<int>>[
      <int>[-1, -1, -1],
      <int>[-1, -1, -1],
      <int>[-1, 3, -1],
      <int>[1, -1, 1],
    ];
    final original = board.map((row) => List<int>.of(row)).toList();
    AdventureRiseDecision attempt(int column) => planAdventureRise(
      board: board,
      activeCells: <(int, int)>[(0, 0)],
      activeRow: 1,
      activeCol: column,
      incomingRow: <int>[2, -1, 2],
    );
    expect(attempt(1).outcome, AdventureRiseOutcome.defer);
    expect(attempt(0).outcome, AdventureRiseOutcome.rise);
    expect(attempt(0).board![1][1], 3);
    expect(board, original);
  });

  test('actual top overflow is still terminal and never shifts the stack', () {
    final board = <List<int>>[
      <int>[0, -1],
      <int>[-1, -1],
      <int>[1, -1],
    ];
    final result = planAdventureRise(
      board: board,
      activeCells: <(int, int)>[(0, 0)],
      activeRow: 1,
      activeCol: 1,
      incomingRow: <int>[-1, 2],
    );
    expect(result.outcome, AdventureRiseOutcome.overflow);
    expect(result.board, isNull);
    expect(board.first, <int>[0, -1]);
  });

  test('screen defers overlap and retries rise next fall tick', () {
    final source = File('lib/screens/falling_blocks_screen.dart').readAsStringSync();
    final start = source.indexOf('case AdventureRiseOutcome.defer:');
    expect(start, greaterThanOrEqualTo(0));
    final handler = source.substring(start, source.indexOf(
      'case AdventureRiseOutcome.rise:', start,
    ));
    expect(handler, contains('_riseTicks = 7;'));
    expect(handler, isNot(contains('_lockPiece()')));
    expect(source, contains('if (_paused || _gameOver || _finishing || _locking) return;'));
  });

  test('gravity checks pause before each step and aborts on dispose', () {
    final source = File('lib/screens/falling_blocks_screen.dart').readAsStringSync();
    final start = source.indexOf('Future<void> _settleFloatingBlocks()');
    final end = source.indexOf('Future<void> _lockPiece()', start);
    final gravity = source.substring(start, end);
    expect(gravity, contains('if (_paused) {'));
    expect(gravity, contains('continue;'));
    expect(gravity, contains('await Future<void>.delayed'));
    expect(source, contains('if (!mounted || _finishing) return;'));
  });
}
