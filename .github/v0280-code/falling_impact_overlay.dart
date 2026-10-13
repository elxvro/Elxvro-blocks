import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/game_theme.dart';

/// Sprite-based bursts attached to actual falling-block contact/clear cells.
/// Limited particle count, clipped to the well, no landing ghost.
class FallingImpactOverlay extends StatelessWidget {
  const FallingImpactOverlay({
    super.key,
    required this.progress,
    required this.cells,
    required this.material,
    required this.accent,
    required this.cleared,
    this.lowFx = false,
  });
  final Animation<double> progress;
  final Set<int> cells;
  final ThemeMaterial material;
  final Color accent;
  final bool cleared;
  final bool lowFx;

  @override
  Widget build(BuildContext context) {
    if (cells.isEmpty) return const SizedBox.shrink();
    final targets = cells.toList()..sort();
    final maxCells = lowFx ? 12 : 32;
    final skip = math.max(1, (targets.length / maxCells).ceil());
    return IgnorePointer(child: AnimatedBuilder(
      animation: progress,
      builder: (context, _) => LayoutBuilder(
        builder: (context, size) {
          if (!size.maxWidth.isFinite || !size.maxHeight.isFinite) {
            return const SizedBox.shrink();
          }
          final cellW = size.maxWidth / 10;
          final cellH = size.maxHeight / 20;
          final t = Curves.easeOutCubic.transform(progress.value);
          final alpha = (1 - t).clamp(0.0, 1.0).toDouble();
          return ClipRect(child: Stack(clipBehavior: Clip.hardEdge, children: <Widget>[
            for (var n = 0; n < targets.length; n += skip)
              for (var shard = 0; shard < (lowFx ? 2 : (cleared ? 5 : 3)); shard++)
                _fragment(targets[n], n, shard, t, alpha, cellW, cellH),
          ]));
        },
      ),
    ));
  }

  Widget _fragment(int cell, int ordinal, int shard, double t,
      double alpha, double cellW, double cellH) {
    final row = cell ~/ 10;
    final col = cell % 10;
    final angle = (ordinal * 79 + shard * 91) * math.pi / 180;
    final range = math.min(cellW, cellH) * (cleared ? 1.65 : 0.83);
    final distance = range * t * (0.60 + (shard % 3) * .19);
    final gravity = math.min(cellW, cellH) * (cleared ? 2.0 : 1.05) * t * t;
    final x = (col + .5) * cellW + math.cos(angle) * distance;
    final y = (row + .5) * cellH + math.sin(angle) * distance + gravity;
    final side = math.min(cellW, cellH) * (cleared ? .22 : .16);
    return Positioned(
      left: x - side / 2,
      top: y - side / 2,
      width: side,
      height: side,
      child: Opacity(
        opacity: (alpha * (shard.isEven ? .98 : .78)).clamp(0.0, 1.0),
        child: Transform.rotate(
          angle: (shard.isEven ? 1 : -1) * t * (2.0 + shard),
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(accent, BlendMode.modulate),
            child: Image.asset(
              'assets/images/material_shards/${material.name}_${shard % 5}.webp',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.low,
            ),
          ),
        ),
      ),
    );
  }
}
