#!/usr/bin/env python3
"""Integrate illustrated Adventure-only scenery over assembled v0.31.1 source."""
from pathlib import Path
import sys
root = Path(sys.argv[1] if len(sys.argv)>1 else 'extracted/elxvro-blocks')
def replace_once(data, old, new, label):
    count = data.count(old)
    if count != 1:
        raise RuntimeError(f'{label}: expected one anchor, got {count}')
    return data.replace(old, new, 1)

map_file=root/'lib/screens/adventure_screen.dart'
screen=map_file.read_text()
screen=replace_once(
    screen,
    "import '../widgets/premium_background.dart';",
    "import '../widgets/premium_background.dart';\nimport '../widgets/adventure_world_backdrop.dart';",
    'map scene import',
)
screen=replace_once(
    screen,
    '''            child: SafeArea(
              child: Column(children: <Widget>[''',
    '''            child: Stack(fit: StackFit.expand, children: <Widget>[
              AdventureWorldBackdrop(world: world, theme: theme),
              SafeArea(
              child: Column(children: <Widget>[''',
    'scene behind world map',
)
screen=replace_once(
    screen,
    '''              ]),
            ),
          ),
        );
      },
    );
  }
}''',
    '''              ]),
            ),
            ]),
          ),
        );
      },
    );
  }
}''',
    'world map stack closure',
)
screen=replace_once(
    screen,
    '''                                  theme.board,
                                ],
                              ),
                            ),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start,''',
    '''                                  theme.board,
                                ],
                              ),
                              image: DecorationImage(
                                image: ResizeImage(
                                  AssetImage(AdventureWorldBackdrop.assetFor(index)),
                                  width: 288,
                                ),
                                fit: BoxFit.cover,
                                colorFilter: ColorFilter.mode(
                                  theme.board.withValues(alpha: selected ? .42 : .62),
                                  BlendMode.srcOver,
                                ),
                              ),
                            ),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start,''',
    'world card artwork',
)
map_file.write_text(screen)

pub = root/'pubspec.yaml'
raw=pub.read_text()
assert raw.count('version: 0.31.1+77')==1, 'Unexpected source version'
assert raw.count('    - assets/images/\n')==1, 'Flutter assets anchor changed'
pub.write_text(raw.replace('version: 0.31.1+77', 'version: 0.31.2+78',1).replace('    - assets/images/\n','    - assets/images/\n    - assets/images/adventure_worlds/\n',1))
for test in (root/'test').glob('*.dart'):
    old=test.read_text()
    newer=old.replace('0.31.1+77','0.31.2+78')
    if newer!=old: test.write_text(newer)
print('Illustrated Adventure assets and version 0.31.2+78 configured.')
