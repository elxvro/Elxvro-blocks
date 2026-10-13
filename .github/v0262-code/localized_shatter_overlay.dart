import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/game_theme.dart';

/// Localized image breakup: fragments originate only in confirmed cleared
/// cells, never from unrelated positions of the board.
class LocalizedShatterOverlay extends StatelessWidget {
  const LocalizedShatterOverlay({
    super.key,
    required this.material,
    required this.cells,
    required this.boardSize,
    required this.progress,
    this.lowFx = false,
  });

  final ThemeMaterial material;
  final Set<int> cells;
  final int boardSize;
  final double progress;
  final bool lowFx;

  @override
  Widget build(BuildContext context) {
    if (cells.isEmpty || boardSize <= 0 || progress >= 1) {
      return const SizedBox.shrink();
    }
    final ordered = cells.toList()..sort();
    final limit = lowFx ? 18 : 42;
    final step = math.max(1, (ordered.length / limit).ceil());
    return IgnorePointer(
      child: LayoutBuilder(builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        if (!w.isFinite || !h.isFinite || w <= 0 || h <= 0) {
          return const SizedBox.shrink();
        }
        final cw = w / boardSize;
        final ch = h / boardSize;
        final t = Curves.easeOutCubic.transform(progress.clamp(0.0, 1.0).toDouble());
        final alpha = math.pow(1 - progress, 1.15).toDouble().clamp(0.0, 1.0);
        final particlesPerCell = lowFx ? 1 : 2;
        return ClipRect(child: Stack(
          clipBehavior: Clip.hardEdge,
          children: <Widget>[
            for (var n = 0; n < ordered.length; n += step)
              for (var i = 0; i < particlesPerCell; i++)
                _shard(index: ordered[n], ordinal: n, shard: i,
                    cellWidth: cw, cellHeight: ch,
                    progress: t, opacity: alpha),
          ],
        ));
      }),
    );
  }

  Widget _shard({
    required int index,
    required int ordinal,
    required int shard,
    required double cellWidth,
    required double cellHeight,
    required double progress,
    required double opacity,
  }) {
    final row = index ~/ boardSize;
    final col = index % boardSize;
    final angle = ((ordinal * 79 + shard * 137) % 360) * math.pi / 180;
    final distance = math.min(cellWidth, cellHeight) *
        (0.18 + (ordinal % 3) * 0.08) * progress;
    final x = (col + 0.5) * cellWidth + math.cos(angle) * distance;
    final y = (row + 0.5) * cellHeight +
        math.sin(angle) * distance +
        cellHeight * 0.30 * progress * progress;
    final side = math.min(cellWidth, cellHeight) *
        (0.15 + (ordinal % 3) * 0.045);
    final spriteIndex = (ordinal + shard * 3) % 5;
    return Positioned(
      left: x - side / 2,
      top: y - side / 2,
      width: side,
      height: side,
      child: Opacity(
        opacity: opacity,
        child: Transform.rotate(
          angle: (shard.isEven ? 1 : -1) * progress * (2.2 + shard),
          child: Image.asset(
            'assets/images/material_shards/${material.name}_$spriteIndex.webp',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.low,
            gaplessPlayback: true,
          ),
        ),
      ),
    );
  }
}
