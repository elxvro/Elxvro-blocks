import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../models/adventure_level.dart';
import '../models/game_theme.dart';
import '../services/audio_service.dart';
import '../services/play_games_service.dart';
import '../widgets/premium_background.dart';
import '../widgets/themed_block_tile.dart';

class FallingBlocksScreen extends StatefulWidget {
  const FallingBlocksScreen({
    super.key,
    required this.appState,
    this.adventureLevel,
  });

  final AppState appState;
  final AdventureLevel? adventureLevel;

  @override
  State<FallingBlocksScreen> createState() => _FallingBlocksScreenState();
}

class _FallingBlocksScreenState extends State<FallingBlocksScreen>
    with WidgetsBindingObserver {
  static const int _rows = 20;
  static const int _cols = 10;
  static const String _adventureLeaderboardId = 'CgkI6arsvtAGEAIQBA';

  final Random _random = Random();
  late List<List<int>> _board;
  late _FallingPiece _piece;
  late _FallingPiece _nextPiece;
  Timer? _timer;

  int _row = 0;
  int _col = 3;
  int _score = 0;
  int _lines = 0;
  int _combo = 0;
  bool _paused = false;
  bool _gameOver = false;
  bool _finishing = false;
  double _dragDx = 0;
  double _dragDy = 0;

  bool get _isAdventure => widget.adventureLevel != null;

  GameThemeData get _theme => gameThemes.firstWhere(
        (theme) => theme.id == widget.appState.themeId,
        orElse: () => gameThemes.first,
      );

  int get _arcadeLevel => 1 + (_lines ~/ 10);

  int get _difficultyLevel =>
      _isAdventure ? widget.adventureLevel!.number : _arcadeLevel;

  int get _targetScore {
    final level = widget.adventureLevel;
    if (level == null) return 0;
    return level.fallingTargetScore;
  }

  Duration get _fallInterval {
    if (_isAdventure) {
      final level = widget.adventureLevel!;
      return Duration(milliseconds: level.fallingIntervalMs);
    }
    final ms = max(125, 620 - (_arcadeLevel - 1) * 48);
    return Duration(milliseconds: ms);
  }

  List<Color> get _palette {
    const palettes = <List<Color>>[
      <Color>[
        Color(0xFF7DEBFF), Color(0xFF4CB8FF), Color(0xFFB8F8FF),
        Color(0xFF57D6D0), Color(0xFF8BA6FF), Color(0xFFD9FFFF), Color(0xFF65C7FF),
      ],
      <Color>[
        Color(0xFFB38CFF), Color(0xFF6C63FF), Color(0xFFEE8CFF),
        Color(0xFF6FD8FF), Color(0xFFC4A7FF), Color(0xFF8F7BFF), Color(0xFFFF9FE8),
      ],
      <Color>[
        Color(0xFFFF7B62), Color(0xFFFFB347), Color(0xFFFFD56A),
        Color(0xFFFF5A78), Color(0xFFFF916E), Color(0xFFFFC36A), Color(0xFFFF6B3D),
      ],
      <Color>[
        Color(0xFF69EE9A), Color(0xFF37C97A), Color(0xFF9AF57B),
        Color(0xFF4CE2C0), Color(0xFFB6FF8A), Color(0xFF51B96E), Color(0xFF7CF0D4),
      ],
      <Color>[
        Color(0xFFFFD56A), Color(0xFFFFA94D), Color(0xFFFFF2A6),
        Color(0xFFDFAF55), Color(0xFFFFC96B), Color(0xFFFFE08D), Color(0xFFCB8E3E),
      ],
      <Color>[
        Color(0xFFFF76C8), Color(0xFFFF5E8D), Color(0xFFC85CFF),
        Color(0xFFFFA4DB), Color(0xFF8D75FF), Color(0xFFFF7AA8), Color(0xFFD76DFF),
      ],
      <Color>[
        Color(0xFF80A8FF), Color(0xFF4D78E8), Color(0xFF65E4FF),
        Color(0xFF9FC2FF), Color(0xFF5771D9), Color(0xFF76C8FF), Color(0xFFA6B2FF),
      ],
    ];

    final cycle = _isAdventure ? widget.adventureLevel!.colorCycle : 0;
    final selected = palettes[cycle % palettes.length];
    return List<Color>.generate(selected.length, (index) {
      return Color.lerp(selected[index], _theme.block, 0.12)!;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reset();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_gameOver || _finishing) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _timer?.cancel();
      if (mounted) setState(() => _paused = true);
    }
  }

  void _reset() {
    _timer?.cancel();
    _board = List<List<int>>.generate(
      _rows,
      (_) => List<int>.filled(_cols, -1),
    );
    if (_isAdventure) {
      _seedAdventureBoard();
    }
    _piece = _randomPiece();
    _nextPiece = _randomPiece();
    _row = 0;
    _col = ((_cols - _piece.width) ~/ 2).clamp(0, _cols - 1);
    _score = 0;
    _lines = 0;
    _combo = 0;
    _paused = false;
    _gameOver = false;
    _finishing = false;
    _dragDx = 0;
    _dragDy = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _restartTimer();
    });
  }

  void _seedAdventureBoard() {
    final level = widget.adventureLevel!;
    final seeded = Random(level.number * 9173 + 31);
    final maxRows = (3 + level.chapter).clamp(3, 8);
    final desired = level.startingBlocks.clamp(0, 32);
    var placed = 0;
    var guard = 0;

    while (placed < desired && guard < 500) {
      guard += 1;
      final row = _rows - 1 - seeded.nextInt(maxRows);
      final col = seeded.nextInt(_cols);
      if (_board[row][col] >= 0) continue;
      final occupied = _board[row].where((cell) => cell >= 0).length;
      if (occupied >= _cols - 3) continue;
      _board[row][col] = seeded.nextInt(7);
      placed += 1;
    }
  }

  _FallingPiece _randomPiece() {
    final shape = _shapes[_random.nextInt(_shapes.length)];
    return _FallingPiece(shape, _random.nextInt(7));
  }

  void _restartTimer() {
    _timer?.cancel();
    if (_paused || _gameOver || _finishing) return;
    _timer = Timer.periodic(_fallInterval, (_) {
      if (mounted && !_paused && !_gameOver && !_finishing) {
        _stepDown();
      }
    });
  }

  bool _canPlace(_FallingPiece piece, int row, int col) {
    for (final cell in piece.cells) {
      final r = row + cell.$1;
      final c = col + cell.$2;
      if (c < 0 || c >= _cols || r >= _rows) return false;
      if (r >= 0 && _board[r][c] >= 0) return false;
    }
    return true;
  }

  void _stepDown() {
    if (_paused || _gameOver || _finishing) return;
    if (_canPlace(_piece, _row + 1, _col)) {
      setState(() => _row += 1);
      return;
    }
    unawaited(_lockPiece());
  }

  void _move(int delta) {
    if (_paused || _gameOver || _finishing) return;
    final nextCol = _col + delta;
    if (_canPlace(_piece, _row, nextCol)) {
      setState(() => _col = nextCol);
      if (widget.appState.hapticsEnabled) {
        HapticFeedback.selectionClick();
      }
    }
  }

  void _rotate() {
    if (_paused || _gameOver || _finishing) return;
    final rotated = _piece.rotated();
    for (final kick in <int>[0, -1, 1, -2, 2]) {
      if (_canPlace(rotated, _row, _col + kick)) {
        setState(() {
          _piece = rotated;
          _col += kick;
        });
        unawaited(AudioService.instance.playClick());
        if (widget.appState.hapticsEnabled) {
          HapticFeedback.selectionClick();
        }
        return;
      }
    }
  }

  void _hardDrop() {
    if (_paused || _gameOver || _finishing) return;
    var distance = 0;
    while (_canPlace(_piece, _row + distance + 1, _col)) {
      distance += 1;
    }
    setState(() {
      _row += distance;
      _score += distance * 2;
    });
    unawaited(_lockPiece());
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_paused || _gameOver || _finishing) return;
    _dragDx += details.delta.dx;
    _dragDy += details.delta.dy;

    const horizontalStep = 23.0;
    if (_dragDx.abs() >= horizontalStep) {
      final direction = _dragDx > 0 ? 1 : -1;
      _move(direction);
      _dragDx = 0;
    }

    if (_dragDy >= 28) {
      _stepDown();
      _dragDy = 0;
    } else if (_dragDy <= -40) {
      _dragDy = 0;
    }
  }

  void _onPanEnd(DragEndDetails details) {
    _dragDx = 0;
    _dragDy = 0;
  }

  Future<void> _lockPiece() async {
    if (_finishing || _gameOver) return;

    var overflow = false;
    for (final cell in _piece.cells) {
      final r = _row + cell.$1;
      final c = _col + cell.$2;
      if (r < 0) {
        overflow = true;
        continue;
      }
      if (r < _rows && c >= 0 && c < _cols) {
        _board[r][c] = _piece.colorIndex;
      }
    }

    if (overflow) {
      await _finish(success: false);
      return;
    }

    final cleared = <int>[];
    for (var r = 0; r < _rows; r++) {
      if (_board[r].every((cell) => cell >= 0)) cleared.add(r);
    }

    if (cleared.isNotEmpty) {
      for (final r in cleared.reversed) {
        _board.removeAt(r);
      }
      while (_board.length < _rows) {
        _board.insert(0, List<int>.filled(_cols, -1));
      }

      _combo += 1;
      _lines += cleared.length;
      final base = switch (cleared.length) {
        1 => 100,
        2 => 300,
        3 => 500,
        _ => 800,
      };
      final comboBonus = _combo > 1 ? (_combo - 1) * 90 : 0;
      _score += base * _difficultyLevel + comboBonus;

      unawaited(
        AudioService.instance.playClearTier(
          _theme.audioProfile,
          lineCount: cleared.length,
          combo: _combo,
        ),
      );
      if (widget.appState.hapticsEnabled) {
        if (cleared.length >= 4 || _combo >= 3) {
          HapticFeedback.heavyImpact();
        } else {
          HapticFeedback.mediumImpact();
        }
      }
    } else {
      _combo = 0;
      _score += 12;
      unawaited(AudioService.instance.playPlace(_theme.audioProfile));
      if (widget.appState.hapticsEnabled) {
        HapticFeedback.lightImpact();
      }
    }

    if (_isAdventure && _score >= _targetScore) {
      await _finish(success: true);
      return;
    }

    _piece = _nextPiece;
    _nextPiece = _randomPiece();
    _row = -1;
    _col = ((_cols - _piece.width) ~/ 2).clamp(0, _cols - 1);

    if (!_canPlace(_piece, _row, _col)) {
      await _finish(success: false);
      return;
    }

    if (mounted) {
      setState(() {});
      _restartTimer();
    }
  }

  Future<void> _finish({required bool success}) async {
    if (_finishing) return;
    _finishing = true;
    _timer?.cancel();

    var earned = 0;
    if (_isAdventure && success) {
      final level = widget.adventureLevel!;
      earned = await widget.appState.completeAdventureLevel(
        level: level.number,
        reward: level.reward,
        score: _score,
      );

      final playGames = PlayGamesService.production();
      unawaited(
        playGames.submitScore(
          leaderboardId: _adventureLeaderboardId,
          score: widget.appState.adventureTournamentScore,
        ),
      );
    } else if (!_isAdventure) {
      await widget.appState.recordFallingBlocksScore(_score);
    }

    if (!mounted) return;
    setState(() => _gameOver = true);

    if (success) {
      unawaited(AudioService.instance.playReward());
    } else {
      unawaited(AudioService.instance.playGameOver());
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final adventure = widget.adventureLevel;
        final canGoNext =
            success && adventure != null && adventure.number < adventureLevelCount;

        return AlertDialog(
          backgroundColor: const Color(0xFF101719),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          title: Text(
            _isAdventure
                ? success
                    ? 'BÖLÜM TAMAMLANDI'
                    : 'BÖLÜM BAŞARISIZ'
                : 'DÜŞEN BLOKLAR',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: success ? _palette.first : const Color(0xFFFFD98B),
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '$_score',
                style: TextStyle(
                  color: _theme.blockAccent,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                'SKOR',
                style: TextStyle(color: Colors.white38, fontSize: 10),
              ),
              const SizedBox(height: 14),
              Text(
                _isAdventure
                    ? 'Hedef $_targetScore puan  •  $_lines çizgi'
                        '${earned > 0 ? '  •  +$earned coin' : ''}'
                    : '$_lines çizgi  •  Seviye $_arcadeLevel\n'
                        'En iyi: ${widget.appState.fallingBlocksBestScore}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60, height: 1.5),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
              },
              child: Text(_isAdventure ? 'BÖLÜMLER' : 'MODLAR'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (canGoNext) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => FallingBlocksScreen(
                        appState: widget.appState,
                        adventureLevel:
                            adventureLevelFor(adventure.number + 1),
                      ),
                    ),
                  );
                  return;
                }
                setState(_reset);
              },
              style: FilledButton.styleFrom(
                backgroundColor: _palette.first,
                foregroundColor: const Color(0xFF071014),
              ),
              child: Text(canGoNext ? 'SONRAKİ' : 'TEKRAR OYNA'),
            ),
          ],
        );
      },
    );
  }

  void _togglePause() {
    if (_gameOver || _finishing) return;
    setState(() => _paused = !_paused);
    if (_paused) {
      _timer?.cancel();
    } else {
      _restartTimer();
    }
  }

  Map<int, int> get _activeCells {
    final result = <int, int>{};
    for (final cell in _piece.cells) {
      final r = _row + cell.$1;
      final c = _col + cell.$2;
      if (r >= 0 && r < _rows && c >= 0 && c < _cols) {
        result[r * _cols + c] = _piece.colorIndex;
      }
    }
    return result;
  }

  Map<int, int> get _ghostCells {
    if (_paused || _gameOver || _finishing) return const <int, int>{};
    var distance = 0;
    while (_canPlace(_piece, _row + distance + 1, _col)) {
      distance += 1;
    }
    if (distance == 0) return const <int, int>{};

    final result = <int, int>{};
    for (final cell in _piece.cells) {
      final r = _row + distance + cell.$1;
      final c = _col + cell.$2;
      if (r >= 0 && r < _rows && c >= 0 && c < _cols) {
        result[r * _cols + c] = _piece.colorIndex;
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final active = _activeCells;
    final ghost = _ghostCells;
    final levelAccent = _palette.first;

    return Scaffold(
      body: PremiumBackground(
        top: _theme.backgroundTop,
        bottom: _theme.backgroundBottom,
        material: _theme.material,
        accent: _theme.blockAccent,
        child: SafeArea(
          child: Column(
            children: <Widget>[
              _Header(
                title: _isAdventure
                    ? 'MACERA • BÖLÜM ${widget.adventureLevel!.number}'
                    : 'DÜŞEN BLOKLAR',
                score: _score,
                lines: _lines,
                targetScore: _targetScore,
                level: _difficultyLevel,
                accent: levelAccent,
                paused: _paused,
                onBack: () => Navigator.of(context).pop(),
                onPause: _togglePause,
              ),
              if (_isAdventure)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 6),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 5,
                      value: _targetScore <= 0
                          ? 0
                          : (_score / _targetScore).clamp(0.0, 1.0).toDouble(),
                      backgroundColor: Colors.white.withValues(alpha: 0.055),
                      valueColor: AlwaysStoppedAnimation<Color>(levelAccent),
                    ),
                  ),
                ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final widthByScreen = constraints.maxWidth - 16;
                    final widthByHeight = constraints.maxHeight / 2;
                    final boardWidth =
                        min(widthByScreen, widthByHeight).clamp(220.0, 420.0);
                    final cell = boardWidth / _cols;
                    final boardHeight = cell * _rows;

                    return Center(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: _onPanEnd,
                        child: Container(
                          width: boardWidth,
                          height: boardHeight,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: <Color>[
                                Color.lerp(_theme.board, levelAccent, 0.12)!
                                    .withValues(alpha: 0.97),
                                _theme.board.withValues(alpha: 0.94),
                                Color.lerp(_theme.board, Colors.black, 0.24)!
                                    .withValues(alpha: 0.98),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: levelAccent.withValues(alpha: 0.58),
                              width: 1.6,
                            ),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: levelAccent.withValues(alpha: 0.22),
                                blurRadius: 30,
                                spreadRadius: 1,
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.34),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: _cols,
                            ),
                            itemCount: _rows * _cols,
                            itemBuilder: (context, index) {
                              final row = index ~/ _cols;
                              final col = index % _cols;
                              final fixedColor = _board[row][col];
                              final activeColor = active[index];
                              final ghostColor = ghost[index];
                              final colorIndex = activeColor ?? fixedColor;
                              final filled = colorIndex >= 0;

                              if (!filled && ghostColor == null) {
                                return Container(
                                  margin: const EdgeInsets.all(0.45),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(3.2),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: <Color>[
                                        _theme.cell.withValues(alpha: 0.31),
                                        Color.lerp(_theme.cell, Colors.black, 0.28)!
                                            .withValues(alpha: 0.22),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: levelAccent.withValues(alpha: 0.045),
                                      width: 0.5,
                                    ),
                                  ),
                                );
                              }

                              final displayIndex =
                                  filled ? colorIndex : ghostColor!;
                              final base =
                                  _palette[displayIndex % _palette.length];
                              final accent =
                                  Color.lerp(base, Colors.white, 0.58)!;
                              final tile = Padding(
                                padding: const EdgeInsets.all(0.20),
                                child: ThemedBlockTile(
                                  material: _theme.material,
                                  base: base,
                                  accent: accent,
                                ),
                              );
                              if (!filled && ghostColor != null) {
                                return Opacity(opacity: 0.22, child: tile);
                              }
                              return tile;
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_paused)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'DURAKLATILDI',
                    style: TextStyle(
                      color: levelAccent,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.6,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 6),
                child: Text(
                  'Sağa/sola sürükle • Aşağı kaydır',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.42),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _Controls(
                accent: levelAccent,
                onRotate: _rotate,
                onDrop: _hardDrop,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.score,
    required this.lines,
    required this.targetScore,
    required this.level,
    required this.accent,
    required this.paused,
    required this.onBack,
    required this.onPause,
  });

  final String title;
  final int score;
  final int lines;
  final int targetScore;
  final int level;
  final Color accent;
  final bool paused;
  final VoidCallback onBack;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 4),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          Expanded(
            child: Column(
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.25,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  targetScore > 0
                      ? 'SKOR $score/$targetScore  •  ÇİZGİ $lines  •  ZORLUK $level'
                      : 'SKOR $score  •  ÇİZGİ $lines  •  HIZ $level',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onPause,
            icon: Icon(
              paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.accent,
    required this.onRotate,
    required this.onDrop,
  });

  final Color accent;
  final VoidCallback onRotate;
  final VoidCallback onDrop;

  @override
  Widget build(BuildContext context) {
    Widget button(
      IconData icon,
      String label,
      VoidCallback onTap, {
      bool emphasized = false,
    }) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Material(
            color: emphasized
                ? accent.withValues(alpha: 0.24)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 58,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(icon, color: accent, size: 25),
                    const SizedBox(width: 7),
                    Text(
                      label,
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: Row(
        children: <Widget>[
          button(Icons.rotate_right_rounded, 'DÖNDÜR', onRotate),
          button(
            Icons.vertical_align_bottom_rounded,
            'HIZLI İNDİR',
            onDrop,
            emphasized: true,
          ),
        ],
      ),
    );
  }
}

class _FallingPiece {
  const _FallingPiece(this.cells, this.colorIndex);

  final List<(int, int)> cells;
  final int colorIndex;

  int get width {
    var maxCol = 0;
    for (final cell in cells) {
      if (cell.$2 > maxCol) maxCol = cell.$2;
    }
    return maxCol + 1;
  }

  int get height {
    var maxRow = 0;
    for (final cell in cells) {
      if (cell.$1 > maxRow) maxRow = cell.$1;
    }
    return maxRow + 1;
  }

  _FallingPiece rotated() {
    final h = height;
    final rotated = cells
        .map((cell) => (cell.$2, h - 1 - cell.$1))
        .toList(growable: false);

    var minRow = rotated.first.$1;
    var minCol = rotated.first.$2;
    for (final cell in rotated) {
      minRow = min(minRow, cell.$1);
      minCol = min(minCol, cell.$2);
    }
    return _FallingPiece(
      rotated
          .map((cell) => (cell.$1 - minRow, cell.$2 - minCol))
          .toList(growable: false),
      colorIndex,
    );
  }
}

const List<List<(int, int)>> _shapes = <List<(int, int)>>[
  <(int, int)>[(0, 0), (0, 1), (0, 2), (0, 3)],
  <(int, int)>[(0, 0), (0, 1), (1, 0), (1, 1)],
  <(int, int)>[(0, 1), (1, 0), (1, 1), (1, 2)],
  <(int, int)>[(0, 1), (0, 2), (1, 0), (1, 1)],
  <(int, int)>[(0, 0), (0, 1), (1, 1), (1, 2)],
  <(int, int)>[(0, 0), (1, 0), (1, 1), (1, 2)],
  <(int, int)>[(0, 2), (1, 0), (1, 1), (1, 2)],
];
