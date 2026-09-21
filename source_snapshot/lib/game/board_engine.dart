import '../models/block_piece.dart';

class BoardCell {
  const BoardCell(this.row, this.col);

  final int row;
  final int col;

  @override
  bool operator ==(Object other) {
    return other is BoardCell && other.row == row && other.col == col;
  }

  @override
  int get hashCode => Object.hash(row, col);
}

class PlacementResult {
  const PlacementResult({
    required this.placedCells,
    required this.clearedRows,
    required this.clearedColumns,
    required this.clearedCells,
    required this.power,
  });

  final int placedCells;
  final List<int> clearedRows;
  final List<int> clearedColumns;
  final List<BoardCell> clearedCells;
  final PiecePower power;

  int get clearedLines => clearedRows.length + clearedColumns.length;
  int get clearedCellCount => clearedCells.length;
  bool get usedSpecial => power != PiecePower.normal;
}

class BoardEngine {
  BoardEngine({this.size = 10})
      : grid = List<List<bool>>.generate(
          size,
          (_) => List<bool>.filled(size, false),
        );

  final int size;
  final List<List<bool>> grid;

  void reset() {
    for (final row in grid) {
      row.fillRange(0, row.length, false);
    }
  }

  List<List<bool>> snapshot() {
    return grid.map((row) => List<bool>.from(row)).toList();
  }

  void restore(List<List<bool>> state) {
    if (state.length != size || state.any((row) => row.length != size)) {
      throw ArgumentError('Board snapshot size does not match engine size.');
    }
    for (var row = 0; row < size; row++) {
      for (var col = 0; col < size; col++) {
        grid[row][col] = state[row][col];
      }
    }
  }

  bool canPlace(BlockPiece piece, int originRow, int originCol) {
    for (final cell in piece.cells) {
      final row = originRow + cell.row;
      final col = originCol + cell.col;
      if (row < 0 || col < 0 || row >= size || col >= size) {
        return false;
      }
      if (grid[row][col]) {
        return false;
      }
    }
    return true;
  }

  PlacementResult? place(BlockPiece piece, int originRow, int originCol) {
    if (!canPlace(piece, originRow, originCol)) {
      return null;
    }

    for (final cell in piece.cells) {
      grid[originRow + cell.row][originCol + cell.col] = true;
    }

    final rows = <int>[];
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

    final cellsToClear = <BoardCell>{};

    void addFilledCell(int row, int col) {
      if (row < 0 || col < 0 || row >= size || col >= size) {
        return;
      }
      if (grid[row][col]) {
        cellsToClear.add(BoardCell(row, col));
      }
    }

    for (final row in rows) {
      for (var col = 0; col < size; col++) {
        addFilledCell(row, col);
      }
    }
    for (final col in columns) {
      for (var row = 0; row < size; row++) {
        addFilledCell(row, col);
      }
    }

    switch (piece.power) {
      case PiecePower.bomb:
        for (var row = originRow - 1; row <= originRow + 1; row++) {
          for (var col = originCol - 1; col <= originCol + 1; col++) {
            addFilledCell(row, col);
          }
        }
        break;
      case PiecePower.rowClear:
        for (var col = 0; col < size; col++) {
          addFilledCell(originRow, col);
        }
        break;
      case PiecePower.columnClear:
        for (var row = 0; row < size; row++) {
          addFilledCell(row, originCol);
        }
        break;
      case PiecePower.normal:
      case PiecePower.wild:
        break;
    }

    for (final cell in cellsToClear) {
      grid[cell.row][cell.col] = false;
    }

    return PlacementResult(
      placedCells: piece.size,
      clearedRows: rows,
      clearedColumns: columns,
      clearedCells: cellsToClear.toList(growable: false),
      power: piece.power,
    );
  }

  bool hasMoveFor(BlockPiece piece) {
    for (var row = 0; row < size; row++) {
      for (var col = 0; col < size; col++) {
        if (canPlace(piece, row, col)) {
          return true;
        }
      }
    }
    return false;
  }

  bool hasAnyMove(Iterable<BlockPiece> pieces) {
    return pieces.any(hasMoveFor);
  }
}
