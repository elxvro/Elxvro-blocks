import 'package:flutter/material.dart';

import '../models/block_piece.dart';
import '../models/game_theme.dart';
import 'themed_block_tile.dart';

class PiecePreview extends StatelessWidget {
  const PiecePreview({
    super.key,
    required this.piece,
    required this.color,
    required this.accent,
    required this.material,
    this.cellSize = 24,
    this.dimmed = false,
  });

  final BlockPiece piece;
  final Color color;
  final Color accent;
  final ThemeMaterial material;
  final double cellSize;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: dimmed ? 0.18 : 1,
      child: SizedBox(
        width: piece.cols * cellSize,
        height: piece.rows * cellSize,
        child: Stack(
          children: piece.cells.map((cell) {
            return Positioned(
              left: cell.col * cellSize,
              top: cell.row * cellSize,
              child: SizedBox(
                width: cellSize - 2,
                height: cellSize - 2,
                child: ThemedBlockTile(
                  material: material,
                  base: color,
                  accent: accent,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
