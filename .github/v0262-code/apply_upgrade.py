from pathlib import Path
import sys

app = Path(sys.argv[1])

def patch(relative, before, after):
    file = app / relative
    text = file.read_text(encoding="utf-8")
    count = text.count(before)
    if count != 1:
        raise RuntimeError(f"v0.26.2 patch anchor failed: {relative}, count={count}")
    file.write_text(text.replace(before, after, 1), encoding="utf-8")

patch("pubspec.yaml", "version: 0.26.1+51", "version: 0.26.2+52")
patch("test/v0240_features_test.dart", "version: 0.26.1+51", "version: 0.26.2+52")
patch("test/real_material_audio_test.dart", "version: 0.26.1+51", "version: 0.26.2+52")
patch("lib/screens/home_screen.dart", "badge: 'v0.26.1'", "badge: 'v0.26.2'")
patch("lib/screens/settings_screen.dart", "'v0.26.1  •  ", "'v0.26.2  •  ")

# A placed block can complete only a row or column it has touched. Global
# checks cause unrelated prefilled lines (e.g. a restored session) to shatter.
patch("lib/game/board_engine.dart",
"""    final rows = <int>[];
    final columns = <int>[];

    for (var row = 0; row < size; row++) {
      if (grid[row].every((value) => value)) {
        rows.add(row);
      }
    }

    for (var col = 0; col < size; col++) {
      var full = true;
      for (var row = 0; row < size; row++) {
        if (!grid[row][col]) {
          full = false;
          break;
        }
      }
      if (full) {
        columns.add(col);
      }
    }
""",
"""    final rows = <int>[];
    final columns = <int>[];

    // Evaluate only lines affected by this placement. Keep deliberate power
    // effects below intact; this prevents distant, unrelated chain clears.
    final touchedRows =
        piece.cells.map((cell) => originRow + cell.row).toSet().toList()
          ..sort();
    final touchedColumns =
        piece.cells.map((cell) => originCol + cell.col).toSet().toList()
          ..sort();

    for (final row in touchedRows) {
      if (grid[row].every((value) => value)) {
        rows.add(row);
      }
    }

    for (final col in touchedColumns) {
      if (List<bool>.generate(size, (row) => grid[row][col])
          .every((filled) => filled)) {
        columns.add(col);
      }
    }
""")

patch("lib/screens/game_screen.dart",
    "import '../widgets/material_fragment_fx.dart';",
    "import '../widgets/material_fragment_fx.dart';\nimport '../widgets/localized_shatter_overlay.dart';")

# The old widget made EACH placed cell explode independently, even without
# any line clear. Keep the settle animation but render the tile without shards.
patch("lib/screens/game_screen.dart",
"""                        child: Stack(
                          clipBehavior: Clip.none,
                          fit: StackFit.expand,
                          children: <Widget>[
                            ThemedBlockTile(
                              material: theme.material,
                              base: theme.block,
                              accent: theme.blockAccent,
                              flash: flashed ? flashAlpha : 0,
                            ),
                            MaterialFragmentFx(
                              material: theme.material,
                              trailing: false,
                            ),
                          ],
                        ),""",
"""                        child: ThemedBlockTile(
                          material: theme.material,
                          base: theme.block,
                          accent: theme.blockAccent,
                          flash: flashed ? flashAlpha : 0,
                        ),""")

# One small placement puff is anchored to the actual placed piece. It does
# not modify board state and cannot show a break on a distant cell.
board_grid_anchor = """                                        placementPulseRevision: _placementPulseRevision,
                                      ),"""
placement_overlay = """                                        placementPulseRevision: _placementPulseRevision,
                                      ),
                                      if (_placementPulseCells.isNotEmpty)
                                        Positioned.fill(
                                          child: IgnorePointer(
                                            child: LayoutBuilder(
                                              builder: (context, constraints) {
                                                final indexes = _placementPulseCells;
                                                final averageCol = indexes
                                                    .map((i) => (i % _boardSize) + 0.5)
                                                    .reduce((a, b) => a + b) /
                                                    indexes.length;
                                                final averageRow = indexes
                                                    .map((i) => (i ~/ _boardSize) + 0.5)
                                                    .reduce((a, b) => a + b) /
                                                    indexes.length;
                                                final w = constraints.maxWidth;
                                                final h = constraints.maxHeight;
                                                final side = w / _boardSize * 1.3;
                                                return ClipRect(
                                                  child: Stack(
                                                    children: <Widget>[
                                                      Positioned(
                                                        left: averageCol / _boardSize * w - side / 2,
                                                        top: averageRow / _boardSize * h - side / 2,
                                                        width: side,
                                                        height: side,
                                                        child: MaterialFragmentFx(
                                                          key: ValueKey<int>(_placementPulseRevision),
                                                          material: _theme.material,
                                                          trailing: false,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),"""
