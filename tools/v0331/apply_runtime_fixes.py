#!/usr/bin/env python3
"""Fix runtime black board and Adventure's indefinite loading state."""
from pathlib import Path
import sys
root = Path(sys.argv[1] if len(sys.argv) > 1 else 'extracted/elxvro-blocks')

def once(s, old, new, label):
    n=s.count(old)
    if n != 1: raise RuntimeError(f'{label}: expected exactly one anchor, got {n}')
    return s.replace(old,new,1)

p=root/'lib/screens/falling_blocks_screen.dart'
s=p.read_text()
s=once(s,"  void _reset() {\n    _timer?.cancel();","  void _reset() {\n    _timer?.cancel();\n    // Initialize the full 20x10 board before GridView renders any cell.\n    _board = List<List<int>>.generate(\n      _rows, (_) => List<int>.filled(_cols, -1), growable: true);",'board init')
p.write_text(s)

p=root/'lib/screens/animal_adventure_screen.dart'
s=p.read_text()
s=once(s,'  bool _loading = true;\n  @override','  bool _loading = true;\n  bool _loadFailed = false;\n  @override','loading state')
s=once(s,"""  Future<void> _load() async {
    await _progress.load();
    if (mounted) setState(() => _loading = false);
  }""","""  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _loadFailed = false; });
    try {
      await _progress.load().timeout(const Duration(seconds: 8));
      if (mounted) setState(() { _loading = false; _loadFailed = false; });
    } catch (error) {
      debugPrint('Animal Adventure progress loading failed: $error');
      if (mounted) setState(() { _loading = false; _loadFailed = true; });
    }
  }""",'timeout and error state')
s=once(s,"""          Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator())
            : GridView.builder(""","""          Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _loadFailed
              ? Center(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(Icons.error_outline_rounded, size: 35),
                    const SizedBox(height: 10),
                    Text(tr ? 'Bölümler yüklenemedi' : 'Could not load levels'),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(tr ? 'TEKRAR DENE' : 'RETRY'),
                    ),
                  ],
                ))
              : GridView.builder(""",'retry display')
p.write_text(s)

p=root/'lib/services/animal_match_progress.dart'
s=p.read_text()
s=once(s,"""    unlocked = (prefs.getInt(_unlockedKey) ?? 1).clamp(1, 100).toInt();
    for (final s in prefs.getStringList(_starsKey) ?? <String>[]) {""","""    // Ignore invalid pref types; keep previously saved data on disk.
    final storedUnlocked = prefs.get(_unlockedKey);
    var nextUnlocked = (storedUnlocked is int ? storedUnlocked : 1)
        .clamp(1, 100).toInt();
    final nextStars = <int, int>{};
    final storedStars = prefs.get(_starsKey);
    for (final s in storedStars is List<String> ? storedStars : <String>[]) {""",'safe stored types')
s=once(s,"""        stars[level] = count;
      }
    }
    for (final raw in prefs.getStringList(_completedKey) ?? <String>[]) {""","""        nextStars[level] = count;
      }
    }
    final nextCompleted = <int>{};
    final storedCompleted = prefs.get(_completedKey);
    for (final raw in storedCompleted is List<String>
        ? storedCompleted : <String>[]) {""",'temporary progress')
s=once(s,"""      if (level != null && level >= 1 && level <= 100) completed.add(level);
    }
    if (completed.isNotEmpty) {
      final inferred = completed.reduce((a, b) => a > b ? a : b);
      if (inferred >= unlocked) unlocked = (inferred + 1).clamp(1, 100).toInt();
    }
  }""","""      if (level != null && level >= 1 && level <= 100) {
        nextCompleted.add(level);
      }
    }
    if (nextCompleted.isNotEmpty) {
      final inferred = nextCompleted.reduce((a, b) => a > b ? a : b);
      if (inferred >= nextUnlocked) {
        nextUnlocked = (inferred + 1).clamp(1, 100).toInt();
      }
    }
    // Replace in-memory progress only after successful disk reads.
    unlocked = nextUnlocked;
    stars..clear()..addAll(nextStars);
    completed..clear()..addAll(nextCompleted);
  }""",'atomic memory update')
p.write_text(s)

p=root/'pubspec.yaml'
p.write_text(once(p.read_text(),'version: 0.33.0+83','version: 0.33.1+84','version'))
for p in (root/'test').glob('*.dart'):
    old=p.read_text()
    new=old.replace('0.33.0+83','0.33.1+84')
    if old!=new: p.write_text(new)
print('Applied v0.33.1 runtime screen fixes')
