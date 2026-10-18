/// Pure, deterministic planning for the rising adventure board.
/// The currently falling piece never moves when the stack rises.
enum AdventureRiseOutcome { rise, lockActivePiece, overflow }

class AdventureRiseDecision {
  const AdventureRiseDecision(this.outcome, this.board);
  final AdventureRiseOutcome outcome;
  final List<List<int>>? board;
}

AdventureRiseDecision planAdventureRise({
  required List<List<int>> board,
  required List<(int, int)> activeCells,
  required int activeRow,
  required int activeCol,
  required List<int> incomingRow,
}) {
  if (board.isEmpty || board.first.isEmpty ||
      board.any((row) => row.length != board.first.length) ||
      incomingRow.length != board.first.length) {
    throw ArgumentError('Rising board dimensions must match.');
  }
  final height = board.length;
  final width = board.first.length;
  if (board.first.any((cell) => cell >= 0)) {
    return const AdventureRiseDecision(AdventureRiseOutcome.overflow, null);
  }

  final candidate = <List<int>>[
    for (var row = 1; row < height; row++) List<int>.from(board[row]),
    List<int>.from(incomingRow),
  ];
  for (final (dr, dc) in activeCells) {
    final row = activeRow + dr;
    final col = activeCol + dc;
    if (row >= 0 && row < height && col >= 0 && col < width &&
        candidate[row][col] >= 0) {
      return const AdventureRiseDecision(
        AdventureRiseOutcome.lockActivePiece, null,
      );
    }
  }
  return AdventureRiseDecision(AdventureRiseOutcome.rise, candidate);
}
