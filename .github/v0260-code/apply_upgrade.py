from pathlib import Path
import sys

app = Path(sys.argv[1])

def patch(path, needle, replacement):
    f = app / path
    data = f.read_text(encoding="utf-8")
    count = data.count(needle)
    if count != 1:
        raise RuntimeError(f"Upgrade anchor: {path} ({count} occurrences)")
    f.write_text(data.replace(needle, replacement, 1), encoding="utf-8")

patch("pubspec.yaml", "version: 0.25.0+49", "version: 0.26.0+50")
patch("test/real_material_audio_test.dart", "version: 0.25.0+49", "version: 0.26.0+50")
patch("test/v0240_features_test.dart", "version: 0.25.0+49", "version: 0.26.0+50")
patch("lib/screens/home_screen.dart", "badge: 'v0.25.0'", "badge: 'v0.26.0'")
patch("lib/screens/settings_screen.dart", "'v0.25.0  •  ", "'v0.26.0  •  ")
patch("lib/screens/game_screen.dart",
      "import '../widgets/themed_block_tile.dart';",
      "import '../widgets/themed_block_tile.dart';\nimport '../widgets/material_fragment_fx.dart';")

patch("lib/screens/game_screen.dart",
"""                        child: ThemedBlockTile(
                          material: theme.material,
                          base: theme.block,
                          accent: theme.blockAccent,
                          flash: flashed ? flashAlpha : 0,
                        ),""",
"""                        child: Stack(
                          clipBehavior: Clip.none,
                          fit: StackFit.expand,
                          children: <Widget>[
                            ThemedBlockTile(
                              material: theme.material,
                              base: theme.block,
                              accent: theme.blockAccent,
                              flash: flashed ? flashAlpha : 0,
                            ),
                            MaterialFragmentFx(
                              material: theme.material,
                              trailing: false,
                            ),
                          ],
                        ),""")

patch("lib/screens/game_screen.dart",
"""        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            PiecePreview(
              piece: currentPiece,
              color: theme.block,
              accent: theme.blockAccent,
              material: theme.material,
              cellSize: 28,
            ),""",
"""        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            PiecePreview(
              piece: currentPiece,
              color: theme.block,
              accent: theme.blockAccent,
              material: theme.material,
              cellSize: 28,
            ),
            Positioned.fill(
              child: MaterialFragmentFx(material: theme.material),
            ),""")

test = app / "test/v0260_visual_assets_test.dart"
test.write_text("""import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:elxvro_blocks/models/game_theme.dart';
import 'package:elxvro_blocks/widgets/themed_block_tile.dart';

void main() {
  test('Every material has a raster tile and five fragment images', () {
    for (final material in ThemeMaterial.values) {
      expect(File(ThemedBlockTile.artworkPath(material)).existsSync(), isTrue);
      for (var i = 0; i < 5; i++) {
        expect(File('assets/images/material_shards/\${material.name}_$i.webp').existsSync(), isTrue);
      }
    }
  });
}
""", encoding="utf-8")
print("v0.26.0 image surface + drag fragment/placement burst wired")
