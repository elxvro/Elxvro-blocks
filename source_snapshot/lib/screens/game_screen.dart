import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_state.dart';
import '../game/board_engine.dart';
import '../models/block_piece.dart';
import '../models/game_mode.dart';
import '../models/game_theme.dart';
import '../services/audio_service.dart';
import '../widgets/piece_preview.dart';
import '../widgets/premium_background.dart';
import '../widgets/themed_block_tile.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.appState,
    this.mode = GameMode.classic,
  });

  final AppState appState;
  final GameMode mode;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const int _boardSize = 10;
  static const String _sessionBoardKey = 'active_game_board_v094';
  static const String _sessionPiecesKey = 'active_game_pieces_v094';
  static const String _sessionScoreKey = 'active_game_score_v094';
  static const String _sessionComboKey = 'active_game_combo_v094';
  static const String _sessionBestComboKey = 'active_game_best_combo_v094';
  static const String _sessionLinesKey = 'active_game_lines_v094';
  static const String _sessionBlocksKey = 'active_game_blocks_v094';
  static const String _sessionPerfectKey = 'active_game_perfect_v094';
  static const String _sessionValidKey = 'active_game_valid_v094';
  final BoardEngine _engine = BoardEngine(size: _boardSize);
  Random _random = Random();
  final GlobalKey _gridKey = GlobalKey();

  late List<BlockPiece?> _pieces;
  late final AnimationController _clearController;
  Timer? _modeTimer;
  Timer? _bannerTimer;

  int _score = 0;
  int _combo = 0;
  int _bestComboThisGame = 0;
  int _clearedLinesThisGame = 0;
  int _placedBlocksThisGame = 0;
  int _perfectClearsThisGame = 0;
  int? _hoverRow;
  int? _hoverCol;
  int? _hoverPieceIndex;
  bool _finishing = false;
  bool _paused = false;
  bool _resumePausePending = false;
  String? _eventBanner;
  bool _undoAvailable = true;
  bool _refreshAvailable = true;
  int _secondsLeft = 0;
  _GameSnapshot? _undoSnapshot;
  Set<int> _flashCells = <int>{};
  List<_Particle> _particles = <_Particle>[];
  bool _perfectClearFx = false;
  int _lastPlacementEpochMs = 0;
  int _lastToolActionEpochMs = 0;
  Set<int> _placementPulseCells = <int>{};
  int _placementPulseRevision = 0;
  final List<_FloatingScoreFx> _floatingScores = <_FloatingScoreFx>[];
  int _fxSequence = 0;
  int _impactLevel = 0;
  bool _liveRecordFx = false;
  bool _recordCelebratedInRound = false;
  Timer? _placementPulseTimer;
  Timer? _liveRecordTimer;

  GameThemeData get _theme => gameThemes.firstWhere(
        (theme) => theme.id == widget.appState.themeId,
        orElse: () => gameThemes.first,
      );


  GameModeData get _modeData => gameModeData[widget.mode]!;

  int get _dailySeed {
    final now = DateTime.now();
    return now.year * 10000 + now.month * 100 + now.day;
  }

  int get _modeBest {
    switch (widget.mode) {
      case GameMode.classic:
        return widget.appState.bestScore;
      case GameMode.timed:
        return widget.appState.timedBestScore;
      case GameMode.target:
        return widget.appState.targetBestScore;
      case GameMode.daily:
        return widget.appState.dailyChallengeBestScore;
      case GameMode.zen:
        return widget.appState.zenBestScore;
      case GameMode.hard:
        return widget.appState.hardBestScore;
    }
  }

  double get _boardFillRatio {
    var filled = 0;
    for (final row in _engine.grid) {
      for (final cell in row) {
        if (cell) filled += 1;
      }
    }
    return filled / (_boardSize * _boardSize);
  }

  double get _recordProgress {
    final best = _modeBest;
    if (best <= 0) return 0;
    return (_score / best).clamp(0.0, 1.0).toDouble();
  }

  int get _recordGap => max(0, _modeBest - _score);

  String get _recordStatus {
    if (_modeBest <= 0) return 'İLK REKORUNU YAZ';
    if (_score > _modeBest) return 'YENİ REKOR';
    if (_recordProgress >= 0.85) return 'REKORA $_recordGap';
    return 'REKOR $_modeBest';
  }

  String get _modeStatus {
    final target = _modeData.targetScore;
    final timer = _modeData.durationSeconds;
    if (target != null && timer != null) {
      return '${_formatTime(_secondsLeft)}  •  HEDEF $target';
    }
    if (timer != null) {
      return _formatTime(_secondsLeft);
    }
    if (target != null) {
      return 'HEDEF $target';
    }
    if (widget.mode == GameMode.zen) {
      return 'RAHAT MOD';
    }
    if (widget.mode == GameMode.hard) {
      return 'ZORLUK x1.35';
    }
    return 'SINIRSIZ';
  }

  String _formatTime(int seconds) {
    final safe = max(0, seconds);
    final minutes = safe ~/ 60;
    final rest = safe % 60;
    return '$minutes:${rest.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _prepareRound();
    _clearController = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: widget.appState.performanceMode ? 360 : 620,
      ),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() {
            _flashCells = <int>{};
            _particles = <_Particle>[];
            _perfectClearFx = false;
            _impactLevel = 0;
          });
        }
      });
    if (widget.mode == GameMode.classic) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_restoreSavedClassicGame());
        }
      });
    }
    if (widget.appState.tutorialCompleted) {
      _startModeTimer();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_showFirstRunTutorial());
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _modeTimer?.cancel();
    _bannerTimer?.cancel();
    _placementPulseTimer?.cancel();
    _liveRecordTimer?.cancel();
    _clearController.dispose();
    super.dispose();
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_finishing) return;

    switch (state) {
      case AppLifecycleState.resumed:
        if (!_resumePausePending || !mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_finishing && !_paused) {
            _resumePausePending = false;
            unawaited(_showPauseMenu());
          } else {
            _resumePausePending = false;
          }
        });
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        if (!_paused) {
          _modeTimer?.cancel();
          _resumePausePending = true;
          unawaited(_saveClassicGame());
        }
        break;
    }
  }

  void _prepareRound() {
    _modeTimer?.cancel();
    _random = widget.mode == GameMode.daily ? Random(_dailySeed) : Random();
    _engine.reset();
    if (widget.mode == GameMode.daily) {
      _applyDailyStartingBoard();
    } else if (widget.mode == GameMode.target) {
      _applyTargetStartingBoard();
    } else if (widget.mode == GameMode.hard) {
      _applyHardStartingBoard();
    }
    _secondsLeft = _modeData.durationSeconds ?? 0;
    _pieces = _generatePieces();
  }

  void _applyTargetStartingBoard() {
    final state = List<List<bool>>.generate(
      _boardSize,
      (_) => List<bool>.filled(_boardSize, false),
    );
    const cells = <({int row, int col})>[
      (row: 9, col: 0),
      (row: 9, col: 1),
      (row: 8, col: 0),
      (row: 9, col: 8),
      (row: 9, col: 9),
      (row: 8, col: 9),
      (row: 7, col: 3),
      (row: 7, col: 6),
      (row: 6, col: 4),
      (row: 6, col: 5),
    ];
    for (final cell in cells) {
      state[cell.row][cell.col] = true;
    }
    _engine.restore(state);
  }

  void _applyDailyStartingBoard() {
    final boardRandom = Random(_dailySeed ^ 0x5EED);
    final state = List<List<bool>>.generate(
      _boardSize,
      (_) => List<bool>.filled(_boardSize, false),
    );
    final rowCounts = List<int>.filled(_boardSize, 0);
    var placed = 0;
    while (placed < 14) {
      final row = 4 + boardRandom.nextInt(6);
      final col = boardRandom.nextInt(_boardSize);
      if (state[row][col] || rowCounts[row] >= 6) {
        continue;
      }
      state[row][col] = true;
      rowCounts[row] += 1;
      placed += 1;
    }
    _engine.restore(state);
  }

  void _applyHardStartingBoard() {
    final state = List<List<bool>>.generate(
      _boardSize,
      (_) => List<bool>.filled(_boardSize, false),
    );
    final rowCounts = List<int>.filled(_boardSize, 0);
    var placed = 0;
    while (placed < 20) {
      final row = 3 + _random.nextInt(7);
      final col = _random.nextInt(_boardSize);
      if (state[row][col] || rowCounts[row] >= 6) {
        continue;
      }
      state[row][col] = true;
      rowCounts[row] += 1;
      placed += 1;
    }
    _engine.restore(state);
  }

  BlockPiece _normalPieceForMode() {
    if (!_modeData.hardPieces) {
      return blockCatalog[_random.nextInt(blockCatalog.length)];
    }

    final hardPieces = blockCatalog
        .where((piece) => piece.size >= 4 && piece.id != 'square_3')
        .toList(growable: false);
    if (hardPieces.isNotEmpty && _random.nextDouble() < 0.82) {
      return hardPieces[_random.nextInt(hardPieces.length)];
    }
    return blockCatalog[_random.nextInt(blockCatalog.length)];
  }

  void _startModeTimer() {
    if (_modeData.durationSeconds == null) {
      return;
    }
    _modeTimer?.cancel();
    _modeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _finishing) {
        return;
      }
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
        unawaited(_handleTimeExpired());
        return;
      }
      setState(() => _secondsLeft -= 1);
    });
  }

  Future<void> _handleTimeExpired() async {
    if (widget.mode == GameMode.timed) {
      await _finishGame(success: true, reason: 'SÜRE DOLDU');
      return;
    }
    await _finishGame(success: false, reason: 'SÜRE DOLDU');
  }

  List<BlockPiece?> _generateRawPieces() {
    var specialUsed = false;
    return List<BlockPiece?>.generate(3, (_) {
      final shouldUseSpecial =
          !specialUsed && _random.nextDouble() < _modeData.specialChance;
      if (shouldUseSpecial) {
        specialUsed = true;
        return specialBlockCatalog[_random.nextInt(specialBlockCatalog.length)];
      }
      return _normalPieceForMode();
    });
  }

  List<BlockPiece?> _generatePieces() {
    var candidate = _generateRawPieces();
    // Popular block puzzlers protect the flow from a tray that is instantly
    // unusable. We only reroll a completely dead tray; the board can still
    // naturally reach a true game-over state. Hard mode keeps a stricter tray.
    final attempts = widget.mode == GameMode.hard ? 3 : 9;
    for (var attempt = 0; attempt < attempts; attempt++) {
      if (_engine.hasAnyMove(candidate.whereType<BlockPiece>())) {
        return candidate;
      }
      candidate = _generateRawPieces();
    }
    return candidate;
  }

  BlockPiece? _pieceForId(String id) {
    if (id == '-') return null;
    for (final piece in <BlockPiece>[...blockCatalog, ...specialBlockCatalog]) {
      if (piece.id == id) return piece;
    }
    return null;
  }

  Future<void> _saveClassicGame() async {
    if (widget.mode != GameMode.classic || _finishing) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final board = _engine
          .snapshot()
          .expand((row) => row)
          .map((filled) => filled ? '1' : '0')
          .join();
      final pieces = _pieces.map((piece) => piece?.id ?? '-').join(',');
      await prefs.setString(_sessionBoardKey, board);
      await prefs.setString(_sessionPiecesKey, pieces);
      await prefs.setInt(_sessionScoreKey, _score);
      await prefs.setInt(_sessionComboKey, _combo);
      await prefs.setInt(_sessionBestComboKey, _bestComboThisGame);
      await prefs.setInt(_sessionLinesKey, _clearedLinesThisGame);
      await prefs.setInt(_sessionBlocksKey, _placedBlocksThisGame);
      await prefs.setInt(_sessionPerfectKey, _perfectClearsThisGame);
      await prefs.setBool(_sessionValidKey, true);
    } catch (error) {
      debugPrint('ELXVRO active game save failed: $error');
    }
  }

  Future<void> _restoreSavedClassicGame() async {
    if (widget.mode != GameMode.classic || _finishing) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool(_sessionValidKey) ?? false)) return;
      final board = prefs.getString(_sessionBoardKey) ?? '';
      final pieceIds = (prefs.getString(_sessionPiecesKey) ?? '').split(',');
      if (board.length != _boardSize * _boardSize || pieceIds.length != 3) {
        await _clearSavedClassicGame();
        return;
      }
      final restoredGrid = List<List<bool>>.generate(
        _boardSize,
        (row) => List<bool>.generate(
          _boardSize,
          (col) => board[row * _boardSize + col] == '1',
        ),
      );
      final restoredPieces = pieceIds.map(_pieceForId).toList(growable: false);
      if (restoredPieces.every((piece) => piece == null)) {
        await _clearSavedClassicGame();
        return;
      }
      if (!mounted) return;
      setState(() {
        _engine.restore(restoredGrid);
        _pieces = List<BlockPiece?>.from(restoredPieces);
        _score = prefs.getInt(_sessionScoreKey) ?? 0;
        _combo = prefs.getInt(_sessionComboKey) ?? 0;
        _bestComboThisGame = prefs.getInt(_sessionBestComboKey) ?? 0;
        _clearedLinesThisGame = prefs.getInt(_sessionLinesKey) ?? 0;
        _placedBlocksThisGame = prefs.getInt(_sessionBlocksKey) ?? 0;
        _perfectClearsThisGame = prefs.getInt(_sessionPerfectKey) ?? 0;
        _recordCelebratedInRound = _score > _modeBest;
        _undoSnapshot = null;
        _hoverRow = null;
        _hoverCol = null;
        _hoverPieceIndex = null;
      });
      _showEventBanner('OYUNA DEVAM EDİLDİ');
    } catch (error) {
      debugPrint('ELXVRO active game restore failed: $error');
    }
  }

  Future<void> _clearSavedClassicGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_sessionValidKey, false);
      await prefs.remove(_sessionBoardKey);
      await prefs.remove(_sessionPiecesKey);
      await prefs.remove(_sessionScoreKey);
      await prefs.remove(_sessionComboKey);
      await prefs.remove(_sessionBestComboKey);
      await prefs.remove(_sessionLinesKey);
      await prefs.remove(_sessionBlocksKey);
      await prefs.remove(_sessionPerfectKey);
    } catch (error) {
      debugPrint('ELXVRO active game clear failed: $error');
    }
  }

  void _resetGame() {
    _modeTimer?.cancel();
    unawaited(_clearSavedClassicGame());
    setState(() {
      _finishing = false;
      _paused = false;
      _resumePausePending = false;
      _eventBanner = null;
      _prepareRound();
      _score = 0;
      _combo = 0;
      _bestComboThisGame = 0;
      _clearedLinesThisGame = 0;
      _placedBlocksThisGame = 0;
      _perfectClearsThisGame = 0;
      _hoverRow = null;
      _hoverCol = null;
      _hoverPieceIndex = null;
      _undoAvailable = true;
      _refreshAvailable = true;
      _undoSnapshot = null;
      _flashCells = <int>{};
      _particles = <_Particle>[];
      _placementPulseCells = <int>{};
      _floatingScores.clear();
      _impactLevel = 0;
      _liveRecordFx = false;
      _recordCelebratedInRound = false;
    });
    _clearController.reset();
    _startModeTimer();
  }

  _GameSnapshot _captureSnapshot() {
    return _GameSnapshot(
      grid: _engine.snapshot(),
      pieces: List<BlockPiece?>.from(_pieces),
      score: _score,
      combo: _combo,
      bestCombo: _bestComboThisGame,
      clearedLines: _clearedLinesThisGame,
      placedBlocks: _placedBlocksThisGame,
      perfectClears: _perfectClearsThisGame,
    );
  }

  bool _allowToolAction() {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (nowMs - _lastToolActionEpochMs < 420) return false;
    _lastToolActionEpochMs = nowMs;
    return true;
  }

  Future<void> _undoLastMove() async {
    if (_finishing || _paused || _resumePausePending) return;
    if (!_allowToolAction()) return;
    final snapshot = _undoSnapshot;
    if (snapshot == null || (!_undoAvailable && widget.appState.undoInventory <= 0)) {
      return;
    }

    if (!_undoAvailable) {
      final consumed = await widget.appState.consumeUndo();
      if (!consumed || !mounted) return;
    }

    setState(() {
      _engine.restore(snapshot.grid);
      _pieces = List<BlockPiece?>.from(snapshot.pieces);
      _score = snapshot.score;
      _combo = snapshot.combo;
      _bestComboThisGame = snapshot.bestCombo;
      _clearedLinesThisGame = snapshot.clearedLines;
      _placedBlocksThisGame = snapshot.placedBlocks;
      _perfectClearsThisGame = snapshot.perfectClears;
      if (_undoAvailable) {
        _undoAvailable = false;
      }
      _undoSnapshot = null;
      _flashCells = <int>{};
      _particles = <_Particle>[];
      _hoverRow = null;
      _hoverCol = null;
      _hoverPieceIndex = null;
    });
    _clearController.reset();
    _playClick();
    _lightHaptic();
    unawaited(_saveClassicGame());
  }

  Future<void> _refreshPieces() async {
    if (_finishing || _paused || _resumePausePending) return;
    if (!_allowToolAction()) return;
    if (!_refreshAvailable && widget.appState.refreshInventory <= 0) {
      return;
    }

    if (!_refreshAvailable) {
      final consumed = await widget.appState.consumeRefresh();
      if (!consumed || !mounted) return;
    }

    var candidate = List<BlockPiece?>.from(_pieces);
    for (var attempt = 0; attempt < 30; attempt++) {
      var specialUsed = false;
      candidate = List<BlockPiece?>.generate(3, (index) {
        if (_pieces[index] == null) {
          return null;
        }
        final useSpecial =
            !specialUsed && _random.nextDouble() < _modeData.specialChance;
        if (useSpecial) {
          specialUsed = true;
          return specialBlockCatalog[
              _random.nextInt(specialBlockCatalog.length)];
        }
        return _normalPieceForMode();
      });
      if (_engine.hasAnyMove(candidate.whereType<BlockPiece>())) {
        break;
      }
    }

    setState(() {
      _pieces = candidate;
      if (_refreshAvailable) {
        _refreshAvailable = false;
      }
      _undoSnapshot = null;
      _hoverRow = null;
      _hoverCol = null;
      _hoverPieceIndex = null;
    });
    _playClick();
    _lightHaptic();
    unawaited(_afterBoardMutation());
  }

  Future<void> _useSpecialBlock() async {
    if (_finishing || _paused || _resumePausePending) return;
    if (!_allowToolAction()) return;
    if (widget.appState.specialInventory <= 0) {
      return;
    }
    final index = _pieces.indexWhere((piece) => piece != null);
    if (index < 0) {
      return;
    }
    final consumed = await widget.appState.consumeSpecial();
    if (!consumed || !mounted) return;
    setState(() {
      _pieces[index] =
          specialBlockCatalog[_random.nextInt(specialBlockCatalog.length)];
      _undoSnapshot = null;
      _hoverRow = null;
      _hoverCol = null;
      _hoverPieceIndex = null;
    });
    _playAlert();
    _lightHaptic();
    unawaited(_saveClassicGame());
  }

  ({int row, int col})? _rawOriginFromGlobal(Offset globalOffset) {
    final renderObject = _gridKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return null;
    }

    final local = renderObject.globalToLocal(globalOffset);
    final size = renderObject.size;
    if (local.dx < 0 ||
        local.dy < 0 ||
        local.dx >= size.width ||
        local.dy >= size.height) {
      return null;
    }

    final cellWidth = size.width / _boardSize;
    final cellHeight = size.height / _boardSize;
    final col = (local.dx / cellWidth).floor();
    final row = (local.dy / cellHeight).floor();
    return (row: row, col: col);
  }

  ({int row, int col})? _snapToValidOrigin(
    BlockPiece piece,
    int row,
    int col,
  ) {
    if (_engine.canPlace(piece, row, col)) {
      return (row: row, col: col);
    }

    const offsets = <({int row, int col})>[
      (row: -1, col: 0),
      (row: 1, col: 0),
      (row: 0, col: -1),
      (row: 0, col: 1),
      (row: -1, col: -1),
      (row: -1, col: 1),
      (row: 1, col: -1),
      (row: 1, col: 1),
    ];

    for (final offset in offsets) {
      final candidateRow = row + offset.row;
      final candidateCol = col + offset.col;
      if (_engine.canPlace(piece, candidateRow, candidateCol)) {
        return (row: candidateRow, col: candidateCol);
      }
    }
    return null;
  }

  void _updateHover(DragTargetDetails<int> details) {
    if (_finishing || _paused || _resumePausePending) return;
    final index = details.data;
    final piece = _pieces[index];
    if (piece == null) {
      return;
    }

    final raw = _rawOriginFromGlobal(details.offset);
    if (raw == null) {
      setState(() {
        _hoverPieceIndex = null;
        _hoverRow = null;
        _hoverCol = null;
      });
      return;
    }

    final snapped = _snapToValidOrigin(piece, raw.row, raw.col);
    final shown = snapped ?? raw;
    setState(() {
      _hoverPieceIndex = index;
      _hoverRow = shown.row;
      _hoverCol = shown.col;
    });
  }

  void _acceptPiece(DragTargetDetails<int> details) {
    if (_finishing || _paused || _resumePausePending) return;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (nowMs - _lastPlacementEpochMs < 110) return;
    _lastPlacementEpochMs = nowMs;
    final index = details.data;
    final piece = _pieces[index];
    if (piece == null) {
      return;
    }

    final raw = _rawOriginFromGlobal(details.offset);
    if (raw == null) {
      return;
    }
    final snapped = _snapToValidOrigin(piece, raw.row, raw.col);
    if (snapped == null) {
      setState(() {
        _hoverPieceIndex = null;
        _hoverRow = null;
        _hoverCol = null;
      });
      return;
    }

    final before = _captureSnapshot();
    final result = _engine.place(piece, snapped.row, snapped.col);

    if (result == null) {
      setState(() {
        _hoverPieceIndex = null;
        _hoverRow = null;
        _hoverCol = null;
      });
      return;
    }

    final scoreBeforeMove = _score;
    final lineCount = result.clearedLines;
    final didClear = result.clearedCellCount > 0;
    final nextCombo = didClear ? _combo + 1 : 0;
    final clearTierBonus = _clearTierBonus(lineCount);
    final isPerfectClear = didClear &&
        _engine.grid.every((row) => row.every((filled) => !filled));

    final baseMoveScore = result.placedCells * 10 +
        lineCount * 120 * max(1, nextCombo) +
        _specialBonus(result) +
        clearTierBonus;
    var moveScore = (baseMoveScore * _modeData.scoreMultiplier).round();
    if (isPerfectClear) {
      moveScore += 1000;
    }

    setState(() {
      if (_undoAvailable || widget.appState.undoInventory > 0) {
        _undoSnapshot = before;
      }
      _pieces[index] = null;
      _placedBlocksThisGame += 1;
      _clearedLinesThisGame += lineCount;

      _combo = nextCombo;
      if (didClear) {
        _bestComboThisGame = max(_bestComboThisGame, _combo);
      }

      _score += moveScore;
      if (isPerfectClear) {
        _perfectClearsThisGame += 1;
      }

      _hoverPieceIndex = null;
      _hoverRow = null;
      _hoverCol = null;

      if (_pieces.every((item) => item == null)) {
        _pieces = _generatePieces();
      }
    });

    _triggerPlacementFx(piece, snapped.row, snapped.col);
    _spawnScoreFx(
      cells: didClear ? result.clearedCells : const <BoardCell>[],
      fallbackRow: snapped.row,
      fallbackCol: snapped.col,
      score: moveScore,
      lineCount: lineCount,
      combo: _combo,
      perfect: isPerfectClear,
    );
    _maybeCelebrateLiveRecord(scoreBeforeMove);

    if (didClear) {
      _triggerClearFx(
        result.clearedCells,
        perfect: isPerfectClear,
        impact: max(lineCount, min(_combo, 5)),
      );
      final comboLabel = _combo > 1 ? 'COMBO x$_combo' : 'TEMİZLEME';
      if (isPerfectClear) {
        _showEventBanner('PERFECT CLEAR  •  $comboLabel  •  +$moveScore');
        unawaited(AudioService.instance.playPerfect(_theme.audioProfile));
      } else {
        final clearLabel = _clearTierLabel(lineCount);
        final eventLabel = clearLabel == null
            ? comboLabel
            : _combo > 1
                ? '$clearLabel  •  COMBO x$_combo'
                : clearLabel;
        _showEventBanner('$eventLabel  •  +$moveScore');
        unawaited(
          AudioService.instance.playClearTier(
            _theme.audioProfile,
            lineCount: lineCount,
            combo: _combo,
          ),
        );
      }

      if (isPerfectClear) {
        _perfectClearHaptic();
      } else if (lineCount >= 3 || _combo >= 4) {
        _mediumHaptic();
      } else {
        _clearHaptic();
      }
    } else {
      _lightHaptic();
      unawaited(AudioService.instance.playPlace(_theme.audioProfile));
    }

    unawaited(_afterBoardMutation());
  }

  int _clearTierBonus(int lines) {
    if (lines >= 4) {
      return 1200 + (lines - 4) * 300;
    }
    if (lines == 3) return 600;
    if (lines == 2) return 250;
    return 0;
  }

  String? _clearTierLabel(int lines) {
    if (lines >= 4) return 'MEGA CLEAR x$lines';
    if (lines == 3) return 'TRIPLE CLEAR';
    if (lines == 2) return 'DOUBLE CLEAR';
    return null;
  }

  int _specialBonus(PlacementResult result) {
    switch (result.power) {
      case PiecePower.bomb:
        return 80 + result.clearedCellCount * 18;
      case PiecePower.rowClear:
      case PiecePower.columnClear:
        return 100 + result.clearedCellCount * 14;
      case PiecePower.wild:
        return 50;
      case PiecePower.normal:
        return 0;
    }
  }

  void _triggerClearFx(
    List<BoardCell> cells, {
    bool perfect = false,
    int impact = 1,
  }) {
    if (cells.isEmpty) {
      return;
    }

    final flash = <int>{};
    final particles = <_Particle>[];
    final lowFx = widget.appState.performanceMode;
    final perCell = lowFx ? 1 : (cells.length > 18 ? 2 : 4);
    final maxParticles = lowFx ? 28 : 84;

    for (final cell in cells) {
      flash.add(cell.row * _boardSize + cell.col);
      for (var i = 0; i < perCell; i++) {
        particles.add(
          _Particle(
            x: (cell.col + 0.5) / _boardSize,
            y: (cell.row + 0.5) / _boardSize,
            vx: (_random.nextDouble() - 0.5) * (perfect ? 0.34 : 0.24),
            vy: -0.05 - _random.nextDouble() * (perfect ? 0.27 : 0.19),
            radius: 1.6 + _random.nextDouble() * (perfect ? 4.0 : 3.0),
            angle: _random.nextDouble() * pi * 2,
            spin: (_random.nextDouble() - 0.5) * 5.5,
          ),
        );
      }
    }

    setState(() {
      _flashCells = flash;
      _particles = particles.take(maxParticles).toList(growable: false);
      _perfectClearFx = perfect;
      _impactLevel = impact.clamp(1, 6).toInt();
    });
    _clearController.forward(from: 0);
  }

  void _triggerPlacementFx(BlockPiece piece, int row, int col) {
    final cells = <int>{};
    for (final cell in piece.cells) {
      final targetRow = row + cell.row;
      final targetCol = col + cell.col;
      if (targetRow >= 0 &&
          targetRow < _boardSize &&
          targetCol >= 0 &&
          targetCol < _boardSize) {
        cells.add(targetRow * _boardSize + targetCol);
      }
    }
    _placementPulseTimer?.cancel();
    setState(() {
      _placementPulseCells = cells;
      _placementPulseRevision += 1;
    });
    _placementPulseTimer = Timer(const Duration(milliseconds: 260), () {
      if (!mounted) return;
      setState(() => _placementPulseCells = <int>{});
    });
  }

  void _spawnScoreFx({
    required List<BoardCell> cells,
    required int fallbackRow,
    required int fallbackCol,
    required int score,
    required int lineCount,
    required int combo,
    required bool perfect,
  }) {
    if (score <= 0 || !mounted) return;

    double x;
    double y;
    if (cells.isNotEmpty) {
      x = cells.map((cell) => cell.col + 0.5).reduce((a, b) => a + b) /
          cells.length /
          _boardSize;
      y = cells.map((cell) => cell.row + 0.5).reduce((a, b) => a + b) /
          cells.length /
          _boardSize;
    } else {
      x = (fallbackCol + 0.5) / _boardSize;
      y = (fallbackRow + 0.5) / _boardSize;
    }

    final id = ++_fxSequence;
    final fx = _FloatingScoreFx(
      id: id,
      x: x.clamp(0.08, 0.92).toDouble(),
      y: y.clamp(0.10, 0.88).toDouble(),
      score: score,
      combo: combo,
      lineCount: lineCount,
      perfect: perfect,
    );
    setState(() {
      _floatingScores.add(fx);
      if (_floatingScores.length > 4) {
        _floatingScores.removeAt(0);
      }
    });
    Timer(const Duration(milliseconds: 980), () {
      if (!mounted) return;
      setState(() => _floatingScores.removeWhere((item) => item.id == id));
    });
  }

  void _maybeCelebrateLiveRecord(int scoreBeforeMove) {
    final previousBest = _modeBest;
    if (_recordCelebratedInRound || previousBest <= 0) return;
    if (scoreBeforeMove <= previousBest && _score > previousBest) {
      _recordCelebratedInRound = true;
      _liveRecordTimer?.cancel();
      setState(() => _liveRecordFx = true);
      _showEventBanner('YENİ REKOR  •  ${_score}');
      unawaited(AudioService.instance.playLiveRecordCue());
      if (widget.appState.hapticsEnabled) {
        HapticFeedback.heavyImpact();
      }
      _liveRecordTimer = Timer(const Duration(milliseconds: 1600), () {
        if (!mounted) return;
        setState(() => _liveRecordFx = false);
      });
    }
  }

  void _showEventBanner(String text) {
    _bannerTimer?.cancel();
    if (!mounted) return;
    setState(() => _eventBanner = text);
    _bannerTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() => _eventBanner = null);
      }
    });
  }

  Future<void> _showFirstRunTutorial() async {
    _modeTimer?.cancel();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF12100E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: const Column(
            children: <Widget>[
              Icon(
                Icons.school_rounded,
                color: Color(0xFFFFD98B),
                size: 34,
              ),
              SizedBox(height: 8),
              Text(
                'HIZLI EĞİTİM',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFFFD98B),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.8,
                ),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _TutorialLine(
                icon: Icons.touch_app_rounded,
                title: 'SÜRÜKLE & BIRAK',
                text: 'Alttaki blokları tahtadaki hayalet konuma bırak.',
              ),
              _TutorialLine(
                icon: Icons.grid_on_rounded,
                title: 'ÇİZGİLERİ TEMİZLE',
                text: 'Dolu satır ve sütunlar temizlenir; seri yaparsan combo büyür.',
              ),
              _TutorialLine(
                icon: Icons.auto_awesome_rounded,
                title: 'PERFECT CLEAR',
                text: 'Tahtayı tamamen boşaltırsan +1000 skor ve bonus coin kazanırsın.',
              ),
              _TutorialLine(
                icon: Icons.bolt_rounded,
                title: 'GÜÇLER',
                text: 'Geri Al, Yenile ve Özel blok haklarını kritik anda kullan.',
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC7863C),
                foregroundColor: const Color(0xFF160D06),
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('OYUNA BAŞLA'),
            ),
          ],
        );
      },
    );
    await widget.appState.completeTutorial();
    if (mounted && !_finishing) {
      _startModeTimer();
    }
  }

  Future<void> _showPauseMenu() async {
    if (_finishing || _paused) return;
    _modeTimer?.cancel();
    setState(() => _paused = true);

    final action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF12100E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              title: const Text(
                'OYUN DURAKLATILDI',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFFFD98B),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: widget.appState.soundEnabled,
                    onChanged: (value) async {
                      await widget.appState.setSoundEnabled(value);
                      setDialogState(() {});
                    },
                    title: const Text('Ses efektleri'),
                    secondary: const Icon(
                      Icons.volume_up_rounded,
                      color: Color(0xFFFFCF7A),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: widget.appState.musicEnabled,
                    onChanged: (value) async {
                      await widget.appState.setMusicEnabled(value);
                      setDialogState(() {});
                    },
                    title: const Text('Müzik'),
                    secondary: const Icon(
                      Icons.music_note_rounded,
                      color: Color(0xFFFFCF7A),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: widget.appState.hapticsEnabled,
                    onChanged: (value) async {
                      await widget.appState.setHapticsEnabled(value);
                      setDialogState(() {});
                    },
                    title: const Text('Titreşim'),
                    secondary: const Icon(
                      Icons.vibration_rounded,
                      color: Color(0xFFFFCF7A),
                    ),
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop('home'),
                  child: const Text('ANA MENÜ'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop('restart'),
                  child: const Text('YENİDEN'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop('resume'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFC7863C),
                    foregroundColor: const Color(0xFF160D06),
                  ),
                  child: const Text('DEVAM ET'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted) return;
    if (action == 'home') {
      await _saveClassicGame();
      if (widget.mode == GameMode.zen) {
        await widget.appState.recordModeResult(
          modeId: _modeData.id,
          score: _score,
          success: true,
        );
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
      return;
    }
    if (action == 'restart') {
      _resetGame();
      return;
    }
    setState(() => _paused = false);
    _startModeTimer();
  }

  void _playClick() {
    unawaited(AudioService.instance.playClick());
  }

  void _playAlert() {
    unawaited(AudioService.instance.playReward());
  }

  void _lightHaptic() {
    if (widget.appState.hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  void _mediumHaptic() {
    if (widget.appState.hapticsEnabled) {
      HapticFeedback.mediumImpact();
    }
  }

  void _clearHaptic() {
    if (widget.appState.hapticsEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  void _perfectClearHaptic() {
    if (widget.appState.hapticsEnabled) {
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> _afterBoardMutation() async {
    await _checkGameState();
    if (!_finishing) {
      await _saveClassicGame();
      if (widget.mode == GameMode.zen && _placedBlocksThisGame % 5 == 0) {
        await widget.appState.recordModeResult(
          modeId: _modeData.id,
          score: _score,
          success: false,
        );
      }
    }
  }

  Future<void> _checkGameState() async {
    if (_finishing) {
      return;
    }

    final target = _modeData.targetScore;
    if (target != null && _score >= target) {
      await _finishGame(success: true, reason: 'HEDEF TAMAMLANDI');
      return;
    }

    final available = _pieces.whereType<BlockPiece>().toList();
    if (available.isNotEmpty && _engine.hasAnyMove(available)) {
      return;
    }

    if (_modeData.zenRecovery) {
      _recoverZenBoard();
      return;
    }

    final canRescueWithRefresh =
        _refreshAvailable || widget.appState.refreshInventory > 0;
    final canRescueWithSpecial = widget.appState.specialInventory > 0;
    final canRescueWithUndo = _undoSnapshot != null &&
        (_undoAvailable || widget.appState.undoInventory > 0);
    if (canRescueWithRefresh || canRescueWithSpecial || canRescueWithUndo) {
      _showEventBanner('KRİTİK HAMLE • GÜÇ KULLAN');
      return;
    }

    final timedSuccess = widget.mode == GameMode.timed && _score >= 1000;
    await _finishGame(
      success: widget.mode == GameMode.classic ||
          widget.mode == GameMode.hard ||
          timedSuccess,
      reason: 'HAMLE KALMADI',
    );
  }

  void _recoverZenBoard() {
    final filled = <BoardCell>[];
    for (var row = 0; row < _boardSize; row++) {
      for (var col = 0; col < _boardSize; col++) {
        if (_engine.grid[row][col]) {
          filled.add(BoardCell(row, col));
        }
      }
    }
    filled.shuffle(_random);
    final cleared = filled.take(min(14, filled.length)).toList(growable: false);
    final state = _engine.snapshot();
    for (final cell in cleared) {
      state[cell.row][cell.col] = false;
    }
    _engine.restore(state);

    setState(() {
      _pieces = _generatePieces();
      _combo = 0;
      _undoSnapshot = null;
      _hoverRow = null;
      _hoverCol = null;
      _hoverPieceIndex = null;
    });

    if (cleared.isNotEmpty) {
      _triggerClearFx(cleared);
    }
    _showEventBanner('ZEN NEFESİ • TAHTA RAHATLADI');
    unawaited(AudioService.instance.playClear(_theme.audioProfile));
    _lightHaptic();
  }

  Future<void> _finishGame({
    required bool success,
    required String reason,
  }) async {
    if (_finishing) {
      return;
    }
    _finishing = true;
    _modeTimer?.cancel();
    unawaited(_clearSavedClassicGame());

    final previousModeBest = _modeBest;
    final progression = await widget.appState.recordGame(
      score: _score,
      combo: _bestComboThisGame,
      clearedLines: _clearedLinesThisGame,
      placedBlocks: _placedBlocksThisGame,
      perfectClearsThisGame: _perfectClearsThisGame,
    );
    final modeReward = await widget.appState.recordModeResult(
      modeId: _modeData.id,
      score: _score,
      success: success,
    );
    final isNewPersonalRecord = _score > previousModeBest;
    if (!mounted) {
      return;
    }

    if (isNewPersonalRecord) {
      unawaited(AudioService.instance.playRecordCelebration());
    } else if (success &&
        (widget.mode == GameMode.target || widget.mode == GameMode.daily)) {
      unawaited(AudioService.instance.playReward());
    } else {
      unawaited(AudioService.instance.playGameOver());
    }
    if (widget.appState.hapticsEnabled) {
      HapticFeedback.heavyImpact();
    }

    var title = isNewPersonalRecord ? 'YENİ REKOR!' : 'OYUN BİTTİ';
    if (!isNewPersonalRecord) {
      if (widget.mode == GameMode.timed) {
        title = reason;
      } else if (widget.mode == GameMode.target || widget.mode == GameMode.daily) {
        title = success ? 'HEDEF TAMAMLANDI' : 'CHALLENGE BİTTİ';
      } else if (widget.mode == GameMode.hard) {
        title = 'ZOR MOD BİTTİ';
      } else if (widget.mode == GameMode.zen) {
        title = 'ZEN OTURUMU';
      }
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF12100E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFFFD98B),
              letterSpacing: 2.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Stack(
            children: <Widget>[
              Positioned.fill(
                child: IgnorePointer(
                  child: _GameOverMaterialFx(
                    theme: _theme,
                    lowFx: widget.appState.performanceMode,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
              Text(
                '${_modeData.title}  •  $reason',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
              if (isNewPersonalRecord) ...<Widget>[
                const SizedBox(height: 10),
                _RecordCelebrationStrip(theme: _theme),
              ],
              const SizedBox(height: 18),
              _AnimatedFinalScore(
                score: _score,
                accent: _theme.blockAccent,
                lowFx: widget.appState.performanceMode,
              ),
              const Text(
                'SKOR',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  letterSpacing: 1.5,
                ),
              ),
              if (isNewPersonalRecord) ...<Widget>[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: const Color(0xFFFFC86E).withValues(alpha: 0.12),
                    border: Border.all(
                      color: const Color(0xFFFFC86E).withValues(alpha: 0.30),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.workspace_premium_rounded, size: 16, color: Color(0xFFFFD98B)),
                      SizedBox(width: 6),
                      Text(
                        'YENİ KİŞİSEL REKOR',
                        style: TextStyle(
                          color: Color(0xFFFFD98B),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _DialogStat(
                      label: 'ÇİZGİ',
                      value: '$_clearedLinesThisGame',
                    ),
                  ),
                  Expanded(
                    child: _DialogStat(
                      label: 'MAX COMBO',
                      value: 'x$_bestComboThisGame',
                    ),
                  ),
                  Expanded(
                    child: _DialogStat(
                      label: 'BLOK',
                      value: '$_placedBlocksThisGame',
                    ),
                  ),
                ],
              ),
              if (_perfectClearsThisGame > 0) ...<Widget>[
                const SizedBox(height: 10),
                Text(
                  'PERFECT CLEAR  x$_perfectClearsThisGame',
                  style: const TextStyle(
                    color: Color(0xFFFFD98B),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'MOD REKORU  ${max(_modeBest, _score)}',
                style: const TextStyle(
                  color: Color(0xFFFFC86E),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 7,
                runSpacing: 7,
                children: <Widget>[
                  _RewardChip(label: '+${progression.xpEarned} XP'),
                  if (progression.coinBonus > 0)
                    _RewardChip(label: '+${progression.coinBonus} COIN'),
                  if (progression.leveledUp)
                    _RewardChip(
                      label: 'SEVİYE ${progression.levelAfter}',
                      emphasized: true,
                    ),
                  if (progression.milestoneSpecials > 0)
                    _RewardChip(
                      label: '+${progression.milestoneSpecials} ÖZEL',
                      emphasized: true,
                    ),
                ],
              ),
              if (modeReward > 0) ...<Widget>[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: const Color(0xFFFFC86E).withValues(alpha: 0.10),
                    border: Border.all(
                      color: const Color(0xFFFFC86E).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    '+$modeReward COIN KAZANDIN',
                    style: const TextStyle(
                      color: Color(0xFFFFD98B),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
                ],
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('ANA MENÜ'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetGame();
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC7863C),
                foregroundColor: const Color(0xFF160D06),
              ),
              child: const Text('TEKRAR OYNA'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PremiumBackground(
        top: _theme.backgroundTop,
        bottom: _theme.backgroundBottom,
        material: _theme.material,
        accent: _theme.blockAccent,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final heightLimited = max(232.0, constraints.maxHeight - 282);
              final boardExtent = min(
                constraints.maxWidth - 28,
                min(430.0, heightLimited),
              );
              final cellSize = boardExtent / _boardSize;
              return Stack(
                children: <Widget>[
                  Column(
                    children: <Widget>[
                  _TopBar(
                    score: _score,
                    modeLabel: _modeData.title,
                    modeStatus: _modeStatus,
                    recordStatus: _recordStatus,
                    recordProgress: _recordProgress,
                    accent: _theme.blockAccent,
                    danger: _boardFillRatio >= 0.78,
                    onBack: _showPauseMenu,
                    onHelp: () => _showHowToPlay(context),
                  ),
                  SizedBox(
                    height: 34,
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 210),
                        transitionBuilder: (child, animation) => ScaleTransition(
                          scale: Tween<double>(begin: 0.84, end: 1).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutBack,
                            ),
                          ),
                          child: FadeTransition(opacity: animation, child: child),
                        ),
                        child: _combo > 1
                            ? _StreakMeter(
                                key: ValueKey<int>(_combo),
                                combo: _combo,
                                accent: _theme.blockAccent,
                                lowFx: widget.appState.performanceMode,
                              )
                            : _FlowHint(
                                key: const ValueKey<String>('flow'),
                                text: _boardFillRatio >= 0.78
                                    ? 'TAHTA DOLUYOR • ALAN AÇ'
                                    : _recordStatus,
                                accent: _theme.blockAccent,
                                danger: _boardFillRatio >= 0.78,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  SizedBox(
                    width: boardExtent,
                    height: boardExtent,
                    child: DragTarget<int>(
                      onWillAcceptWithDetails: (details) {
                        _updateHover(details);
                        return _pieces[details.data] != null;
                      },
                      onMove: _updateHover,
                      onLeave: (_) {
                        setState(() {
                          _hoverRow = null;
                          _hoverCol = null;
                          _hoverPieceIndex = null;
                        });
                      },
                      onAcceptWithDetails: _acceptPiece,
                      builder: (context, candidateData, rejectedData) {
                        final danger = _boardFillRatio >= 0.78;
                        final dangerAmount = ((_boardFillRatio - 0.78) / 0.22)
                            .clamp(0.0, 1.0)
                            .toDouble();
                        return AnimatedBuilder(
                          animation: _clearController,
                          builder: (context, _) {
                            final progress = _clearController.value;
                            final impactActive = _impactLevel > 1 &&
                                progress < 0.54 &&
                                !widget.appState.performanceMode;
                            final decay = impactActive
                                ? (1 - progress / 0.54).clamp(0.0, 1.0)
                                : 0.0;
                            final shake = impactActive
                                ? sin(progress * pi * 13) *
                                    min(7.5, 1.25 * _impactLevel) *
                                    decay
                                : 0.0;
                            final punch = impactActive
                                ? 1 + sin(progress * pi) * 0.006 * _impactLevel
                                : 1.0;
                            return Transform.translate(
                              offset: Offset(shake, 0),
                              child: Transform.scale(
                                scale: punch,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: <Color>[
                                        Color.lerp(
                                          _theme.board,
                                          _theme.blockAccent,
                                          0.09,
                                        )!,
                                        _theme.board,
                                        Color.lerp(
                                          _theme.board,
                                          Colors.black,
                                          0.30,
                                        )!,
                                      ],
                                      stops: const <double>[0.0, 0.56, 1.0],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: danger
                                          ? Color.lerp(
                                              _theme.blockAccent,
                                              const Color(0xFFFF665F),
                                              0.62 + dangerAmount * 0.28,
                                            )!.withValues(alpha: 0.72)
                                          : _theme.blockAccent.withValues(alpha: 0.34),
                                      width: danger ? 1.5 : 1.0,
                                    ),
                                    boxShadow: widget.appState.performanceMode
                                        ? null
                                        : <BoxShadow>[
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.62),
                                              blurRadius: 18,
                                              spreadRadius: 1,
                                              offset: const Offset(0, 12),
                                            ),
                                            BoxShadow(
                                              color: danger
                                                  ? const Color(0xFFFF4D4D)
                                                      .withValues(alpha: 0.16 + dangerAmount * 0.17)
                                                  : _theme.blockAccent.withValues(alpha: 0.14),
                                              blurRadius: danger ? 28 : 24,
                                              spreadRadius: -2,
                                              offset: const Offset(0, 4),
                                            ),
                                            BoxShadow(
                                              color: Colors.white.withValues(alpha: 0.035),
                                              blurRadius: 2,
                                              offset: const Offset(0, -1),
                                            ),
                                          ],
                                  ),
                                  child: Stack(
                                    children: <Widget>[
                                      _BoardGrid(
                                        engine: _engine,
                                        theme: _theme,
                                        hoverRow: _hoverRow,
                                        hoverCol: _hoverCol,
                                        hoverPiece: _hoverPieceIndex == null
                                            ? null
                                            : _pieces[_hoverPieceIndex!],
                                        cellSize: cellSize,
                                        gridKey: _gridKey,
                                        flashCells: _flashCells,
                                        flashProgress: progress,
                                        placementPulseCells: _placementPulseCells,
                                        placementPulseRevision: _placementPulseRevision,
                                      ),
                                      if (_flashCells.isNotEmpty &&
                                          !widget.appState.performanceMode)
                                        Positioned.fill(
                                          child: IgnorePointer(
                                            child: CustomPaint(
                                              painter: _ClearShockwavePainter(
                                                progress: progress,
                                                cells: _flashCells,
                                                boardSize: _boardSize,
                                                color: _theme.blockAccent,
                                                impact: _impactLevel,
                                              ),
                                            ),
                                          ),
                                        ),
                                      if (_flashCells.isNotEmpty &&
                                          !widget.appState.performanceMode)
                                        Positioned.fill(
                                          child: IgnorePointer(
                                            child: CustomPaint(
                                              painter: _Material2DOverlayPainter(
                                                progress: progress,
                                                cells: _flashCells,
                                                boardSize: _boardSize,
                                                theme: _theme,
                                                impact: _impactLevel,
                                                perfect: _perfectClearFx,
                                              ),
                                            ),
                                          ),
                                        ),
                                      if (_particles.isNotEmpty)
                                        Positioned.fill(
                                          child: IgnorePointer(
                                            child: CustomPaint(
                                              painter: _ParticleBurstPainter(
                                                particles: _particles,
                                                progress: progress,
                                                color: _theme.blockAccent,
                                                baseColor: _theme.block,
                                                material: _theme.material,
                                              ),
                                            ),
                                          ),
                                        ),
                                      if (_flashCells.isNotEmpty &&
                                          _combo >= 3 &&
                                          !widget.appState.performanceMode)
                                        Positioned.fill(
                                          child: IgnorePointer(
                                            child: _Combo2DSplash(
                                              animation: _clearController,
                                              combo: _combo,
                                              accent: _theme.blockAccent,
                                            ),
                                          ),
                                        ),
                                      if (_floatingScores.isNotEmpty)
                                        Positioned.fill(
                                          child: IgnorePointer(
                                            child: _FloatingScoreOverlay(
                                              items: List<_FloatingScoreFx>.from(
                                                _floatingScores,
                                              ),
                                              accent: _theme.blockAccent,
                                              lowFx: widget.appState.performanceMode,
                                            ),
                                          ),
                                        ),
                                      if (_eventBanner != null)
                                        Positioned(
                                          top: 10,
                                          left: 8,
                                          right: 8,
                                          child: IgnorePointer(
                                            child: Center(
                                              child: _MaterialEventBanner(
                                                text: _eventBanner!,
                                                theme: _theme,
                                                lowFx: widget.appState.performanceMode,
                                              ),
                                            ),
                                          ),
                                        ),
                                      if (_liveRecordFx)
                                        Positioned.fill(
                                          child: IgnorePointer(
                                            child: _LiveRecordOverlay(
                                              accent: _theme.blockAccent,
                                              lowFx: widget.appState.performanceMode,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 9),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Container(
                      height: 104,
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            _theme.blockAccent.withValues(alpha: 0.065),
                            Colors.black.withValues(alpha: 0.24),
                          ],
                        ),
                        border: Border.all(
                          color: _theme.blockAccent.withValues(alpha: 0.18),
                        ),
                        boxShadow: widget.appState.performanceMode
                            ? null
                            : <BoxShadow>[
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.42),
                                  blurRadius: 16,
                                  offset: const Offset(0, 7),
                                ),
                              ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List<Widget>.generate(3, (index) {
                          final piece = _pieces[index];
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: _PieceSlot(
                                piece: piece,
                                index: index,
                                theme: _theme,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          child: _GameToolButton(
                            icon: Icons.undo_rounded,
                            label: 'GERİ AL',
                            charge: (_undoAvailable ? 1 : 0) +
                                widget.appState.undoInventory,
                            enabled: _undoSnapshot != null &&
                                (_undoAvailable || widget.appState.undoInventory > 0),
                            accent: _theme.blockAccent,
                            onPressed: _undoLastMove,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: _GameToolButton(
                            icon: Icons.autorenew_rounded,
                            label: 'YENİLE',
                            charge: (_refreshAvailable ? 1 : 0) +
                                widget.appState.refreshInventory,
                            enabled: _refreshAvailable ||
                                widget.appState.refreshInventory > 0,
                            accent: _theme.blockAccent,
                            onPressed: _refreshPieces,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: _GameToolButton(
                            icon: Icons.auto_awesome_rounded,
                            label: 'ÖZEL',
                            charge: widget.appState.specialInventory,
                            enabled: widget.appState.specialInventory > 0 &&
                                _pieces.any((piece) => piece != null),
                            accent: _theme.blockAccent,
                            onPressed: _useSpecialBlock,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                    ],
                  ),
                  if (_perfectClearFx && !widget.appState.performanceMode)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: _PerfectClearOverlay(
                          animation: _clearController,
                          theme: _theme,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showHowToPlay(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'NASIL OYNANIR?',
              style: TextStyle(
                color: Color(0xFFFFD98B),
                fontWeight: FontWeight.w800,
                letterSpacing: 1.7,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${_modeData.title}: ${_modeData.description}',
              style: const TextStyle(
                color: Color(0xFFFFC86E),
                fontSize: 11,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            const _Rule(text: '1. Bloğu sürükle; hayalet alan nereye oturacağını gösterir.'),
            const _Rule(text: '2. Dolu satır veya sütunları temizleyerek combo yap.'),
            const _Rule(text: '3. Bomba, Satır, Sütun ve Joker özel bloklarını kullan.'),
            const _Rule(text: '4. Her oyunda 1 ücretsiz Geri Al ve 1 Yenile hakkın var.'),
            const _Rule(text: '5. Mağazadan ekstra hak ve Özel Blok gücü alabilirsin.'),
            const _Rule(text: '6. Mod hedefini tamamla veya mümkün olan en iyi skoru yap.'),
          ],
        ),
      ),
    );
  }
}

class _TutorialLine extends StatelessWidget {
  const _TutorialLine({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              color: const Color(0xFFFFC86E).withValues(alpha: 0.10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: const Color(0xFFFFCF7A), size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  const _RewardChip({required this.label, this.emphasized = false});

  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFFFFC86E)
            .withValues(alpha: emphasized ? 0.15 : 0.08),
        border: Border.all(
          color: const Color(0xFFFFC86E)
              .withValues(alpha: emphasized ? 0.35 : 0.18),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFFFD98B),
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _GameSnapshot {
  const _GameSnapshot({
    required this.grid,
    required this.pieces,
    required this.score,
    required this.combo,
    required this.bestCombo,
    required this.clearedLines,
    required this.placedBlocks,
    required this.perfectClears,
  });

  final List<List<bool>> grid;
  final List<BlockPiece?> pieces;
  final int score;
  final int combo;
  final int bestCombo;
  final int clearedLines;
  final int placedBlocks;
  final int perfectClears;
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.score,
    required this.modeLabel,
    required this.modeStatus,
    required this.recordStatus,
    required this.recordProgress,
    required this.accent,
    required this.danger,
    required this.onBack,
    required this.onHelp,
  });

  final int score;
  final String modeLabel;
  final String modeStatus;
  final String recordStatus;
  final double recordProgress;
  final Color accent;
  final bool danger;
  final VoidCallback onBack;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    final statusColor = danger ? const Color(0xFFFF827B) : accent;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 7, 10, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _RoundIconButton(
            icon: Icons.pause_rounded,
            tooltip: 'Duraklat',
            onPressed: onBack,
            accent: accent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  modeLabel.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: statusColor.withValues(alpha: 0.92),
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 1),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.96, end: 1).animate(animation),
                      child: child,
                    ),
                  ),
                  child: Text(
                    '$score',
                    key: ValueKey<int>(score),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 31,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.7,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        modeStatus,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.55,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        recordStatus,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.55,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: SizedBox(
                    height: 3,
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        ColoredBox(color: Colors.white.withValues(alpha: 0.06)),
                        FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: recordProgress.clamp(0.0, 1.0).toDouble(),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: <Color>[
                                  accent.withValues(alpha: 0.55),
                                  statusColor,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _RoundIconButton(
            icon: Icons.help_outline_rounded,
            tooltip: 'Nasıl oynanır?',
            onPressed: onHelp,
            accent: accent,
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.accent,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withValues(alpha: 0.18),
        shape: CircleBorder(
          side: BorderSide(color: accent.withValues(alpha: 0.14)),
        ),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(icon, color: Colors.white70, size: 21),
          ),
        ),
      ),
    );
  }
}

class _StreakMeter extends StatelessWidget {
  const _StreakMeter({
    super.key,
    required this.combo,
    required this.accent,
    required this.lowFx,
  });

  final int combo;
  final Color accent;
  final bool lowFx;

  String get _label {
    if (combo >= 8) return 'OVERDRIVE x$combo';
    if (combo >= 5) return 'MEGA SERİ x$combo';
    return 'SERİ x$combo';
  }

  @override
  Widget build(BuildContext context) {
    final lit = min(6, combo);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.black.withValues(alpha: 0.24),
        border: Border.all(color: accent.withValues(alpha: 0.26)),
        boxShadow: lowFx
            ? null
            : <BoxShadow>[
                BoxShadow(
                  color: accent.withValues(alpha: combo >= 5 ? 0.28 : 0.13),
                  blurRadius: combo >= 5 ? 20 : 12,
                ),
              ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            combo >= 5 ? Icons.local_fire_department_rounded : Icons.bolt_rounded,
            size: 15,
            color: accent,
          ),
          const SizedBox(width: 6),
          Text(
            _label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.9,
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: List<Widget>.generate(6, (index) {
              final active = index < lit;
              return Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.only(left: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? accent : Colors.white12,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _FlowHint extends StatelessWidget {
  const _FlowHint({
    super.key,
    required this.text,
    required this.accent,
    required this.danger,
  });

  final String text;
  final Color accent;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? const Color(0xFFFF827B) : accent;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          danger ? Icons.warning_amber_rounded : Icons.emoji_events_outlined,
          size: 13,
          color: color.withValues(alpha: 0.85),
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            color: color.withValues(alpha: 0.82),
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _BoardGrid extends StatelessWidget {
  const _BoardGrid({
    required this.engine,
    required this.theme,
    required this.hoverRow,
    required this.hoverCol,
    required this.hoverPiece,
    required this.cellSize,
    required this.gridKey,
    required this.flashCells,
    required this.flashProgress,
    required this.placementPulseCells,
    required this.placementPulseRevision,
  });

  final BoardEngine engine;
  final GameThemeData theme;
  final int? hoverRow;
  final int? hoverCol;
  final BlockPiece? hoverPiece;
  final double cellSize;
  final GlobalKey gridKey;
  final Set<int> flashCells;
  final double flashProgress;
  final Set<int> placementPulseCells;
  final int placementPulseRevision;

  bool _isHoveredCell(int row, int col) {
    final piece = hoverPiece;
    final originRow = hoverRow;
    final originCol = hoverCol;
    if (piece == null || originRow == null || originCol == null) {
      return false;
    }
    return piece.cells.any(
      (cell) => originRow + cell.row == row && originCol + cell.col == col,
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPlace = hoverPiece != null && hoverRow != null && hoverCol != null
        ? engine.canPlace(hoverPiece!, hoverRow!, hoverCol!)
        : false;

    return SizedBox.expand(
      key: gridKey,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _GameScreenState._boardSize,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
        ),
        itemCount: engine.size * engine.size,
        itemBuilder: (context, index) {
          final row = index ~/ engine.size;
          final col = index % engine.size;
          final filled = engine.grid[row][col];
          final hovered = _isHoveredCell(row, col);
          final flashed = flashCells.contains(index);
          final flashAlpha = (1 - flashProgress).clamp(0.0, 1.0).toDouble();
          final hoverColor = canPlace
              ? theme.blockAccent.withValues(alpha: 0.55)
              : const Color(0xFFFF4D4D).withValues(alpha: 0.42);

          return AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(max(2.5, cellSize * 0.10)),
              color: filled
                  ? Colors.transparent
                  : flashed
                      ? theme.blockAccent.withValues(alpha: 0.72 * flashAlpha)
                      : hovered
                          ? hoverColor
                          : theme.cell,
              gradient: null,
              border: Border.all(
                color: flashed
                    ? Colors.white.withValues(alpha: 0.88 * flashAlpha)
                    : filled
                        ? Colors.transparent
                        : Colors.white.withValues(alpha: 0.035),
                width: flashed ? 1.3 : 0.7,
              ),
              boxShadow: flashed
                  ? <BoxShadow>[
                      BoxShadow(
                        color: theme.blockAccent.withValues(
                          alpha: 0.55 * flashAlpha,
                        ),
                        blurRadius: 14,
                      ),
                    ]
                  : null,
            ),
            child: filled
                ? placementPulseCells.contains(index)
                    ? TweenAnimationBuilder<double>(
                        key: ValueKey<String>(
                          'place-$index-$placementPulseRevision',
                        ),
                        tween: Tween<double>(begin: 0.72, end: 1),
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutBack,
                        builder: (context, scale, child) => Transform.scale(
                          scale: scale,
                          child: child,
                        ),
                        child: ThemedBlockTile(
                          material: theme.material,
                          base: theme.block,
                          accent: theme.blockAccent,
                          flash: flashed ? flashAlpha : 0,
                        ),
                      )
                    : ThemedBlockTile(
                        material: theme.material,
                        base: theme.block,
                        accent: theme.blockAccent,
                        flash: flashed ? flashAlpha : 0,
                      )
                : flashed
                    ? Opacity(
                        opacity: flashAlpha,
                        child: ThemedBlockTile(
                          material: theme.material,
                          base: theme.block,
                          accent: theme.blockAccent,
                          flash: flashAlpha,
                        ),
                      )
                    : hovered && canPlace
                        ? AnimatedScale(
                            duration: const Duration(milliseconds: 90),
                            curve: Curves.easeOutBack,
                            scale: 0.90,
                            child: Opacity(
                              opacity: 0.48,
                              child: ThemedBlockTile(
                                material: theme.material,
                                base: theme.block,
                                accent: theme.blockAccent,
                              ),
                            ),
                          )
                        : null,
          );
        },
      ),
    );
  }
}

class _PieceSlot extends StatelessWidget {
  const _PieceSlot({
    required this.piece,
    required this.index,
    required this.theme,
  });

  final BlockPiece? piece;
  final int index;
  final GameThemeData theme;

  @override
  Widget build(BuildContext context) {
    final currentPiece = piece;
    final child = Container(
      height: 92,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.022),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: currentPiece?.isSpecial == true
              ? theme.blockAccent.withValues(alpha: 0.28)
              : theme.blockAccent.withValues(alpha: 0.075),
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: Tween<double>(begin: 0.72, end: 1).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          ),
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: currentPiece == null
            ? const SizedBox.shrink(key: ValueKey<String>('empty'))
            : Stack(
                key: ValueKey<String>(currentPiece.id),
                alignment: Alignment.center,
                children: <Widget>[
                  PiecePreview(
                    piece: currentPiece,
                    color: theme.block,
                    accent: theme.blockAccent,
                    material: theme.material,
                    cellSize: currentPiece.rows >= 3 || currentPiece.cols >= 3
                        ? 20
                        : 25,
                  ),
                  if (currentPiece.isSpecial)
                    Positioned(
                      top: 5,
                      right: 5,
                      child: _SpecialBadge(piece: currentPiece),
                    ),
                ],
              ),
      ),
    );

    if (currentPiece == null) {
      return child;
    }

    return Draggable<int>(
      data: index,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      maxSimultaneousDrags: 1,
      feedback: Material(
        color: Colors.transparent,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            PiecePreview(
              piece: currentPiece,
              color: theme.block,
              accent: theme.blockAccent,
              material: theme.material,
              cellSize: 28,
            ),
            if (currentPiece.isSpecial)
              Positioned(
                right: -18,
                top: -18,
                child: _SpecialBadge(piece: currentPiece, compact: true),
              ),
          ],
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.18, child: child),
      child: child,
    );
  }
}

class _SpecialBadge extends StatelessWidget {
  const _SpecialBadge({required this.piece, this.compact = false});

  final BlockPiece piece;
  final bool compact;

  IconData get _icon {
    switch (piece.power) {
      case PiecePower.bomb:
        return Icons.brightness_7_rounded;
      case PiecePower.rowClear:
        return Icons.swap_horiz_rounded;
      case PiecePower.columnClear:
        return Icons.swap_vert_rounded;
      case PiecePower.wild:
        return Icons.auto_awesome_rounded;
      case PiecePower.normal:
        return Icons.square_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: compact
          ? const EdgeInsets.all(5)
          : const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0806).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFFFD98B).withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(_icon, size: 12, color: const Color(0xFFFFD98B)),
          if (!compact) ...<Widget>[
            const SizedBox(width: 4),
            Text(
              piece.powerLabel,
              style: const TextStyle(
                color: Color(0xFFFFD98B),
                fontSize: 7,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GameToolButton extends StatelessWidget {
  const _GameToolButton({
    required this.icon,
    required this.label,
    required this.charge,
    required this.enabled,
    required this.accent,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final int charge;
  final bool enabled;
  final Color accent;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: enabled ? 0.18 : 0.10),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                icon,
                size: 17,
                color: enabled ? accent : Colors.white24,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                label,
                style: TextStyle(
                  color: enabled ? Colors.white70 : Colors.white24,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: enabled
                      ? accent.withValues(alpha: 0.14)
                      : Colors.white.withValues(alpha: 0.025),
                ),
                child: Text(
                  '$charge',
                  style: TextStyle(
                    color: enabled ? accent : Colors.white24,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogStat extends StatelessWidget {
  const _DialogStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 7,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _FloatingScoreFx {
  const _FloatingScoreFx({
    required this.id,
    required this.x,
    required this.y,
    required this.score,
    required this.combo,
    required this.lineCount,
    required this.perfect,
  });

  final int id;
  final double x;
  final double y;
  final int score;
  final int combo;
  final int lineCount;
  final bool perfect;
}

class _FloatingScoreOverlay extends StatelessWidget {
  const _FloatingScoreOverlay({
    required this.items,
    required this.accent,
    required this.lowFx,
  });

  final List<_FloatingScoreFx> items;
  final Color accent;
  final bool lowFx;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: items.map((item) {
        final alignment = Alignment(item.x * 2 - 1, item.y * 2 - 1);
        final important = item.perfect || item.lineCount >= 2 || item.combo >= 3;
        return Align(
          key: ValueKey<int>(item.id),
          alignment: alignment,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: Duration(milliseconds: lowFx ? 520 : 860),
            curve: Curves.easeOutCubic,
            builder: (context, progress, _) {
              final fade = progress < 0.68
                  ? 1.0
                  : ((1 - progress) / 0.32).clamp(0.0, 1.0).toDouble();
              final lift = lowFx ? 18.0 : 34.0;
              final scale = important
                  ? 0.78 + Curves.easeOutBack.transform(
                        min(1.0, progress * 1.7).toDouble(),
                      ) *
                      0.28
                  : 0.88 + progress * 0.12;
              return Opacity(
                opacity: fade,
                child: Transform.translate(
                  offset: Offset(0, -lift * progress),
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: important ? 10 : 7,
                        vertical: important ? 5 : 3,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: Colors.black.withValues(alpha: important ? 0.48 : 0.30),
                        border: Border.all(
                          color: accent.withValues(alpha: important ? 0.55 : 0.22),
                        ),
                        boxShadow: lowFx
                            ? null
                            : <BoxShadow>[
                                BoxShadow(
                                  color: accent.withValues(alpha: important ? 0.36 : 0.16),
                                  blurRadius: important ? 18 : 10,
                                ),
                              ],
                      ),
                      child: Text(
                        important && item.combo > 1
                            ? '+${item.score}  •  x${item.combo}'
                            : '+${item.score}',
                        style: TextStyle(
                          color: important ? Colors.white : accent,
                          fontSize: important ? 13 : 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: important ? 0.4 : 0.2,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _ClearShockwavePainter extends CustomPainter {
  const _ClearShockwavePainter({
    required this.progress,
    required this.cells,
    required this.boardSize,
    required this.color,
    required this.impact,
  });

  final double progress;
  final Set<int> cells;
  final int boardSize;
  final Color color;
  final int impact;

  @override
  void paint(Canvas canvas, Size size) {
    if (cells.isEmpty) return;
    var x = 0.0;
    var y = 0.0;
    for (final index in cells) {
      x += (index % boardSize) + 0.5;
      y += (index ~/ boardSize) + 0.5;
    }
    x = x / cells.length / boardSize * size.width;
    y = y / cells.length / boardSize * size.height;
    final center = Offset(x, y);
    final p = Curves.easeOutCubic.transform(progress.clamp(0.0, 1.0).toDouble());
    final alpha = (1 - progress).clamp(0.0, 1.0).toDouble();
    final baseRadius = size.shortestSide * (0.05 + 0.19 * p);

    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 + impact * 0.22
      ..color = color.withValues(alpha: 0.48 * alpha);
    canvas.drawCircle(center, baseRadius, glow);
    canvas.drawCircle(
      center,
      baseRadius * 0.62,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = Colors.white.withValues(alpha: 0.36 * alpha),
    );

    if (impact < 2) return;
    final rays = min(16, 6 + impact * 2);
    final rayPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.0
      ..color = color.withValues(alpha: 0.27 * alpha);
    for (var i = 0; i < rays; i++) {
      final angle = i / rays * pi * 2 + 0.18;
      final inner = baseRadius * 0.46;
      final outer = baseRadius * (0.78 + (i.isEven ? 0.34 : 0.18));
      canvas.drawLine(
        center + Offset(cos(angle), sin(angle)) * inner,
        center + Offset(cos(angle), sin(angle)) * outer,
        rayPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ClearShockwavePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.cells != cells ||
        oldDelegate.color != color ||
        oldDelegate.impact != impact;
  }
}

class _Material2DOverlayPainter extends CustomPainter {
  const _Material2DOverlayPainter({
    required this.progress,
    required this.cells,
    required this.boardSize,
    required this.theme,
    required this.impact,
    required this.perfect,
  });

  final double progress;
  final Set<int> cells;
  final int boardSize;
  final GameThemeData theme;
  final int impact;
  final bool perfect;

  Offset _center(Size size) {
    var x = 0.0;
    var y = 0.0;
    for (final index in cells) {
      x += (index % boardSize) + 0.5;
      y += (index ~/ boardSize) + 0.5;
    }
    return Offset(
      x / cells.length / boardSize * size.width,
      y / cells.length / boardSize * size.height,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (cells.isEmpty) return;
    final center = _center(size);
    final p = Curves.easeOutCubic.transform(
      progress.clamp(0.0, 1.0).toDouble(),
    );
    final fade = (1 - progress).clamp(0.0, 1.0).toDouble();
    final radius = size.shortestSide * (0.05 + 0.22 * p) *
        (1 + (impact - 1).clamp(0, 5) * 0.055);

    switch (theme.material) {
      case ThemeMaterial.glass:
        _paintGlass(canvas, size, center, radius, p, fade);
        break;
      case ThemeMaterial.wood:
        _paintWood(canvas, center, radius, p, fade);
        break;
      case ThemeMaterial.stone:
        _paintStone(canvas, center, radius, p, fade);
        break;
      case ThemeMaterial.leaf:
        _paintLeaf(canvas, center, radius, p, fade);
        break;
      case ThemeMaterial.crystal:
        _paintCrystal(canvas, center, radius, p, fade);
        break;
      case ThemeMaterial.marble:
        _paintMarble(canvas, center, radius, p, fade);
        break;
    }
  }

  void _paintGlass(
    Canvas canvas,
    Size size,
    Offset center,
    double radius,
    double p,
    double fade,
  ) {
    // v0.11.1: fracture starts on the real outer edge of every cleared cell,
    // then travels inward before the shards leave the board.
    final crackPhase = (progress / 0.24).clamp(0.0, 1.0).toDouble();
    final shardPhase =
        ((progress - 0.14) / 0.46).clamp(0.0, 1.0).toDouble();
    final cellW = size.width / boardSize;
    final cellH = size.height / boardSize;
    final edgeGlow = theme.blockAccent.withValues(alpha: 0.30 * fade);

    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = perfect ? 1.45 : 1.05
      ..color = Colors.white.withValues(alpha: 0.86 * fade * crackPhase);
    final edgeGlowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = perfect ? 3.4 : 2.5
      ..color = edgeGlow;

    bool cleared(int row, int col) {
      if (row < 0 || row >= boardSize || col < 0 || col >= boardSize) {
        return false;
      }
      return cells.contains(row * boardSize + col);
    }

    void jaggedEdge(Offset a, Offset b, int seed) {
      final path = Path()..moveTo(a.dx, a.dy);
      const segments = 5;
      for (var s = 1; s <= segments; s++) {
        final t = s / segments;
        final base = Offset(
          a.dx + (b.dx - a.dx) * t,
          a.dy + (b.dy - a.dy) * t,
        );
        final nx = b.dy - a.dy;
        final ny = -(b.dx - a.dx);
        final len = max(1.0, sqrt(nx * nx + ny * ny));
        final wobble =
            sin((seed + 1) * 1.73 + s * 2.21) * min(cellW, cellH) * 0.035;
        path.lineTo(base.dx + nx / len * wobble, base.dy + ny / len * wobble);
      }
      canvas.drawPath(path, edgeGlowPaint);
      canvas.drawPath(path, edgePaint);
    }

    for (final index in cells) {
      final row = index ~/ boardSize;
      final col = index % boardSize;
      final left = col * cellW;
      final top = row * cellH;
      final right = left + cellW;
      final bottom = top + cellH;
      final inset = min(cellW, cellH) * 0.08;

      if (!cleared(row - 1, col)) {
        jaggedEdge(
          Offset(left + inset, top + inset * 0.22),
          Offset(right - inset, top + inset * 0.22),
          index * 4,
        );
      }
      if (!cleared(row + 1, col)) {
        jaggedEdge(
          Offset(left + inset, bottom - inset * 0.22),
          Offset(right - inset, bottom - inset * 0.22),
          index * 4 + 1,
        );
      }
      if (!cleared(row, col - 1)) {
        jaggedEdge(
          Offset(left + inset * 0.22, top + inset),
          Offset(left + inset * 0.22, bottom - inset),
          index * 4 + 2,
        );
      }
      if (!cleared(row, col + 1)) {
        jaggedEdge(
          Offset(right - inset * 0.22, top + inset),
          Offset(right - inset * 0.22, bottom - inset),
          index * 4 + 3,
        );
      }

      if (crackPhase > 0.10) {
        final cellCenter = Offset(left + cellW * 0.5, top + cellH * 0.5);
        final spokePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 0.72
          ..color = Colors.white.withValues(alpha: 0.50 * fade * crackPhase);
        final spokes = perfect ? 5 : 3;
        for (var s = 0; s < spokes; s++) {
          final angle = (index * 0.91 + s * 2.17);
          final len = min(cellW, cellH) *
              (0.22 + 0.15 * crackPhase + (s % 2) * 0.05);
          final elbow = cellCenter +
              Offset(cos(angle), sin(angle)) * len * 0.56;
          final endAngle = angle + sin(index + s * 1.7) * 0.34;
          final end =
              elbow + Offset(cos(endAngle), sin(endAngle)) * len * 0.50;
          final path = Path()
            ..moveTo(cellCenter.dx, cellCenter.dy)
            ..lineTo(elbow.dx, elbow.dy)
            ..lineTo(end.dx, end.dy);
          canvas.drawPath(path, spokePaint);
        }
      }

      if (shardPhase > 0) {
        final shardAlpha = fade * shardPhase;
        final shardPaint = Paint()
          ..style = PaintingStyle.fill
          ..color = theme.block.withValues(alpha: 0.18 * shardAlpha);
        final shardEdge = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.72
          ..color = Colors.white.withValues(alpha: 0.56 * shardAlpha);

        for (var s = 0; s < 2; s++) {
          final angle = index * 0.83 + s * pi + 0.4;
          final travel = min(cellW, cellH) * (0.16 + 0.34 * shardPhase);
          final origin = Offset(
            left + cellW * (s == 0 ? 0.24 : 0.72),
            top + cellH * (s == 0 ? 0.20 : 0.76),
          );
          final pos = origin + Offset(cos(angle), sin(angle)) * travel;
          final r = min(cellW, cellH) * (0.09 + 0.025 * s);
          canvas.save();
          canvas.translate(pos.dx, pos.dy);
          canvas.rotate(angle + shardPhase * (s == 0 ? 1.2 : -1.0));
          final shard = Path()
            ..moveTo(-r * 0.35, -r)
            ..lineTo(r * 0.85, -r * 0.10)
            ..lineTo(-r * 0.15, r * 0.92)
            ..close();
          canvas.drawPath(shard, shardPaint);
          canvas.drawPath(shard, shardEdge);
          canvas.restore();
        }
      }
    }

    // A thin refraction flash keeps the break readable without hiding the grid.
    final flare = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = perfect ? 1.35 : 1.0
      ..color = Colors.white.withValues(alpha: 0.30 * fade);
    canvas.drawLine(
      Offset(center.dx - radius * 0.82, center.dy - radius * 0.20),
      Offset(center.dx + radius * 0.88, center.dy + radius * 0.12),
      flare,
    );
  }

  void _paintWood(
    Canvas canvas,
    Offset center,
    double radius,
    double p,
    double fade,
  ) {
    // v0.11.2: wood tears along exposed cell edges instead of exploding
    // from one artificial center point.
    final cellW = size.width / boardSize;
    final cellH = size.height / boardSize;
    final splitPhase =
        ((progress - 0.04) / 0.34).clamp(0.0, 1.0).toDouble();
    final debrisPhase =
        ((progress - 0.20) / 0.62).clamp(0.0, 1.0).toDouble();

    bool cleared(int row, int col) {
      if (row < 0 || row >= boardSize || col < 0 || col >= boardSize) {
        return false;
      }
      return cells.contains(row * boardSize + col);
    }

    final splitPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.0
      ..color = const Color(0xFFFFE2A8)
          .withValues(alpha: 0.36 * fade * splitPhase);
    final darkSplit = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.75
      ..color = const Color(0xFF3B1D0D)
          .withValues(alpha: 0.64 * fade * splitPhase);

    for (final index in cells) {
      final row = index ~/ boardSize;
      final col = index % boardSize;
      final rect = Rect.fromLTWH(col * cellW, row * cellH, cellW, cellH);
      final cx = rect.center.dx;
      final cy = rect.center.dy;

      final splits = <Path>[];
      for (var s = 0; s < 3; s++) {
        final y = rect.top + cellH * (0.28 + s * 0.22);
        final path = Path()
          ..moveTo(rect.left + cellW * 0.12, y)
          ..cubicTo(
            cx - cellW * 0.18,
            y - cellH * 0.07,
            cx + cellW * 0.10,
            y + cellH * 0.06,
            rect.right - cellW * 0.10,
            y - cellH * 0.02,
          );
        splits.add(path);
      }
      for (final path in splits) {
        canvas.drawPath(path, darkSplit);
        canvas.drawPath(path, splitPaint);
      }

      final exposed = <({Offset a, Offset b, double angle})>[];
      if (!cleared(row - 1, col)) {
        exposed.add((
          a: Offset(rect.left + cellW * 0.12, rect.top + cellH * 0.06),
          b: Offset(rect.right - cellW * 0.12, rect.top + cellH * 0.06),
          angle: -pi / 2,
        ));
      }
      if (!cleared(row + 1, col)) {
        exposed.add((
          a: Offset(rect.left + cellW * 0.12, rect.bottom - cellH * 0.06),
          b: Offset(rect.right - cellW * 0.12, rect.bottom - cellH * 0.06),
          angle: pi / 2,
        ));
      }
      if (!cleared(row, col - 1)) {
        exposed.add((
          a: Offset(rect.left + cellW * 0.06, rect.top + cellH * 0.12),
          b: Offset(rect.left + cellW * 0.06, rect.bottom - cellH * 0.12),
          angle: pi,
        ));
      }
      if (!cleared(row, col + 1)) {
        exposed.add((
          a: Offset(rect.right - cellW * 0.06, rect.top + cellH * 0.12),
          b: Offset(rect.right - cellW * 0.06, rect.bottom - cellH * 0.12),
          angle: 0,
        ));
      }

      for (var e = 0; e < exposed.length; e++) {
        final edge = exposed[e];
        final edgePath = Path()..moveTo(edge.a.dx, edge.a.dy);
        for (var s = 1; s <= 5; s++) {
          final t = s / 5;
          final base = Offset(
            edge.a.dx + (edge.b.dx - edge.a.dx) * t,
            edge.a.dy + (edge.b.dy - edge.a.dy) * t,
          );
          final wobble =
              sin(index * 1.17 + e * 2.03 + s * 2.6) * min(cellW, cellH) * 0.04;
          final normal = Offset(cos(edge.angle), sin(edge.angle));
          edgePath.lineTo(
            base.dx + normal.dx * wobble,
            base.dy + normal.dy * wobble,
          );
        }
        canvas.drawPath(edgePath, darkSplit);
        canvas.drawPath(edgePath, splitPaint);

        if (debrisPhase > 0) {
          for (var chip = 0; chip < 2; chip++) {
            final t = (chip + 1) / 3;
            final anchor = Offset(
              edge.a.dx + (edge.b.dx - edge.a.dx) * t,
              edge.a.dy + (edge.b.dy - edge.a.dy) * t,
            );
            final travel =
                min(cellW, cellH) * (0.12 + 0.24 * debrisPhase + chip * 0.03);
            final pos = anchor +
                Offset(cos(edge.angle), sin(edge.angle)) * travel;
            final length = min(cellW, cellH) * (0.17 + chip * 0.04);
            final width = max(1.5, length * 0.22);
            canvas.save();
            canvas.translate(pos.dx, pos.dy);
            canvas.rotate(edge.angle + debrisPhase * (chip.isEven ? 0.8 : -0.7));
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                Rect.fromCenter(
                  center: Offset.zero,
                  width: width,
                  height: length,
                ),
                Radius.circular(width * 0.35),
              ),
              Paint()
                ..color = theme.block.withValues(alpha: 0.82 * fade),
            );
            canvas.drawLine(
              Offset(0, -length * 0.30),
              Offset(0, length * 0.32),
              Paint()
                ..strokeWidth = 0.55
                ..color = const Color(0xFF5C2D13)
                    .withValues(alpha: 0.72 * fade),
            );
            canvas.restore();
          }
        }
      }

      if (debrisPhase > 0.1) {
        canvas.drawCircle(
          Offset(cx, cy),
          min(cellW, cellH) * 0.07 * (1 - debrisPhase * 0.45),
          Paint()
            ..color = theme.blockAccent
                .withValues(alpha: 0.10 * fade * (1 - debrisPhase)),
        );
      }
    }
  }

  void _paintStone(
    Canvas canvas,
    Offset center,
    double radius,
    double p,
    double fade,
  ) {
    final cellW = size.width / boardSize;
    final cellH = size.height / boardSize;
    final crackPhase =
        (progress / 0.30).clamp(0.0, 1.0).toDouble();
    final crumblePhase =
        ((progress - 0.16) / 0.60).clamp(0.0, 1.0).toDouble();

    bool cleared(int row, int col) {
      if (row < 0 || row >= boardSize || col < 0 || col >= boardSize) {
        return false;
      }
      return cells.contains(row * boardSize + col);
    }

    final crack = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.05
      ..color = const Color(0xFF11171B)
          .withValues(alpha: 0.78 * fade * crackPhase);
    final crackLight = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.72
      ..color = theme.blockAccent.withValues(alpha: 0.30 * fade * crackPhase);

    for (final index in cells) {
      final row = index ~/ boardSize;
      final col = index % boardSize;
      final rect = Rect.fromLTWH(col * cellW, row * cellH, cellW, cellH);
      final c0 = rect.center;

      for (var s = 0; s < 5; s++) {
        final angle = index * 0.73 + s * (pi * 2 / 5);
        final elbow = c0 +
            Offset(cos(angle), sin(angle)) *
                min(cellW, cellH) * (0.12 + 0.10 * crackPhase);
        final endAngle = angle + sin(index * 0.7 + s * 1.9) * 0.36;
        final end = c0 +
            Offset(cos(endAngle), sin(endAngle)) *
                min(cellW, cellH) * (0.27 + 0.16 * crackPhase);
        final path = Path()
          ..moveTo(c0.dx, c0.dy)
          ..lineTo(elbow.dx, elbow.dy)
          ..lineTo(end.dx, end.dy);
        canvas.drawPath(path, crackLight);
        canvas.drawPath(path, crack);
      }

      final exposedAngles = <double>[];
      if (!cleared(row - 1, col)) exposedAngles.add(-pi / 2);
      if (!cleared(row + 1, col)) exposedAngles.add(pi / 2);
      if (!cleared(row, col - 1)) exposedAngles.add(pi);
      if (!cleared(row, col + 1)) exposedAngles.add(0);

      for (var e = 0; e < exposedAngles.length; e++) {
        final angle = exposedAngles[e];
        final base = c0 +
            Offset(cos(angle), sin(angle)) *
                min(cellW, cellH) * 0.42;
        if (crumblePhase > 0) {
          for (var rock = 0; rock < 2; rock++) {
            final spread = (rock == 0 ? -1 : 1) * 0.22;
            final a = angle + spread;
            final travel =
                min(cellW, cellH) * (0.10 + crumblePhase * (0.26 + rock * 0.05));
            final pos = base + Offset(cos(a), sin(a)) * travel;
            final r = min(cellW, cellH) * (0.055 + rock * 0.018);
            final poly = Path()
              ..moveTo(-r, -r * 0.24)
              ..lineTo(-r * 0.28, -r)
              ..lineTo(r * 0.86, -r * 0.48)
              ..lineTo(r, r * 0.40)
              ..lineTo(r * 0.08, r)
              ..lineTo(-r * 0.80, r * 0.42)
              ..close();
            canvas.save();
            canvas.translate(pos.dx, pos.dy);
            canvas.rotate(a + crumblePhase * (rock == 0 ? 1.1 : -0.9));
            canvas.drawPath(
              poly,
              Paint()..color = theme.block.withValues(alpha: 0.90 * fade),
            );
            canvas.drawPath(
              poly,
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 0.60
                ..color = theme.blockAccent.withValues(alpha: 0.24 * fade),
            );
            canvas.restore();
          }

          final dustPaint = Paint();
          for (var d = 0; d < 3; d++) {
            final a = angle + (d - 1) * 0.20;
            final travel = min(cellW, cellH) *
                (0.18 + crumblePhase * (0.22 + d * 0.04));
            final pos = base + Offset(cos(a), sin(a)) * travel;
            dustPaint.color = Color.lerp(theme.block, Colors.white, 0.22)!
                .withValues(alpha: 0.12 * fade * (1 - crumblePhase * 0.4));
            canvas.drawCircle(
              pos,
              min(cellW, cellH) * (0.035 + d * 0.012),
              dustPaint,
            );
          }
        }
      }
    }
  }

  void _paintLeaf(
    Canvas canvas,
    Offset center,
    double radius,
    double p,
    double fade,
  ) {
    // v0.11.3: leaf material separates as fibers and curled fragments.
    final cellW = size.width / boardSize;
    final cellH = size.height / boardSize;
    final tearPhase =
        (progress / 0.30).clamp(0.0, 1.0).toDouble();
    final driftPhase =
        ((progress - 0.16) / 0.72).clamp(0.0, 1.0).toDouble();

    bool cleared(int row, int col) {
      if (row < 0 || row >= boardSize || col < 0 || col >= boardSize) {
        return false;
      }
      return cells.contains(row * boardSize + col);
    }

    final vein = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.82
      ..color = const Color(0xFFE3FFBD)
          .withValues(alpha: 0.48 * fade * tearPhase);
    final tear = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.0
      ..color = const Color(0xFF143F24)
          .withValues(alpha: 0.72 * fade * tearPhase);

    for (final index in cells) {
      final row = index ~/ boardSize;
      final col = index % boardSize;
      final rect = Rect.fromLTWH(col * cellW, row * cellH, cellW, cellH);
      final c0 = rect.center;

      final mainPath = Path()
        ..moveTo(rect.left + cellW * 0.12, rect.bottom - cellH * 0.16)
        ..quadraticBezierTo(
          c0.dx,
          c0.dy - cellH * 0.05,
          rect.right - cellW * 0.12,
          rect.top + cellH * 0.14,
        );
      canvas.drawPath(mainPath, vein);

      for (var s = 0; s < 3; s++) {
        final t = 0.30 + s * 0.18;
        final x = rect.left + cellW * t;
        final y = rect.bottom - cellH * (0.18 + t * 0.58);
        canvas.drawLine(
          Offset(x, y),
          Offset(x - cellW * 0.16, y - cellH * 0.07),
          vein,
        );
        canvas.drawLine(
          Offset(x, y),
          Offset(x + cellW * 0.14, y + cellH * 0.06),
          vein,
        );
      }

      final exposedAngles = <double>[];
      if (!cleared(row - 1, col)) exposedAngles.add(-pi / 2);
      if (!cleared(row + 1, col)) exposedAngles.add(pi / 2);
      if (!cleared(row, col - 1)) exposedAngles.add(pi);
      if (!cleared(row, col + 1)) exposedAngles.add(0);

      for (var e = 0; e < exposedAngles.length; e++) {
        final angle = exposedAngles[e];
        final tangent = angle + pi / 2;
        final edgeCenter = c0 +
            Offset(cos(angle), sin(angle)) *
                min(cellW, cellH) * 0.42;
        final path = Path()
          ..moveTo(
            edgeCenter.dx - cos(tangent) * min(cellW, cellH) * 0.32,
            edgeCenter.dy - sin(tangent) * min(cellW, cellH) * 0.32,
          );
        for (var s = 1; s <= 6; s++) {
          final t = s / 6;
          final along = (t - 0.5) * min(cellW, cellH) * 0.64;
          final fray =
              sin(index * 1.31 + e * 2.4 + s * 2.17) * min(cellW, cellH) * 0.035;
          path.lineTo(
            edgeCenter.dx + cos(tangent) * along + cos(angle) * fray,
            edgeCenter.dy + sin(tangent) * along + sin(angle) * fray,
          );
        }
        canvas.drawPath(path, tear);

        if (driftPhase > 0) {
          for (var flake = 0; flake < 2; flake++) {
            final along =
                (flake == 0 ? -0.18 : 0.18) * min(cellW, cellH);
            final start = edgeCenter +
                Offset(cos(tangent), sin(tangent)) * along;
            final sway = sin(index * 0.81 + e + flake * 2.0 + driftPhase * 7) *
                min(cellW, cellH) *
                0.10 *
                driftPhase;
            final travel = min(cellW, cellH) *
                (0.12 + driftPhase * (0.28 + flake * 0.05));
            final pos = start +
                Offset(cos(angle), sin(angle)) * travel +
                Offset(cos(tangent), sin(tangent)) * sway;
            final r = min(cellW, cellH) * (0.07 + flake * 0.015);
            canvas.save();
            canvas.translate(pos.dx, pos.dy);
            canvas.rotate(
              tangent + driftPhase * (flake == 0 ? 1.6 : -1.35),
            );
            final leaf = Path()
              ..moveTo(-r * 1.20, 0)
              ..quadraticBezierTo(0, -r * 0.88, r * 1.20, 0)
              ..quadraticBezierTo(0, r * 0.88, -r * 1.20, 0)
              ..close();
            canvas.drawPath(
              leaf,
              Paint()
                ..color = theme.block.withValues(alpha: 0.86 * fade),
            );
            canvas.drawLine(
              Offset(-r * 0.72, 0),
              Offset(r * 0.72, 0),
              Paint()
                ..strokeWidth = 0.55
                ..color = theme.blockAccent.withValues(alpha: 0.56 * fade),
            );
            canvas.restore();
          }
        }
      }
    }

    // Soft airflow is deliberately subtle; the fragments remain the hero.
    final wind = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.85
      ..color = theme.blockAccent.withValues(alpha: 0.16 * fade);
    for (var i = 0; i < 2; i++) {
      final y = center.dy + (i == 0 ? -1 : 1) * radius * 0.20;
      final path = Path()
        ..moveTo(center.dx - radius * 0.72, y)
        ..quadraticBezierTo(
          center.dx,
          y - radius * (0.20 + i * 0.05),
          center.dx + radius * 0.78,
          y + radius * 0.08,
        );
      canvas.drawPath(path, wind);
    }
  }

  void _paintCrystal(
    Canvas canvas,
    Offset center,
    double radius,
    double p,
    double fade,
  ) {
    final cellW = size.width / boardSize;
    final cellH = size.height / boardSize;
    final splitPhase =
        (progress / 0.24).clamp(0.0, 1.0).toDouble();
    final burstPhase =
        ((progress - 0.12) / 0.54).clamp(0.0, 1.0).toDouble();

    bool cleared(int row, int col) {
      if (row < 0 || row >= boardSize || col < 0 || col >= boardSize) {
        return false;
      }
      return cells.contains(row * boardSize + col);
    }

    final facet = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.84
      ..color = Colors.white.withValues(alpha: 0.58 * fade * splitPhase);
    final neonEdge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.2
      ..color = theme.blockAccent.withValues(alpha: 0.20 * fade * splitPhase);

    for (final index in cells) {
      final row = index ~/ boardSize;
      final col = index % boardSize;
      final rect = Rect.fromLTWH(col * cellW, row * cellH, cellW, cellH);
      final c0 = rect.center;
      final r = min(cellW, cellH);

      for (var s = 0; s < 6; s++) {
        final angle = s * pi / 3 + index * 0.27;
        final end = c0 +
            Offset(cos(angle), sin(angle)) *
                r *
                (0.22 + 0.17 * splitPhase);
        canvas.drawLine(c0, end, neonEdge);
        canvas.drawLine(c0, end, facet);
      }

      final exposedAngles = <double>[];
      if (!cleared(row - 1, col)) exposedAngles.add(-pi / 2);
      if (!cleared(row + 1, col)) exposedAngles.add(pi / 2);
      if (!cleared(row, col - 1)) exposedAngles.add(pi);
      if (!cleared(row, col + 1)) exposedAngles.add(0);

      for (var e = 0; e < exposedAngles.length; e++) {
        final angle = exposedAngles[e];
        final edgeCenter =
            c0 + Offset(cos(angle), sin(angle)) * r * 0.42;
        final tangent = angle + pi / 2;

        canvas.drawLine(
          edgeCenter - Offset(cos(tangent), sin(tangent)) * r * 0.31,
          edgeCenter + Offset(cos(tangent), sin(tangent)) * r * 0.31,
          neonEdge,
        );
        canvas.drawLine(
          edgeCenter - Offset(cos(tangent), sin(tangent)) * r * 0.31,
          edgeCenter + Offset(cos(tangent), sin(tangent)) * r * 0.31,
          facet,
        );

        if (burstPhase > 0) {
          for (var shard = 0; shard < 2; shard++) {
            final spread = (shard == 0 ? -0.17 : 0.17);
            final a = angle + spread;
            final travel = r * (0.12 + burstPhase * (0.34 + shard * 0.05));
            final pos = edgeCenter + Offset(cos(a), sin(a)) * travel;
            final sr = r * (0.075 + shard * 0.018);
            canvas.save();
            canvas.translate(pos.dx, pos.dy);
            canvas.rotate(a + burstPhase * (shard == 0 ? 1.45 : -1.25));
            final diamond = Path()
              ..moveTo(0, -sr * 1.25)
              ..lineTo(sr * 0.86, -sr * 0.12)
              ..lineTo(sr * 0.38, sr)
              ..lineTo(-sr * 0.38, sr)
              ..lineTo(-sr * 0.86, -sr * 0.12)
              ..close();
            canvas.drawPath(
              diamond,
              Paint()
                ..color = theme.block.withValues(alpha: 0.62 * fade),
            );
            canvas.drawPath(
              diamond,
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 0.72
                ..color = Colors.white.withValues(alpha: 0.72 * fade),
            );
            canvas.drawLine(
              Offset.zero,
              Offset(0, -sr * 0.90),
              Paint()
                ..strokeWidth = 0.55
                ..color = theme.blockAccent.withValues(alpha: 0.86 * fade),
            );
            canvas.restore();
          }
        }
      }
    }

    // Short spectral rays appear only during the actual fracture peak.
    final spectral = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.95
      ..color = theme.blockAccent.withValues(
        alpha: 0.24 * fade * (1 - burstPhase * 0.35),
      );
    final rays = 8 + min(6, impact);
    for (var i = 0; i < rays; i++) {
      final angle = i / rays * pi * 2 + 0.15;
      final start = center + Offset(cos(angle), sin(angle)) * radius * 0.34;
      final end = center +
          Offset(cos(angle), sin(angle)) *
              radius *
              (0.66 + burstPhase * 0.30);
      canvas.drawLine(start, end, spectral);
    }
  }

  void _paintMarble(
    Canvas canvas,
    Offset center,
    double radius,
    double p,
    double fade,
  ) {
    final cellW = size.width / boardSize;
    final cellH = size.height / boardSize;
    final crackPhase =
        (progress / 0.32).clamp(0.0, 1.0).toDouble();
    final chipPhase =
        ((progress - 0.18) / 0.62).clamp(0.0, 1.0).toDouble();

    bool cleared(int row, int col) {
      if (row < 0 || row >= boardSize || col < 0 || col >= boardSize) {
        return false;
      }
      return cells.contains(row * boardSize + col);
    }

    final vein = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.95
      ..color = const Color(0xFF554B41)
          .withValues(alpha: 0.66 * fade * crackPhase);
    final gold = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.82
      ..color = theme.blockAccent
          .withValues(alpha: 0.62 * fade * crackPhase);

    for (final index in cells) {
      final row = index ~/ boardSize;
      final col = index % boardSize;
      final rect = Rect.fromLTWH(col * cellW, row * cellH, cellW, cellH);
      final c0 = rect.center;
      final r = min(cellW, cellH);

      for (var s = 0; s < 4; s++) {
        final angle = index * 0.61 + s * pi / 2;
        final start = c0 + Offset(cos(angle), sin(angle)) * r * 0.05;
        final control = c0 +
            Offset(cos(angle + 0.42), sin(angle + 0.42)) * r * 0.25;
        final end = c0 +
            Offset(cos(angle), sin(angle)) *
                r *
                (0.28 + 0.12 * crackPhase);
        final path = Path()
          ..moveTo(start.dx, start.dy)
          ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
        canvas.drawPath(path, s.isEven ? vein : gold);
      }

      final exposedAngles = <double>[];
      if (!cleared(row - 1, col)) exposedAngles.add(-pi / 2);
      if (!cleared(row + 1, col)) exposedAngles.add(pi / 2);
      if (!cleared(row, col - 1)) exposedAngles.add(pi);
      if (!cleared(row, col + 1)) exposedAngles.add(0);

      for (var e = 0; e < exposedAngles.length; e++) {
        final angle = exposedAngles[e];
        final tangent = angle + pi / 2;
        final edgeCenter =
            c0 + Offset(cos(angle), sin(angle)) * r * 0.42;

        final edgePath = Path()
          ..moveTo(
            edgeCenter.dx - cos(tangent) * r * 0.30,
            edgeCenter.dy - sin(tangent) * r * 0.30,
          );
        for (var s = 1; s <= 5; s++) {
          final t = s / 5;
          final along = (t - 0.5) * r * 0.60;
          final wobble =
              sin(index * 1.13 + e * 1.9 + s * 2.4) * r * 0.035;
          edgePath.lineTo(
            edgeCenter.dx + cos(tangent) * along + cos(angle) * wobble,
            edgeCenter.dy + sin(tangent) * along + sin(angle) * wobble,
          );
        }
        canvas.drawPath(edgePath, vein);
        if ((index + e).isEven) {
          canvas.drawPath(edgePath, gold);
        }

        if (chipPhase > 0) {
          for (var chip = 0; chip < 2; chip++) {
            final spread = (chip == 0 ? -0.16 : 0.16);
            final a = angle + spread;
            final travel = r * (0.10 + chipPhase * (0.30 + chip * 0.05));
            final pos = edgeCenter + Offset(cos(a), sin(a)) * travel;
            final sr = r * (0.060 + chip * 0.016);
            final shard = Path()
              ..moveTo(-sr * 0.90, -sr * 0.34)
              ..lineTo(-sr * 0.20, -sr)
              ..lineTo(sr * 0.82, -sr * 0.40)
              ..lineTo(sr * 0.60, sr * 0.78)
              ..lineTo(-sr * 0.54, sr)
              ..close();
            canvas.save();
            canvas.translate(pos.dx, pos.dy);
            canvas.rotate(a + chipPhase * (chip == 0 ? 0.82 : -0.74));
            canvas.drawPath(
              shard,
              Paint()
                ..color = Color.lerp(theme.block, Colors.white, 0.18)!
                    .withValues(alpha: 0.92 * fade),
            );
            canvas.drawPath(
              shard,
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 0.62
                ..color = theme.blockAccent.withValues(alpha: 0.42 * fade),
            );
            canvas.restore();
          }
        }
      }
    }

    if (chipPhase > 0) {
      final dust = Paint()..style = PaintingStyle.fill;
      for (var i = 0; i < 14; i++) {
        final angle = i / 14 * pi * 2 + 0.16;
        final rr = radius * (0.30 + (i % 4) * 0.14) * chipPhase;
        final point = center + Offset(cos(angle), sin(angle)) * rr;
        dust.color = (i % 3 == 0 ? theme.blockAccent : Colors.white)
            .withValues(alpha: 0.15 * fade * (1 - chipPhase * 0.35));
        canvas.drawCircle(point, 1.0 + (i % 3) * 0.65, dust);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _Material2DOverlayPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.cells != cells ||
        oldDelegate.theme != theme ||
        oldDelegate.impact != impact ||
        oldDelegate.perfect != perfect;
  }
}

class _LiveRecordOverlay extends StatelessWidget {
  const _LiveRecordOverlay({required this.accent, required this.lowFx});

  final Color accent;
  final bool lowFx;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: lowFx ? 650 : 1250),
      curve: Curves.easeOutCubic,
      builder: (context, progress, _) {
        final fade = progress < 0.72
            ? 1.0
            : ((1 - progress) / 0.28).clamp(0.0, 1.0).toDouble();
        final scale = 0.78 + Curves.easeOutBack.transform(min(1.0, progress * 1.8).toDouble()) * 0.24;
        return Opacity(
          opacity: fade,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: <Color>[
                  accent.withValues(alpha: 0.20 * fade),
                  Colors.transparent,
                ],
              ),
            ),
            child: Transform.scale(
              scale: scale,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.46),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: accent.withValues(alpha: 0.62)),
                  boxShadow: lowFx
                      ? null
                      : <BoxShadow>[
                          BoxShadow(
                            color: accent.withValues(alpha: 0.34),
                            blurRadius: 28,
                          ),
                        ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text('🎉  🎊  🎁', style: TextStyle(fontSize: 20)),
                    const SizedBox(height: 5),
                    Text(
                      'YENİ REKOR',
                      style: TextStyle(
                        color: accent,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Particle {
  const _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.angle,
    required this.spin,
  });

  final double x;
  final double y;
  final double vx;
  final double vy;
  final double radius;
  final double angle;
  final double spin;
}

class _ParticleBurstPainter extends CustomPainter {
  const _ParticleBurstPainter({
    required this.particles,
    required this.progress,
    required this.color,
    required this.baseColor,
    required this.material,
  });

  final List<_Particle> particles;
  final double progress;
  final Color color;
  final Color baseColor;
  final ThemeMaterial material;

  @override
  void paint(Canvas canvas, Size size) {
    final t = Curves.easeOutCubic.transform(
      progress.clamp(0.0, 1.0).toDouble(),
    );
    final alpha = (1 - progress).clamp(0.0, 1.0).toDouble();

    var gravity = 0.11;
    var sway = 0.0;
    var shrink = 0.30;
    switch (material) {
      case ThemeMaterial.glass:
        gravity = 0.075;
        shrink = 0.18;
        break;
      case ThemeMaterial.wood:
        gravity = 0.14;
        sway = 0.006;
        break;
      case ThemeMaterial.stone:
        gravity = 0.18;
        shrink = 0.24;
        break;
      case ThemeMaterial.leaf:
        gravity = 0.055;
        sway = 0.022;
        shrink = 0.12;
        break;
      case ThemeMaterial.crystal:
        gravity = 0.07;
        shrink = 0.16;
        break;
      case ThemeMaterial.marble:
        gravity = 0.17;
        shrink = 0.23;
        break;
    }

    for (var i = 0; i < particles.length; i++) {
      final particle = particles[i];
      final wave = sway == 0
          ? 0.0
          : sin(particle.angle * 2.2 + t * 9 + i * 0.7) * sway * t;
      final x = (particle.x + particle.vx * t + wave) * size.width;
      final y = (particle.y + particle.vy * t + gravity * t * t) * size.height;
      final radius = particle.radius * max(0.34, 1 - shrink * t);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.angle + particle.spin * t);
      _drawParticle(canvas, radius, alpha, i);
      canvas.restore();
    }
  }

  void _drawParticle(Canvas canvas, double r, double alpha, int index) {
    final materialFill = Paint()
      ..style = PaintingStyle.fill
      ..color = baseColor.withValues(alpha: 0.86 * alpha);
    final accentFill = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: 0.78 * alpha);
    final highlight = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.75 + (index % 2) * 0.25
      ..color = Colors.white.withValues(alpha: 0.70 * alpha);

    switch (material) {
      case ThemeMaterial.glass:
        final shard = Path()
          ..moveTo(-r * 0.34, -r * 1.28)
          ..lineTo(r * 0.92, -r * 0.12)
          ..lineTo(-r * 0.10, r * 1.08)
          ..close();
        final glass = Paint()
          ..style = PaintingStyle.fill
          ..color = Color.lerp(baseColor, Colors.white, 0.35)!
              .withValues(alpha: 0.28 * alpha);
        canvas.drawPath(shard, glass);
        canvas.drawPath(shard, highlight);
        canvas.drawLine(
          Offset(-r * 0.12, -r * 0.92),
          Offset(r * 0.48, -r * 0.28),
          Paint()
            ..strokeWidth = 0.65
            ..color = Colors.white.withValues(alpha: 0.82 * alpha),
        );
        break;
      case ThemeMaterial.wood:
        final chip = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: r * (index.isEven ? 0.68 : 0.48),
            height: r * (index.isEven ? 2.35 : 1.75),
          ),
          Radius.circular(r * 0.20),
        );
        canvas.drawRRect(chip, materialFill);
        canvas.drawLine(
          Offset(0, -r * 0.82),
          Offset(0, r * 0.82),
          Paint()
            ..strokeWidth = 0.6
            ..color = color.withValues(alpha: 0.55 * alpha),
        );
        break;
      case ThemeMaterial.stone:
        final rock = Path()
          ..moveTo(-r, -r * 0.22)
          ..lineTo(-r * 0.38, -r)
          ..lineTo(r * 0.75, -r * 0.58)
          ..lineTo(r, r * 0.34)
          ..lineTo(r * 0.16, r)
          ..lineTo(-r * 0.84, r * 0.48)
          ..close();
        canvas.drawPath(rock, materialFill);
        canvas.drawLine(
          Offset(-r * 0.32, -r * 0.18),
          Offset(r * 0.42, r * 0.28),
          Paint()
            ..strokeWidth = 0.7
            ..color = color.withValues(alpha: 0.46 * alpha),
        );
        break;
      case ThemeMaterial.leaf:
        final leaf = Path()
          ..moveTo(-r * 1.18, 0)
          ..quadraticBezierTo(0, -r, r * 1.18, 0)
          ..quadraticBezierTo(0, r, -r * 1.18, 0)
          ..close();
        canvas.drawPath(leaf, index.isEven ? materialFill : accentFill);
        canvas.drawLine(
          Offset(-r * 0.78, 0),
          Offset(r * 0.78, 0),
          highlight,
        );
        break;
      case ThemeMaterial.crystal:
        final crystal = Path()
          ..moveTo(0, -r * 1.25)
          ..lineTo(r * 0.90, -r * 0.18)
          ..lineTo(r * 0.46, r)
          ..lineTo(-r * 0.46, r)
          ..lineTo(-r * 0.90, -r * 0.18)
          ..close();
        canvas.drawPath(crystal, accentFill);
        canvas.drawPath(crystal, highlight);
        canvas.drawLine(
          const Offset(0, 0),
          Offset(0, -r * 0.90),
          highlight,
        );
        break;
      case ThemeMaterial.marble:
        final chip = Path()
          ..moveTo(-r * 0.90, -r * 0.35)
          ..lineTo(-r * 0.20, -r)
          ..lineTo(r * 0.82, -r * 0.42)
          ..lineTo(r * 0.62, r * 0.76)
          ..lineTo(-r * 0.55, r)
          ..close();
        canvas.drawPath(chip, materialFill);
        canvas.drawPath(
          Path()
            ..moveTo(-r * 0.52, r * 0.42)
            ..quadraticBezierTo(0, -r * 0.35, r * 0.60, r * 0.08),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.72
            ..color = color.withValues(alpha: 0.66 * alpha),
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _ParticleBurstPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.particles != particles ||
        oldDelegate.color != color ||
        oldDelegate.baseColor != baseColor ||
        oldDelegate.material != material;
  }
}

class _Combo2DSplash extends StatelessWidget {
  const _Combo2DSplash({
    required this.animation,
    required this.combo,
    required this.accent,
  });

  final Animation<double> animation;
  final int combo;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final p = animation.value.clamp(0.0, 1.0).toDouble();
        final entry = Curves.easeOutBack.transform(min(1.0, p * 2.4).toDouble());
        final fade = p < 0.62
            ? 1.0
            : ((1 - p) / 0.38).clamp(0.0, 1.0).toDouble();
        final label = combo >= 8
            ? 'OVERDRIVE x$combo'
            : combo >= 5
                ? 'MEGA COMBO x$combo'
                : 'COMBO x$combo';
        return Opacity(
          opacity: fade,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Positioned.fill(
                child: CustomPaint(
                  painter: _ComboStarburstPainter(
                    progress: p,
                    accent: accent,
                    combo: combo,
                  ),
                ),
              ),
              Transform.scale(
                scale: 0.62 + entry * 0.38,
                child: Transform.rotate(
                  angle: sin(p * pi) * 0.015,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: Colors.black.withValues(alpha: 0.44),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.70),
                        width: 1.2,
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: accent.withValues(alpha: 0.34 * fade),
                          blurRadius: 26,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: combo >= 5 ? 16 : 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                        shadows: <Shadow>[
                          Shadow(
                            color: accent.withValues(alpha: 0.85),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ComboStarburstPainter extends CustomPainter {
  const _ComboStarburstPainter({
    required this.progress,
    required this.accent,
    required this.combo,
  });

  final double progress;
  final Color accent;
  final int combo;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final p = Curves.easeOutCubic.transform(progress);
    final fade = (1 - progress).clamp(0.0, 1.0).toDouble();
    final rays = min(24, 10 + combo * 2);
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = combo >= 5 ? 1.4 : 1.0
      ..color = accent.withValues(alpha: 0.40 * fade);
    final base = size.shortestSide * (0.08 + 0.10 * p);
    for (var i = 0; i < rays; i++) {
      final angle = i / rays * pi * 2 + progress * 0.18;
      final inner = base * (0.58 + (i % 2) * 0.10);
      final outer = base * (1.05 + (i % 3) * 0.18);
      canvas.drawLine(
        center + Offset(cos(angle), sin(angle)) * inner,
        center + Offset(cos(angle), sin(angle)) * outer,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ComboStarburstPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.accent != accent ||
      oldDelegate.combo != combo;
}

class _PerfectClearOverlay extends StatelessWidget {
  const _PerfectClearOverlay({
    required this.animation,
    required this.theme,
  });

  final Animation<double> animation;
  final GameThemeData theme;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final p = animation.value.clamp(0.0, 1.0).toDouble();
        final inScale = 0.72 + Curves.easeOutBack.transform(p) * 0.28;
        final alpha = p < 0.78 ? 1.0 : ((1 - p) / 0.22).clamp(0.0, 1.0).toDouble();
        return Opacity(
          opacity: alpha,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: <Color>[
                  theme.blockAccent.withValues(alpha: 0.26 * (1 - p * 0.55)),
                  theme.block.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
              ),
            ),
            child: Transform.scale(
              scale: inScale,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.black.withValues(alpha: 0.36),
                  border: Border.all(
                    color: theme.blockAccent.withValues(alpha: 0.72),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.auto_awesome_rounded, color: theme.blockAccent, size: 30),
                    const SizedBox(height: 5),
                    Text(
                      'PERFECT CLEAR',
                      style: TextStyle(
                        color: theme.blockAccent,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      '+1000',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}


class _MaterialEventBanner extends StatelessWidget {
  const _MaterialEventBanner({
    required this.text,
    required this.theme,
    required this.lowFx,
  });

  final String text;
  final GameThemeData theme;
  final bool lowFx;

  IconData get _icon {
    switch (theme.material) {
      case ThemeMaterial.glass:
        return Icons.auto_awesome_rounded;
      case ThemeMaterial.wood:
        return Icons.park_rounded;
      case ThemeMaterial.stone:
        return Icons.landscape_rounded;
      case ThemeMaterial.leaf:
        return Icons.eco_rounded;
      case ThemeMaterial.crystal:
        return Icons.diamond_rounded;
      case ThemeMaterial.marble:
        return Icons.texture_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: theme.board.withValues(alpha: 0.72),
        border: Border.all(color: theme.blockAccent.withValues(alpha: 0.38)),
        boxShadow: lowFx
            ? null
            : <BoxShadow>[
                BoxShadow(
                  color: theme.blockAccent.withValues(alpha: 0.18),
                  blurRadius: 18,
                ),
              ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(_icon, size: 15, color: theme.blockAccent),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.blockAccent,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.05,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedFinalScore extends StatelessWidget {
  const _AnimatedFinalScore({
    required this.score,
    required this.accent,
    required this.lowFx,
  });

  final int score;
  final Color accent;
  final bool lowFx;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1050),
      curve: Curves.easeOutExpo,
      builder: (context, progress, _) {
        final value = (score * progress).round();
        final pulse = lowFx ? 1.0 : 1.0 + sin(progress * pi) * 0.075;
        return Transform.scale(
          scale: pulse,
          child: Text(
            '$value',
            style: TextStyle(
              color: Colors.white,
              fontSize: 44,
              fontWeight: FontWeight.w900,
              shadows: lowFx
                  ? null
                  : <Shadow>[
                      Shadow(
                        color: accent.withValues(alpha: 0.72 * progress),
                        blurRadius: 24,
                      ),
                    ],
            ),
          ),
        );
      },
    );
  }
}

class _GameOverMaterialFx extends StatelessWidget {
  const _GameOverMaterialFx({required this.theme, required this.lowFx});

  final GameThemeData theme;
  final bool lowFx;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: lowFx ? 450 : 1450),
      curve: Curves.easeOutCubic,
      builder: (context, progress, _) {
        return CustomPaint(
          painter: _GameOverDebrisPainter(
            progress: progress,
            theme: theme,
            lowFx: lowFx,
          ),
        );
      },
    );
  }
}

class _GameOverDebrisPainter extends CustomPainter {
  const _GameOverDebrisPainter({
    required this.progress,
    required this.theme,
    required this.lowFx,
  });

  final double progress;
  final GameThemeData theme;
  final bool lowFx;

  @override
  void paint(Canvas canvas, Size size) {
    final count = lowFx ? 12 : 30;
    final t = Curves.easeOutCubic.transform(
      progress.clamp(0.0, 1.0).toDouble(),
    );
    for (var i = 0; i < count; i++) {
      final seed = i * 13.73 + theme.material.index * 7.11;
      final edgeLeft = i.isEven;
      final baseX = edgeLeft ? 0.02 + (sin(seed) + 1) * 0.065 : 0.85 + (sin(seed) + 1) * 0.065;
      final baseY = 0.04 + ((cos(seed * 1.31) + 1) * 0.46);
      final driftX = (edgeLeft ? 1 : -1) * (0.025 + (i % 4) * 0.008) * t;
      final driftY = (0.03 + (i % 5) * 0.008) * t;
      final x = (baseX + driftX) * size.width;
      final y = (baseY + driftY) * size.height;
      final r = 2.8 + (i % 5) * 0.75;
      final alpha = (0.18 + (i % 4) * 0.055) * (0.75 + 0.25 * (1 - progress));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(seed * 0.22 + t * (edgeLeft ? 1.2 : -1.2));
      _drawMaterial(canvas, r, alpha.clamp(0.0, 0.48).toDouble());
      canvas.restore();
    }
  }

  void _drawMaterial(Canvas canvas, double r, double alpha) {
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = theme.block.withValues(alpha: alpha);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75
      ..color = theme.blockAccent.withValues(alpha: min(0.60, alpha + 0.18));

    switch (theme.material) {
      case ThemeMaterial.glass:
        final shard = Path()
          ..moveTo(-r * 0.35, -r * 1.25)
          ..lineTo(r, -r * 0.18)
          ..lineTo(-r * 0.08, r * 1.15)
          ..close();
        canvas.drawPath(shard, fill);
        canvas.drawPath(shard, line);
        break;
      case ThemeMaterial.wood:
        final chip = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: r * 0.8, height: r * 2.3),
          Radius.circular(r * 0.25),
        );
        canvas.drawRRect(chip, fill);
        canvas.drawLine(Offset(0, -r), Offset(0, r), line);
        break;
      case ThemeMaterial.stone:
        final rock = Path()
          ..moveTo(-r, -r * 0.15)
          ..lineTo(-r * 0.38, -r)
          ..lineTo(r * 0.84, -r * 0.54)
          ..lineTo(r, r * 0.42)
          ..lineTo(r * 0.05, r)
          ..lineTo(-r * 0.82, r * 0.46)
          ..close();
        canvas.drawPath(rock, fill);
        canvas.drawPath(rock, line);
        break;
      case ThemeMaterial.leaf:
        final leaf = Path()
          ..moveTo(-r * 1.15, 0)
          ..quadraticBezierTo(0, -r, r * 1.15, 0)
          ..quadraticBezierTo(0, r, -r * 1.15, 0)
          ..close();
        canvas.drawPath(leaf, fill);
        canvas.drawLine(Offset(-r * 0.75, 0), Offset(r * 0.75, 0), line);
        break;
      case ThemeMaterial.crystal:
        final crystal = Path()
          ..moveTo(0, -r * 1.2)
          ..lineTo(r, 0)
          ..lineTo(0, r * 1.2)
          ..lineTo(-r, 0)
          ..close();
        canvas.drawPath(crystal, fill);
        canvas.drawPath(crystal, line);
        break;
      case ThemeMaterial.marble:
        canvas.drawCircle(Offset.zero, r * 0.72, fill);
        canvas.drawArc(
          Rect.fromCircle(center: Offset.zero, radius: r * 0.55),
          -0.9,
          1.5,
          false,
          line,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _GameOverDebrisPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.theme != theme ||
      oldDelegate.lowFx != lowFx;
}

class _RecordCelebrationStrip extends StatelessWidget {
  const _RecordCelebrationStrip({required this.theme});

  final GameThemeData theme;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1150),
      curve: Curves.easeOutCubic,
      builder: (context, progress, child) {
        final pop = 0.82 + Curves.easeOutBack.transform(progress) * 0.18;
        return SizedBox(
          height: 72,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _RecordConfettiPainter(
                      progress: progress,
                      color: theme.blockAccent,
                    ),
                  ),
                ),
              ),
              Transform.scale(
                scale: pop,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: theme.blockAccent.withValues(alpha: 0.10),
                    border: Border.all(
                      color: theme.blockAccent.withValues(alpha: 0.34),
                    ),
                  ),
                  child: const Text(
                    '🎉  🎊  🎁',
                    style: TextStyle(fontSize: 25),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RecordConfettiPainter extends CustomPainter {
  const _RecordConfettiPainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  static const List<Offset> _starts = <Offset>[
    Offset(0.12, 0.55),
    Offset(0.20, 0.72),
    Offset(0.29, 0.45),
    Offset(0.38, 0.70),
    Offset(0.62, 0.70),
    Offset(0.71, 0.45),
    Offset(0.80, 0.72),
    Offset(0.88, 0.55),
    Offset(0.46, 0.34),
    Offset(0.54, 0.34),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final t = Curves.easeOutCubic.transform(
      progress.clamp(0.0, 1.0).toDouble(),
    );
    final fade = (1 - max(0.0, (progress - 0.72) / 0.28))
        .clamp(0.0, 1.0)
        .toDouble();
    for (var i = 0; i < _starts.length; i++) {
      final start = _starts[i];
      final side = start.dx < 0.5 ? -1.0 : 1.0;
      final dx = start.dx + side * (0.09 + (i % 3) * 0.022) * t;
      final dy = start.dy - (0.34 + (i % 4) * 0.035) * t + 0.17 * t * t;
      final center = Offset(dx * size.width, dy * size.height);
      final paint = Paint()
        ..color = (i.isEven ? color : Colors.white).withValues(alpha: 0.90 * fade)
        ..style = PaintingStyle.fill;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate((i - 4) * 0.22 + t * (i.isEven ? 2.2 : -2.0));
      final w = 4.5 + (i % 3) * 1.2;
      final h = 9.0 + (i % 2) * 2.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w, height: h),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _RecordConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class _Rule extends StatelessWidget {
  const _Rule({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white70, height: 1.35),
      ),
    );
  }
}
