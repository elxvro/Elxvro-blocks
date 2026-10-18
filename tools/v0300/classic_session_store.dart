import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A complete Classic mode session. AppState owns coins and player progress.
class ClassicSessionSnapshot {
  const ClassicSessionSnapshot({
    required this.board,
    required this.pieces,
    required this.score,
    required this.combo,
    required this.bestCombo,
    required this.clearedLines,
    required this.placedBlocks,
    required this.perfectClears,
  });

  final String board;
  final List<String> pieces;
  final int score;
  final int combo;
  final int bestCombo;
  final int clearedLines;
  final int placedBlocks;
  final int perfectClears;

  bool get isValid =>
      RegExp(r'^[01]{100}$').hasMatch(board) &&
      pieces.length == 3 &&
      pieces.every((id) => id.isNotEmpty && id.length <= 80) &&
      score >= 0 && combo >= 0 && bestCombo >= 0 &&
      clearedLines >= 0 && placedBlocks >= 0 && perfectClears >= 0;

  Map<String, Object> toJson() => <String, Object>{
    'schema': 1,
    'board': board,
    'pieces': pieces,
    'score': score,
    'combo': combo,
    'bestCombo': bestCombo,
    'clearedLines': clearedLines,
    'placedBlocks': placedBlocks,
    'perfectClears': perfectClears,
  };

  static ClassicSessionSnapshot? decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic> || decoded['schema'] != 1) {
        return null;
      }
      final pieceValue = decoded['pieces'];
      if (pieceValue is! List || !pieceValue.every((id) => id is String)) {
        return null;
      }
      final board = decoded['board'];
      final score = decoded['score'];
      final combo = decoded['combo'];
      final bestCombo = decoded['bestCombo'];
      final clearedLines = decoded['clearedLines'];
      final placedBlocks = decoded['placedBlocks'];
      final perfectClears = decoded['perfectClears'];
      if (board is! String ||
          score is! int || combo is! int || bestCombo is! int ||
          clearedLines is! int || placedBlocks is! int ||
          perfectClears is! int) {
        return null;
      }
      final snapshot = ClassicSessionSnapshot(
        board: board,
        pieces: List<String>.unmodifiable(pieceValue.cast<String>()),
        score: score,
        combo: combo,
        bestCombo: bestCombo,
        clearedLines: clearedLines,
        placedBlocks: placedBlocks,
        perfectClears: perfectClears,
      );
      return snapshot.isValid ? snapshot : null;
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }
}

class ClassicSessionStore {
  static const String snapshotKey = 'active_classic_snapshot_v0300';

  // Preserve v0.16.1–v0.29.9 Classic saves without renaming player data.
  static const String _oldBoard = 'active_game_board_v0161';
  static const String _oldPieces = 'active_game_pieces_v0161';
  static const String _oldScore = 'active_game_score_v0161';
  static const String _oldCombo = 'active_game_combo_v0161';
  static const String _oldBestCombo = 'active_game_best_combo_v0161';
  static const String _oldLines = 'active_game_lines_v0161';
  static const String _oldBlocks = 'active_game_blocks_v0161';
  static const String _oldPerfect = 'active_game_perfect_v0161';
  static const String _oldValid = 'active_game_valid_v0161';

  // Shared by all GameScreen instances: late writes can't overtake reset.
  static Future<void> _pendingWrite = Future<void>.value();

  static Future<void> _schedule(Future<void> Function() action) {
    final result = _pendingWrite.then((_) => action());
    _pendingWrite = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return result;
  }

  Future<void> save(ClassicSessionSnapshot snapshot) {
    if (!snapshot.isValid) {
      throw ArgumentError('Invalid Classic game snapshot');
    }
    final payload = jsonEncode(snapshot.toJson());
    return _schedule(() async {
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setString(snapshotKey, payload)) {
        throw StateError('Classic session save failed');
      }
    });
  }

  Future<ClassicSessionSnapshot?> load() async {
    await _pendingWrite;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(snapshotKey);
    if (raw != null) {
      final current = ClassicSessionSnapshot.decode(raw);
      if (current != null) return current;
      await clear();
      return null;
    }
    if (!(prefs.getBool(_oldValid) ?? false)) return null;
    final old = ClassicSessionSnapshot(
      board: prefs.getString(_oldBoard) ?? '',
      pieces: (prefs.getString(_oldPieces) ?? '').split(','),
      score: prefs.getInt(_oldScore) ?? 0,
      combo: prefs.getInt(_oldCombo) ?? 0,
      bestCombo: prefs.getInt(_oldBestCombo) ?? 0,
      clearedLines: prefs.getInt(_oldLines) ?? 0,
      placedBlocks: prefs.getInt(_oldBlocks) ?? 0,
      perfectClears: prefs.getInt(_oldPerfect) ?? 0,
    );
    if (!old.isValid) {
      await clear();
      return null;
    }
    return old;
  }

  Future<void> clear() => _schedule(() async {
    final prefs = await SharedPreferences.getInstance();
    // Disable the legacy fallback before deleting the new record.
    await prefs.setBool(_oldValid, false);
    await prefs.remove(snapshotKey);
    for (final key in <String>[
      _oldBoard, _oldPieces, _oldScore, _oldCombo,
      _oldBestCombo, _oldLines, _oldBlocks, _oldPerfect,
    ]) {
      await prefs.remove(key);
    }
  });
}
