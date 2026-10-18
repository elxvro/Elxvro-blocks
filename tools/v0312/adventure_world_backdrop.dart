import 'package:flutter/material.dart';
import '../models/game_theme.dart';

/// Illustrated world scenes exclusively for Adventure. Existing theme remains active.
class AdventureWorldBackdrop extends StatelessWidget {
  const AdventureWorldBackdrop({super.key, required this.world, required this.theme});

  final int world;
  final GameThemeData theme;

  static String assetFor(int world) =>
      'assets/images/adventure_worlds/world_' +
      world.clamp(0, 5).toString() + '.webp';

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: RepaintBoundary(
          child: Stack(fit: StackFit.expand, children: <Widget>[
            Image.asset(
              assetFor(world),
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) => ColoredBox(color: theme.backgroundBottom),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    theme.backgroundTop.withValues(alpha: 0.34),
                    theme.backgroundBottom.withValues(alpha: 0.40),
                    theme.backgroundBottom.withValues(alpha: 0.73),
                  ],
                  stops: const <double>[0, 0.48, 1],
                ),
              ),
            ),
            ColoredBox(color: theme.blockAccent.withValues(alpha: 0.035)),
          ]),
        ),
      );
}
