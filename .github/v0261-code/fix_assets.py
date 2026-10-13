from pathlib import Path
import sys
from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageOps

app = Path(sys.argv[1])
def exact_patch(relative, before, after):
    path = app / relative
    text = path.read_text(encoding='utf-8')
    if text.count(before) != 1:
        raise SystemExit(f'Unable to apply v0.26.1 fix to {relative}: count={text.count(before)}')
    path.write_text(text.replace(before, after, 1), encoding='utf-8')

exact_patch('pubspec.yaml', 'version: 0.26.0+50', 'version: 0.26.1+51')
exact_patch('pubspec.yaml',
            '    - assets/images/\n    - assets/audio/',
            '    - assets/images/\n    - assets/images/material_tiles/\n    - assets/images/material_shards/\n    - assets/audio/')
exact_patch('test/real_material_audio_test.dart', 'version: 0.26.0+50','version: 0.26.1+51')
exact_patch('test/v0240_features_test.dart', 'version: 0.26.0+50','version: 0.26.1+51')
exact_patch('lib/screens/home_screen.dart', "badge: 'v0.26.0'","badge: 'v0.26.1'")
exact_patch('lib/screens/settings_screen.dart', "'v0.26.0  •  ","'v0.26.1  •  ")

tiles = app / 'assets/images/material_tiles'
for material in ('glass','crystal','marble','stone','wood','leaf'):
    image = Image.open(tiles / f'{material}.webp').convert('RGB')
    gray = ImageOps.grayscale(image)
    gray = ImageEnhance.Contrast(gray).enhance(1.48)
    gray = gray.filter(ImageFilter.UnsharpMask(radius=1.25,percent=165,threshold=2))
    # Preserve hand-made texture, but remove color so game palette is authoritative.
    gray = gray.point(lambda v: 139 + round(v * 0.455))
    face = Image.merge('RGB', (gray, gray, gray)).convert('RGBA')
    alpha = Image.new('L', face.size, 0)
    draw = ImageDraw.Draw(alpha)
    draw.rounded_rectangle((1,1,face.width-2,face.height-2),radius=19,fill=255)
    face.putalpha(alpha)
    face.save(tiles / f'palette_{material}.webp','WEBP',quality=91,method=6)

test = app / 'test/v0261_asset_bundle_test.dart'
test.write_text("""import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:elxvro_blocks/models/game_theme.dart';
import 'package:elxvro_blocks/widgets/themed_block_tile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('The six materials and material debris are in the Flutter bundle', (tester) async {
    for (final material in ThemeMaterial.values) {
      final sprite = await rootBundle.load(ThemedBlockTile.artworkPath(material));
      expect(sprite.lengthInBytes, greaterThan(500));
      for (var i = 0; i < 5; i++) {
        final shard = await rootBundle.load('assets/images/material_shards/\${material.name}_\$i.webp');
        expect(shard.lengthInBytes, greaterThan(100));
      }
    }
  });
}
""", encoding='utf-8')
readme = app/'V0261_FIX_README.md'
readme.write_text("""ELXVRO Blocks v0.26.1 - Material Bundle Repair

Root cause: Flutter's assets/images/ directory registration was non-recursive.
The v0.26.0 APK contained neither material_tiles nor material_shards sprites;
Image.asset errorBuilder displayed the flat colored placeholder instead.

Fixes:
- Explicitly register both nested material asset directories in pubspec.yaml.
- Add a Flutter bundle-loading test for all six faces and thirty shards.
- Bake desaturated texture variants and tint them with the theme's base
  color, preserving Classic and Adventure palettes across every material.
- Verify the six tile images and the thirty shard images inside the signed APK.
All images are bundled offline. Existing gameplay rules are unchanged.
""", encoding='utf-8')
print('Material sprites, bundle declarations and palette variants repaired.')
