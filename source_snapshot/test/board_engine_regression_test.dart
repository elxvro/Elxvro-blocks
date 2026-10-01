import 'package:flutter_test/flutter_test.dart';
import 'package:elxvro_blocks/game/board_engine.dart';
import 'package:elxvro_blocks/models/block_piece.dart';

void main() {
  final single = blockCatalog.firstWhere((piece) => piece.id == 'single');

  test('incomplete row never clears', () {
    final engine = BoardEngine(size: 4);
    engine.restore(<List<bool>>[
      <bool>[false, false, false, false],
      <bool>[true, true, false, false],
      <bool>[false, false, false, false],
      <bool>[false, false, false, false],
    ]);

    final result = engine.place(single, 1, 2)!;

    expect(result.clearedRows, isEmpty);
    expect(result.clearedColumns, isEmpty);
    expect(result.clearedCellCount, 0);
    expect(engine.grid[1], <bool>[true, true, true, false]);
  });

  test('incomplete column never clears', () {
    final engine = BoardEngine(size: 4);
    engine.restore(<List<bool>>[
      <bool>[false, true, false, false],
      <bool>[false, true, false, false],
      <bool>[false, false, false, false],
      <bool>[false, false, false, false],
    ]);

    final result = engine.place(single, 2, 1)!;

    expect(result.clearedRows, isEmpty);
    expect(result.clearedColumns, isEmpty);
    expect(result.clearedCellCount, 0);
    expect(engine.grid[2][1], isTrue);
  });

  test('completed row clears only that row', () {
    final engine = BoardEngine(size: 4);
    engine.restore(<List<bool>>[
      <bool>[true, false, false, false],
      <bool>[true, true, false, true],
      <bool>[false, true, false, false],
      <bool>[false, false, false, false],
    ]);

    final result = engine.place(single, 1, 2)!;

    expect(result.clearedRows, <int>[1]);
    expect(result.clearedColumns, isEmpty);
    expect(result.clearedCellCount, 4);
    expect(engine.grid[1], <bool>[false, false, false, false]);
    expect(engine.grid[0][0], isTrue);
    expect(engine.grid[2][1], isTrue);
  });

  test('row column intersection is cleared once', () {
    final engine = BoardEngine(size: 4);
    engine.restore(<List<bool>>[
      <bool>[false, false, true, false],
      <bool>[true, true, false, true],
      <bool>[false, false, true, false],
      <bool>[false, false, true, false],
    ]);

    final result = engine.place(single, 1, 2)!;

    expect(result.clearedRows, <int>[1]);
    expect(result.clearedColumns, <int>[2]);
    expect(result.clearedCellCount, 7);
    expect(engine.grid[1], <bool>[false, false, false, false]);
    expect(engine.grid[0][2], isFalse);
    expect(engine.grid[2][2], isFalse);
    expect(engine.grid[3][2], isFalse);
  });
}
