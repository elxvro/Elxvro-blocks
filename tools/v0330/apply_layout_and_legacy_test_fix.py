#!/usr/bin/env python3
"""Correct small-screen Adventure header layout and legacy-theme test assumptions."""
from pathlib import Path
import sys

root = Path(sys.argv[1] if len(sys.argv) > 1 else "extracted/elxvro-blocks")
p = root / "lib/screens/animal_adventure_screen.dart"
s = p.read_text()

old = """                      Text(tr ? '100 BÖLÜM · HAYVAN EŞLEŞTİRME'
                              : '100 LEVELS · ANIMAL MATCH',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                          letterSpacing: .6)),"""
new = """                      Expanded(child: Text(
                        tr ? '100 BÖLÜM · HAYVAN EŞLEŞTİRME'
                           : '100 LEVELS · ANIMAL MATCH',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11,
                          fontWeight: FontWeight.w800, letterSpacing: .6))),
                      const SizedBox(width: 8),"""
if s.count(old) != 1:
    raise RuntimeError("Expected exactly one non-responsive progress header")
s = s.replace(old, new, 1)
# Prevent unexpected horizontal overflow when system font scales up.
old = """              Expanded(child: Text(tr ? 'MACERA' : 'ADVENTURE',
                textAlign: TextAlign.center, style: TextStyle("""
new = """              Expanded(child: Text(tr ? 'MACERA' : 'ADVENTURE',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center, style: TextStyle("""
if s.count(old) != 1:
    raise RuntimeError("Expected exactly one map header")
s = s.replace(old, new, 1)
p.write_text(s)

p = root / "test/animal_match_progress_test.dart"
s = p.read_text()
old = """    expect(state.isThemeUnlocked('obsidian'),isTrue);"""
new = """    // A retired Adventure save with 4 completed levels must not
    // grant a 15-level theme; the new Adventure progress stays separate.
    expect(state.isThemeUnlocked('obsidian'),isFalse);"""
if s.count(old) != 1:
    raise RuntimeError("Expected exactly one old theme eligibility assertion")
p.write_text(s.replace(old, new, 1))
print("Responsive 100-level map and legacy save expectations repaired")
