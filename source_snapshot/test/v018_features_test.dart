import 'package:flutter_test/flutter_test.dart';
import 'package:elxvro_blocks/game/board_engine.dart';
import 'package:elxvro_blocks/models/adventure_level.dart';
import 'package:elxvro_blocks/models/block_piece.dart';
import 'package:elxvro_blocks/models/game_mode.dart';

void main() {
  test('adventure contains 60 progressively harder levels', () {
    expect(adventureLevels.length, adventureLevelCount);
    expect(adventureLevels.first.number, 1);
    expect(adventureLevels.last.number, 60);
    expect(
      adventureLevels.last.targetScore,
      greaterThan(adventureLevels.first.targetScore),
    );
    expect(
      adventureLevels.where((level) => level.hardPieces).length,
      greaterThanOrEqualTo(10),
    );
    expect(
      adventureLevels.where((level) => level.durationSeconds != null).length,
      greaterThanOrEqualTo(20),
    );
  });

  test('daily challenge rules are deterministic for the same date', () {
    final day = DateTime(2026, 10, 6);
    final first = dailyChallengeData(day);
    final second = dailyChallengeData(day);

    expect(first.targetScore, second.targetScore);
    expect(first.durationSeconds, second.durationSeconds);
    expect(first.targetScore, inInclusiveRange(3200, 4950));
    expect(first.durationSeconds, inInclusiveRange(165, 195));
  });

  test('cross special clears its row and column', () {
    final engine = BoardEngine(size: 7);
    final state = List<List<bool>>.generate(
      7,
      (_) => List<bool>.filled(7, false),
    );
    state[3][0] = true;
    state[3][6] = true;
    state[0][3] = true;
    state[6][3] = true;
    state[1][1] = true;
    engine.restore(state);

    final cross = specialBlockCatalog.firstWhere(
      (piece) => piece.power == PiecePower.crossClear,
    );
    final result = engine.place(cross, 3, 3)!;

    expect(result.usedSpecial, isTrue);
    for (var i = 0; i < 7; i++) {
      expect(engine.grid[3][i], isFalse);
      expect(engine.grid[i][3], isFalse);
    }
    expect(engine.grid[1][1], isTrue);
  });

  test('mega bomb clears a five by five impact area', () {
    final engine = BoardEngine(size: 7);
    final state = List<List<bool>>.generate(
      7,
      (_) => List<bool>.filled(7, true),
    );
    state[3][3] = false;
    engine.restore(state);

    final mega = specialBlockCatalog.firstWhere(
      (piece) => piece.power == PiecePower.megaBomb,
    );
    final result = engine.place(mega, 3, 3)!;

    expect(result.usedSpecial, isTrue);
    for (var row = 1; row <= 5; row++) {
      for (var col = 1; col <= 5; col++) {
        expect(engine.grid[row][col], isFalse);
      }
    }
  });
}
