#!/usr/bin/env python3
"""Build-time migration from the shipped 0.31.4 Adventure map to action combat.

Only the Adventure entry point and new Adventure code are changed.
Classic mode, purchased themes, AppState and existing saves stay as-is.
"""
from pathlib import Path
import sys

root=Path(sys.argv[1] if len(sys.argv)>1 else 'extracted/elxvro-blocks')

def once(text,old,new,label):
    amount=text.count(old)
    if amount!=1:
        raise RuntimeError(f'{label}: expected one anchor, got {amount}')
    return text.replace(old,new,1)

mapfile=root/'lib/screens/adventure_screen.dart'
s=mapfile.read_text()
s=once(s,"import '../models/adventure_level.dart';\n",'','unused legacy level import')
s=once(s,"import 'falling_blocks_screen.dart';",
       "import 'adventure_combat_screen.dart';",'action route import')
s=once(s,'            AdventureWorldBackdrop(world: world, theme: theme),',
       '            if (_selectedWorld == null) const ColoredBox(color: Color(0xFF071329))\n'
       '            else AdventureWorldBackdrop(world: world, theme: theme),',
       'flat world-menu background')
s=once(s,'builder: (_) => FallingBlocksScreen(\n'
         '                    appState: app, adventureLevel: adventureLevelFor(number))',
       'builder: (_) => AdventureCombatScreen(\n'
       '                    appState: app, level: number)',
       'replace falling blocks with monster combat')
s=once(s,"tr ? 'Her dünyanın kendine özel taşları ve görevleri var'\n"
         "             : 'Each world has its own stones and missions'",
       "tr ? 'Altı dünyada farklı canavarlar ve özel yetenekler'\n"
       "             : 'Six worlds with unique monsters and abilities'",
       'world map text')
s=once(s,'Color.lerp(const Color(0xFF101A35), tone,\n'
         '                      open ? .24 : .04)!,\n'
         '                    const Color(0xF20B142B),',
       'Color.lerp(const Color(0xB0101A35), tone,\n'
       '                      open ? .14 : .03)!,\n'
       '                    const Color(0x88121B36),',
       'transparent glass level cards')
mapfile.write_text(s)

pub=root/'pubspec.yaml'
s=pub.read_text()
s=once(s,'version: 0.31.4+80','version: 0.32.0+81','version')
s=once(s,'    - assets/images/adventure_worlds/\n',
       '    - assets/images/adventure_worlds/\n'
       '    - assets/images/adventure_battles/\n','combat art manifest')
pub.write_text(s)

for test in (root/'test').glob('*.dart'):
    t=test.read_text()
    result=t.replace('version: 0.31.4+80','version: 0.32.0+81')
    if t!=result:test.write_text(result)

print('Action Adventure v0.32.0: 60 stage routes migrated; player saves retained.')
