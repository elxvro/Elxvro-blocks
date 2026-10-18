/// Adventure-only stone rules. Other game modes do not import these helpers.
class AdventureStone {
  static const int pulse = 10;
  static const int ember = 11;
  static const int shield = 12;

  /// Receives a 0..11 roll. `null` means an ordinary themed block.
  static int? forWorld(int world, int roll) {
    if (roll < 0 || roll > 11) return null;
    if (roll != 0 && roll != 1) return null;
    return switch (world) {
      0 => pulse,
      1 => roll == 0 ? shield : null,
      2 => roll == 0 ? pulse : null,
      3 => ember,
      4 => roll == 0 ? shield : pulse,
      _ => roll == 0 ? ember : pulse,
    };
  }

  static int bonusScore(Iterable<int> cleared) {
    var score = 0;
    for (final code in cleared) {
      if (code == pulse) score += 90;
      if (code == ember) score += 250;
      if (code == shield) score += 60;
    }
    return score;
  }

  static int shields(Iterable<int> cleared) =>
      cleared.where((code) => code == shield).length;

  /// Pulse stones in completed lines remove neighboring existing blocks.
  /// The fully cleared rows are excluded, since the caller will remove them.
  static int discharge(List<List<int>> board, List<int> clearedRows) {
    if (board.isEmpty || board.first.isEmpty || clearedRows.isEmpty) return 0;
    final removed = clearedRows.toSet();
    final impacts = <int>{};
    final cols = board.first.length;
    for (final row in clearedRows) {
      if (row < 0 || row >= board.length) continue;
      for (var col = 0; col < cols; col++) {
        if (board[row][col] != pulse) continue;
        for (final r in <int>[row - 1, row + 1]) {
          if (r < 0 || r >= board.length || removed.contains(r)) continue;
          for (final c in <int>[col - 1, col, col + 1]) {
            if (c >= 0 && c < cols && board[r][c] >= 0) {
              impacts.add(r * cols + c);
            }
          }
        }
      }
    }
    for (final index in impacts) {
      board[index ~/ cols][index % cols] = -1;
    }
    return impacts.length;
  }
}
