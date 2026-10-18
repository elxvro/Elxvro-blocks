#!/usr/bin/env python3
"""Patch the assembled v0.29.9 source with Classic save integrity fixes."""
from pathlib import Path
import sys

root = Path(sys.argv[1] if len(sys.argv) > 1 else 'extracted/elxvro-blocks')
screen_path = root / 'lib/screens/game_screen.dart'
source = screen_path.read_text()

def replace(old, new, name):
    global source
    count = source.count(old)
    if count != 1:
        raise RuntimeError(f'{name}: expected one anchor, found {count}')
    source = source.replace(old, new, 1)

replace("import '../game/combo_rush_rules.dart';",
        "import '../game/combo_rush_rules.dart';\nimport '../game/classic_session_store.dart';",
        'new store import')
start = source.index("  static const String _sessionBoardKey = 'active_game_board_v0161';")
end = source.index('  final BoardEngine _engine', start)
source = source[:start] + source[end:]
replace('  final BoardEngine _engine = BoardEngine(size: _boardSize);',
        '  final BoardEngine _engine = BoardEngine(size: _boardSize);\n'
        '  final ClassicSessionStore _classicSessionStore = ClassicSessionStore();',
        'store instance')
replace('  bool _resumePausePending = false;',
        '  bool _resumePausePending = false;\n'
        '  bool _restoringClassicSession = false;', 'restore guard')
replace('    if (widget.adventureLevel == null && widget.mode == GameMode.classic) {\n'
        '      WidgetsBinding.instance.addPostFrameCallback((_) {',
        '    if (widget.adventureLevel == null && widget.mode == GameMode.classic) {\n'
        '      _restoringClassicSession = true;\n'
        '      WidgetsBinding.instance.addPostFrameCallback((_) {',
        'protect initial restore')

for guard in [
    'if (_finishing || _paused || _resumePausePending || _toolRequestPending) return;',
    'if (_finishing || _paused || _toolRequestPending) return;',
]:
    if guard not in source:
        raise RuntimeError('Missing expected input lock: ' + guard)
    source = source.replace(
        guard, guard.replace(') return;', ' || _restoringClassicSession) return;'))

start = source.index('  Future<void> _saveClassicGame() async {')
end = source.index('  void _resetGame() {', start)
source = source[:start] + '''  Future<void> _saveClassicGame() async {
    if (widget.adventureLevel != null ||
        widget.mode != GameMode.classic ||
        _finishing || _restoringClassicSession) {
      return;
    }
    // Capture the entire session before the first await.
    final snapshot = ClassicSessionSnapshot(
      board: _engine.snapshot().expand((row) => row)
          .map((filled) => filled ? '1' : '0').join(),
      pieces: _pieces.map((piece) => piece?.id ?? '-').toList(),
      score: _score,
      combo: _combo,
      bestCombo: _bestComboThisGame,
      clearedLines: _clearedLinesThisGame,
      placedBlocks: _placedBlocksThisGame,
      perfectClears: _perfectClearsThisGame,
    );
    try {
      await _classicSessionStore.save(snapshot);
    } catch (error) {
      debugPrint('ELXVRO active game save failed: $error');
    }
  }

  Future<void> _restoreSavedClassicGame() async {
    if (widget.adventureLevel != null ||
        widget.mode != GameMode.classic || _finishing) {
      _restoringClassicSession = false;
      return;
    }
    try {
      final snapshot = await _classicSessionStore.load();
      if (snapshot == null) return;
      // Unknown pieces must never silently restore as an empty tray slot.
      if (snapshot.pieces.any((id) => id != '-' && _pieceForId(id) == null) ||
          snapshot.pieces.every((id) => id == '-')) {
        await _classicSessionStore.clear();
        return;
      }
      final board = snapshot.board;
      final grid = List<List<bool>>.generate(
        _boardSize,
        (row) => List<bool>.generate(
          _boardSize, (col) => board[row * _boardSize + col] == '1',
        ),
      );
      final restoredPieces = snapshot.pieces.map(_pieceForId).toList();
      if (!mounted) return;
      setState(() {
        _engine.restore(grid);
        _pieces = List<BlockPiece?>.from(restoredPieces);
        _score = snapshot.score;
        _combo = snapshot.combo;
        _bestComboThisGame = snapshot.bestCombo;
        _clearedLinesThisGame = snapshot.clearedLines;
        _placedBlocksThisGame = snapshot.placedBlocks;
        _perfectClearsThisGame = snapshot.perfectClears;
        _recordCelebratedInRound = _score > _modeBest;
        _undoSnapshot = null;
        _hoverRow = null;
        _hoverCol = null;
        _hoverPieceIndex = null;
      });
      _showEventBanner(AppStrings.current.f('OYUNA DEVAM EDİLDİ', 'GAME RESUMED'));
    } catch (error) {
      debugPrint('ELXVRO active game restore failed: $error');
    } finally {
      if (mounted) {
        setState(() => _restoringClassicSession = false);
      }
    }
  }

  Future<void> _clearSavedClassicGame() async {
    // Finishing another game mode must never erase an unfinished Classic game.
    if (widget.adventureLevel != null || widget.mode != GameMode.classic) {
      return;
    }
    try {
      await _classicSessionStore.clear();
    } catch (error) {
      debugPrint('ELXVRO active game clear failed: $error');
    }
  }

''' + source[end:]
replace('  void _resetGame() {\n    _modeTimer?.cancel();',
        '  void _resetGame() {\n    if (_restoringClassicSession) return;\n'
        '    _modeTimer?.cancel();', 'restart restore lock')
screen_path.write_text(source)

pubspec = root / 'pubspec.yaml'
text = pubspec.read_text()
if text.count('version: 0.29.9+73') != 1:
    raise RuntimeError('Old pubspec version mismatch')
pubspec.write_text(text.replace('version: 0.29.9+73', 'version: 0.30.0+74', 1))
for path in (root / 'test').glob('*.dart'):
    original = path.read_text()
    update = original.replace('version: 0.29.9+73', 'version: 0.30.0+74')
    if update != original:
        path.write_text(update)
print('Applied v0.30.0 Classic save integrity and legacy compatibility fixes.')