patch("lib/screens/game_screen.dart", board_grid_anchor, placement_overlay)

# Replace the broad glow and board-wide fake fractures with shards constrained
# to ONLY those cells reported cleared by BoardEngine.
file = app / "lib/screens/game_screen.dart"
data = file.read_text(encoding="utf-8")
start = data.index("""                                      if (_flashCells.isNotEmpty &&
                                          !widget.appState.performanceMode)
                                        Positioned.fill(""")
end = data.index("""                                      if (_particles.isNotEmpty)""", start)
data = data[:start] + """                                      if (_flashCells.isNotEmpty)
                                        Positioned.fill(
                                          child: LocalizedShatterOverlay(
                                            material: _theme.material,
                                            cells: _flashCells,
                                            boardSize: _boardSize,
                                            progress: progress,
                                            lowFx: widget.appState.performanceMode,
                                          ),
                                        ),
""" + data[end:]
start = data.index("""                                      if (_flashCells.isNotEmpty &&
                                          _combo >= 3 &&
                                          !widget.appState.performanceMode)""")
end = data.index("""                                      if (_floatingScores.isNotEmpty)""", start)
data = data[:start] + data[end:]
file.write_text(data, encoding="utf-8")

# Light, localized micro-fragments: no board-spanning motion when a row clears.
patch("lib/screens/game_screen.dart",
"""    final maxVisibleParticles = widget.appState.performanceMode
        ? 42
        : cells.length >= 18
            ? 110
            : 150;""",
"""    final maxVisibleParticles = widget.appState.performanceMode
        ? 20
        : cells.length >= 18
            ? 42
            : 55;""")
patch("lib/screens/game_screen.dart", "vx: particle.vx * 0.15,", "vx: particle.vx * 0.042,")
patch("lib/screens/game_screen.dart", "vy: particle.vy * 0.15,", "vy: particle.vy * 0.042,")
patch("lib/screens/game_screen.dart",
      "_impactLevel = (impact + burst.shakeAmplitude * 2).round().clamp(1, 6);",
      "_impactLevel = (impact + burst.shakeAmplitude).round().clamp(1, 3);")

(app / 'lib/widgets/localized_shatter_overlay.dart').write_text(
    (Path(__file__).parent / 'localized_shatter_overlay.dart').read_text(encoding='utf-8'),
    encoding='utf-8')

(app / 'test/v0262_localized_break_test.dart').write_text("""import 'package:flutter_test/flutter_test.dart';
import 'package:elxvro_blocks/game/board_engine.dart';
import 'package:elxvro_blocks/models/block_piece.dart';
import 'dart:io';

void main() {
  const single = BlockPiece(id: 'single-test', cells: <CellOffset>[CellOffset(0, 0)]);
  test('a complete but unrelated row never breaks on a distant placement', () {
    final board = BoardEngine(size: 4);
    board.restore(<List<bool>>[
      <bool>[true, true, true, true],
      <bool>[false, false, false, false],
      <bool>[false, false, false, false],
      <bool>[false, false, false, false],
    ]);
    final result = board.place(single, 3, 3)!;
    expect(result.clearedCells, isEmpty);
    expect(result.clearedRows, isEmpty);
    expect(board.grid[0], everyElement(isTrue));
  });
  test('only a newly completed row is cleared, not incomplete neighbors', () {
    final board = BoardEngine(size: 4);
    board.restore(<List<bool>>[
      <bool>[false, false, false, false],
      <bool>[true, true, true, false],
      <bool>[false, true, false, false],
      <bool>[false, false, false, false],
    ]);
    final result = board.place(single, 1, 3)!;
    expect(result.clearedRows, <int>[1]);
    expect(result.clearedColumns, isEmpty);
    expect(result.clearedCells.toSet(),
      <BoardCell>{for (var col = 0; col < 4; col++) BoardCell(1, col)});
    expect(board.grid[2][1], isTrue);
  });
  test('visual breakup does not attach to every placed board cell', () {
    final screen = File('lib/screens/game_screen.dart').readAsStringSync();
    expect(screen, contains('LocalizedShatterOverlay('));
    expect(screen, contains('cells: _flashCells,'));
    expect(screen, contains('key: ValueKey<int>(_placementPulseRevision)'));
    expect(screen, isNot(contains('_Combo2DSplash(\\n')));
  });
}
""", encoding='utf-8')

print('v0.26.2: clear scope, local sprite shards, single placement impact, regression tests')
