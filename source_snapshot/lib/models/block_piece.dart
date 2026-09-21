import 'dart:math';

enum PiecePower {
  normal,
  bomb,
  rowClear,
  columnClear,
  wild,
}

class CellOffset {
  const CellOffset(this.row, this.col);

  final int row;
  final int col;
}

class BlockPiece {
  const BlockPiece({
    required this.id,
    required this.cells,
    this.power = PiecePower.normal,
  });

  final String id;
  final List<CellOffset> cells;
  final PiecePower power;

  int get rows => cells.map((cell) => cell.row).reduce(max) + 1;
  int get cols => cells.map((cell) => cell.col).reduce(max) + 1;
  int get size => cells.length;
  bool get isSpecial => power != PiecePower.normal;

  String get powerLabel {
    switch (power) {
      case PiecePower.bomb:
        return 'BOMBA';
      case PiecePower.rowClear:
        return 'SATIR';
      case PiecePower.columnClear:
        return 'SÜTUN';
      case PiecePower.wild:
        return 'JOKER';
      case PiecePower.normal:
        return '';
    }
  }
}

const List<BlockPiece> blockCatalog = <BlockPiece>[
  BlockPiece(id: 'single', cells: <CellOffset>[CellOffset(0, 0)]),
  BlockPiece(
    id: 'domino_h',
    cells: <CellOffset>[CellOffset(0, 0), CellOffset(0, 1)],
  ),
  BlockPiece(
    id: 'domino_v',
    cells: <CellOffset>[CellOffset(0, 0), CellOffset(1, 0)],
  ),
  BlockPiece(
    id: 'line_3_h',
    cells: <CellOffset>[
      CellOffset(0, 0),
      CellOffset(0, 1),
      CellOffset(0, 2),
    ],
  ),
  BlockPiece(
    id: 'line_3_v',
    cells: <CellOffset>[
      CellOffset(0, 0),
      CellOffset(1, 0),
      CellOffset(2, 0),
    ],
  ),
  BlockPiece(
    id: 'line_4_h',
    cells: <CellOffset>[
      CellOffset(0, 0),
      CellOffset(0, 1),
      CellOffset(0, 2),
      CellOffset(0, 3),
    ],
  ),
  BlockPiece(
    id: 'line_4_v',
    cells: <CellOffset>[
      CellOffset(0, 0),
      CellOffset(1, 0),
      CellOffset(2, 0),
      CellOffset(3, 0),
    ],
  ),
  BlockPiece(
    id: 'square_2',
    cells: <CellOffset>[
      CellOffset(0, 0),
      CellOffset(0, 1),
      CellOffset(1, 0),
      CellOffset(1, 1),
    ],
  ),
  BlockPiece(
    id: 'l_small',
    cells: <CellOffset>[
      CellOffset(0, 0),
      CellOffset(1, 0),
      CellOffset(1, 1),
    ],
  ),
  BlockPiece(
    id: 'l_medium',
    cells: <CellOffset>[
      CellOffset(0, 0),
      CellOffset(1, 0),
      CellOffset(2, 0),
      CellOffset(2, 1),
      CellOffset(2, 2),
    ],
  ),
  BlockPiece(
    id: 't',
    cells: <CellOffset>[
      CellOffset(0, 0),
      CellOffset(0, 1),
      CellOffset(0, 2),
      CellOffset(1, 1),
    ],
  ),
  BlockPiece(
    id: 'z',
    cells: <CellOffset>[
      CellOffset(0, 0),
      CellOffset(0, 1),
      CellOffset(1, 1),
      CellOffset(1, 2),
    ],
  ),
  BlockPiece(
    id: 'corner_5',
    cells: <CellOffset>[
      CellOffset(0, 0),
      CellOffset(1, 0),
      CellOffset(2, 0),
      CellOffset(2, 1),
      CellOffset(2, 2),
    ],
  ),
  BlockPiece(
    id: 'square_3',
    cells: <CellOffset>[
      CellOffset(0, 0),
      CellOffset(0, 1),
      CellOffset(0, 2),
      CellOffset(1, 0),
      CellOffset(1, 1),
      CellOffset(1, 2),
      CellOffset(2, 0),
      CellOffset(2, 1),
      CellOffset(2, 2),
    ],
  ),
  BlockPiece(
    id: 'line_5_h',
    cells: <CellOffset>[
      CellOffset(0, 0),
      CellOffset(0, 1),
      CellOffset(0, 2),
      CellOffset(0, 3),
      CellOffset(0, 4),
    ],
  ),
  BlockPiece(
    id: 'line_5_v',
    cells: <CellOffset>[
      CellOffset(0, 0),
      CellOffset(1, 0),
      CellOffset(2, 0),
      CellOffset(3, 0),
      CellOffset(4, 0),
    ],
  ),
  BlockPiece(
    id: 'plus_5',
    cells: <CellOffset>[
      CellOffset(0, 1),
      CellOffset(1, 0),
      CellOffset(1, 1),
      CellOffset(1, 2),
      CellOffset(2, 1),
    ],
  ),
  BlockPiece(
    id: 'u_5',
    cells: <CellOffset>[
      CellOffset(0, 0),
      CellOffset(1, 0),
      CellOffset(1, 1),
      CellOffset(1, 2),
      CellOffset(0, 2),
    ],
  ),
  BlockPiece(
    id: 'step_5',
    cells: <CellOffset>[
      CellOffset(0, 0),
      CellOffset(1, 0),
      CellOffset(1, 1),
      CellOffset(2, 1),
      CellOffset(2, 2),
    ],
  ),
  BlockPiece(
    id: 'hook_5',
    cells: <CellOffset>[
      CellOffset(0, 0),
      CellOffset(1, 0),
      CellOffset(2, 0),
      CellOffset(2, 1),
      CellOffset(1, 1),
    ],
  ),
];

const List<BlockPiece> specialBlockCatalog = <BlockPiece>[
  BlockPiece(
    id: 'special_bomb',
    cells: <CellOffset>[CellOffset(0, 0)],
    power: PiecePower.bomb,
  ),
  BlockPiece(
    id: 'special_row',
    cells: <CellOffset>[CellOffset(0, 0)],
    power: PiecePower.rowClear,
  ),
  BlockPiece(
    id: 'special_column',
    cells: <CellOffset>[CellOffset(0, 0)],
    power: PiecePower.columnClear,
  ),
  BlockPiece(
    id: 'special_wild',
    cells: <CellOffset>[CellOffset(0, 0)],
    power: PiecePower.wild,
  ),
];
