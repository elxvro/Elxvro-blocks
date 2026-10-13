import 'package:flutter/material.dart';
import '../models/game_theme.dart';

/// Theme-colored pre-rendered surfaces. Materials are bitmap assets, not
/// painted Canvas faces; the game palette determines each tile's final hue.
class ThemedBlockTile extends StatelessWidget {
  const ThemedBlockTile({
    super.key,
    required this.material,
    required this.base,
    required this.accent,
    this.flash = 0,
  });

  final ThemeMaterial material;
  final Color base;
  final Color accent;
  final double flash;

  static String artworkPath(ThemeMaterial material) =>
      'assets/images/material_tiles/palette_${material.name}.webp';

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(base, BlendMode.modulate),
            child: Image.asset(
              artworkPath(material),
              fit: BoxFit.fill,
              filterQuality: FilterQuality.medium,
              gaplessPlayback: true,
              errorBuilder: (context, error, stack) => DecoratedBox(
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: accent.withValues(alpha: 0.25),
              width: 0.7,
            ),
          ),
        ),
        if(flash>0)
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: (flash * .34).clamp(0.0, .65),
              ),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: accent.withValues(
                  alpha: (flash * .75).clamp(0.0, 1.0),
                ),
                width: 1.3,
              ),
            ),
          ),
      ],
    ),
  );
}
