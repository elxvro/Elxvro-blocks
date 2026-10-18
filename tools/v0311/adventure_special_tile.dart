import 'package:flutter/material.dart';
import '../game/adventure_quest.dart';
import '../game/adventure_specials.dart';
import '../models/game_theme.dart';
import 'themed_block_tile.dart';

/// Special stones retain the player's chosen block material and tint.
class AdventureSpecialTile extends StatelessWidget {
  const AdventureSpecialTile({super.key, required this.code, required this.theme,
    required this.base, required this.accent});
  final int code;
  final GameThemeData theme;
  final Color base;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final icon = switch (code) {
      AdventureSpecial.ice => Icons.ac_unit_rounded,
      AdventureSpecial.crystal => Icons.diamond_rounded,
      AdventureSpecial.stone => Icons.hexagon_rounded,
      AdventureStone.pulse => Icons.bolt_rounded,
      AdventureStone.ember => Icons.local_fire_department_rounded,
      AdventureStone.shield => Icons.shield_rounded,
      _ => Icons.auto_awesome_rounded,
    };
    final hue = switch (code) {
      AdventureSpecial.ice => const Color(0xFF9BEAFF),
      AdventureSpecial.crystal => const Color(0xFFEEA0FF),
      AdventureSpecial.stone => const Color(0xFFC2CBDE),
      AdventureStone.pulse => const Color(0xFF8CFFEF),
      AdventureStone.ember => const Color(0xFFFFB46E),
      AdventureStone.shield => const Color(0xFFA5F0AB),
      _ => accent,
    };
    final matched = Color.lerp(hue, accent, .37)!;
    return Stack(fit: StackFit.expand, children: <Widget>[
      Padding(padding: const EdgeInsets.all(.25),
        child: ThemedBlockTile(material: theme.material,
          base: Color.lerp(base, matched, .38)!, accent: matched)),
      Container(margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: matched.withValues(alpha: .86), width: 1),
        )),
      Center(child: Icon(icon, size: 17, color: Colors.white,
        shadows: <Shadow>[Shadow(color: matched, blurRadius: 9)])),
    ]);
  }
}
