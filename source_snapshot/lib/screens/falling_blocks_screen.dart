import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../models/game_theme.dart';
import '../services/audio_service.dart';
import '../widgets/premium_background.dart';

class FallingBlocksScreen extends StatefulWidget {
  const FallingBlocksScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<FallingBlocksScreen> createState() => _FallingBlocksScreenState();
}

class _FallingBlocksScreenState extends State<FallingBlocksScreen>
    with WidgetsBindingObserver {
  static const int _rows = 20;
  static const int _cols = 10;

  final Random _random = Random();
  late List<List<bool>> _board;
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

  GameThemeData get _theme => gameThemes.firstWhere(
        (theme) => theme.id == widget.appState.themeId,
        orElse: () => gameThemes.first,
      );

  int get _level => 1 + (_lines ~/ 10);

  Duration get _fallInterval {
    final ms = max(125, 620 - (_level - 1) * 48);
    return Duration(milliseconds: ms);
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
    _board = List<List<bool>>.generate(
      _rows,
      (_) => List<bool>.filled(_cols, false),
    );
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _restartTimer();
    });
  }

  _FallingPiece _randomPiece() {
    final shape = _shapes[_random.nextInt(_shapes.length)];
    return _FallingPiece(shape);
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
      if (r >= 0 && _board[r][c]) return false;
    }
    return true;
  }

  void _stepDown() {
    if (_canPlace(_piece, _row + 1, _col)) {
      setState(() => _row += 1);
      return;
    }
    _lockPiece();
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
    _lockPiece();
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
        _board[r][c] = true;
      }
    }

    if (overflow) {
      await _finish();
      return;
    }

    final cleared = <int>[];
    for (var r = 0; r < _rows; r++) {
      if (_board[r].every((cell) => cell)) cleared.add(r);
    }

    if (cleared.isNotEmpty) {
      for (final r in cleared.reversed) {
        _board.removeAt(r);
      }
      while (_board.length < _rows) {
        _board.insert(0, List<bool>.filled(_cols, false));
      }

      _combo += 1;
      _lines += cleared.length;
      final base = switch (cleared.length) {
        1 => 100,
        2 => 300,
        3 => 500,
        _ => 800,
      };
      _score += (base * _level) + max(0, _combo - 1) * 80;

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

    _piece = _nextPiece;
    _nextPiece = _randomPiece();
    _row = -1;
    _col = ((_cols - _piece.width) ~/ 2).clamp(0, _cols - 1);

    if (!_canPlace(_piece, _row, _col)) {
      await _finish();
      return;
    }

    if (mounted) {
      setState(() {});
      _restartTimer();
    }
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    _timer?.cancel();
    await widget.appState.recordFallingBlocksScore(_score);
    if (!mounted) return;

    setState(() => _gameOver = true);
    unawaited(AudioService.instance.playGameOver());

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF101719),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          title: const Text(
            'DÜŞEN BLOKLAR',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFFFD98B),
              fontWeight: FontWeight.w900,
              letterSpacing: 1.6,
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
                '$_lines çizgi  •  Seviye $_level\nEn iyi: ${widget.appState.fallingBlocksBestScore}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60, height: 1.5),
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
              child: const Text('MODLAR'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(_reset);
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

  void _togglePause() {
    if (_gameOver || _finishing) return;
    setState(() => _paused = !_paused);
    if (_paused) {
      _timer?.cancel();
    } else {
      _restartTimer();
    }
  }

  Set<int> get _activeCells {
    final result = <int>{};
    for (final cell in _piece.cells) {
      final r = _row + cell.$1;
      final c = _col + cell.$2;
      if (r >= 0 && r < _rows && c >= 0 && c < _cols) {
        result.add(r * _cols + c);
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final active = _activeCells;
    return Scaffold(
      body: PremiumBackground(
        top: _theme.backgroundTop,
        bottom: _theme.backgroundBottom,
        material: _theme.material,
        accent: _theme.blockAccent,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final boardWidth = min(constraints.maxWidth - 104, 330.0);
              final cell = boardWidth / _cols;
              final boardHeight = cell * _rows;

              return Column(
                children: <Widget>[
                  _Header(
                    score: _score,
                    best: widget.appState.fallingBlocksBestScore,
                    lines: _lines,
                    level: _level,
                    accent: _theme.blockAccent,
                    paused: _paused,
                    onBack: () => Navigator.of(context).pop(),
                    onPause: _togglePause,
                  ),
                  Expanded(
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            width: boardWidth,
                            height: boardHeight,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: _theme.board.withValues(alpha: 0.94),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _theme.blockAccent.withValues(alpha: 0.30),
                              ),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: _theme.block.withValues(alpha: 0.20),
                                  blurRadius: 22,
                                  spreadRadius: 2,
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
                                final filled = _board[row][col] ||
                                    active.contains(index);
                                return Container(
                                  margin: const EdgeInsets.all(0.7),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(3),
                                    gradient: filled
                                        ? LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: <Color>[
                                              _theme.blockAccent,
                                              _theme.block,
                                              Color.lerp(
                                                _theme.block,
                                                Colors.black,
                                                0.22,
                                              )!,
                                            ],
                                          )
                                        : null,
                                    color: filled
                                        ? null
                                        : _theme.cell.withValues(alpha: 0.34),
                                    border: Border.all(
                                      color: filled
                                          ? Colors.white.withValues(alpha: 0.34)
                                          : Colors.white.withValues(alpha: 0.035),
                                      width: filled ? 0.8 : 0.45,
                                    ),
                                    boxShadow: filled
                                        ? <BoxShadow>[
                                            BoxShadow(
                                              color: _theme.block
                                                  .withValues(alpha: 0.42),
                                              blurRadius: 4,
                                            ),
                                          ]
                                        : null,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 74,
                            child: Column(
                              children: <Widget>[
                                const Text(
                                  'SONRAKİ',
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _NextPiece(
                                  piece: _nextPiece,
                                  theme: _theme,
                                ),
                                const SizedBox(height: 18),
                                _SideStat(label: 'COMBO', value: 'x$_combo'),
                                const SizedBox(height: 8),
                                _SideStat(label: 'HIZ', value: '$_level'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_paused)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        'DURAKLATILDI',
                        style: TextStyle(
                          color: _theme.blockAccent,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.6,
                        ),
                      ),
                    ),
                  _Controls(
                    accent: _theme.blockAccent,
                    onLeft: () => _move(-1),
                    onRotate: _rotate,
                    onRight: () => _move(1),
                    onDown: _stepDown,
                    onDrop: _hardDrop,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.score,
    required this.best,
    required this.lines,
    required this.level,
    required this.accent,
    required this.paused,
    required this.onBack,
    required this.onPause,
  });

  final int score;
  final int best;
  final int lines;
  final int level;
  final Color accent;
  final bool paused;
  final VoidCallback onBack;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
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
                  'DÜŞEN BLOKLAR',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'SKOR $score  •  REKOR $best  •  ÇİZGİ $lines  •  SV $level',
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
    required this.onLeft,
    required this.onRotate,
    required this.onRight,
    required this.onDown,
    required this.onDrop,
  });

  final Color accent;
  final VoidCallback onLeft;
  final VoidCallback onRotate;
  final VoidCallback onRight;
  final VoidCallback onDown;
  final VoidCallback onDrop;

  @override
  Widget build(BuildContext context) {
    Widget button(IconData icon, VoidCallback onTap, {bool emphasized = false}) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Material(
            color: emphasized
                ? accent.withValues(alpha: 0.20)
                : Colors.white.withValues(alpha: 0.055),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 54,
                child: Icon(icon, color: accent, size: 25),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Row(
        children: <Widget>[
          button(Icons.arrow_left_rounded, onLeft),
          button(Icons.rotate_right_rounded, onRotate),
          button(Icons.arrow_right_rounded, onRight),
          button(Icons.arrow_downward_rounded, onDown),
          button(Icons.vertical_align_bottom_rounded, onDrop, emphasized: true),
        ],
      ),
    );
  }
}

class _SideStat extends StatelessWidget {
  const _SideStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: <Widget>[
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 7,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _NextPiece extends StatelessWidget {
  const _NextPiece({required this.piece, required this.theme});

  final _FallingPiece piece;
  final GameThemeData theme;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellSize = constraints.maxWidth / 5;
          return Stack(
            alignment: Alignment.center,
            children: <Widget>[
              for (final cell in piece.cells)
                Positioned(
                  left: (cell.$2 + (5 - piece.width) / 2) * cellSize,
                  top: (cell.$1 + (5 - piece.height) / 2) * cellSize,
                  width: cellSize - 1,
                  height: cellSize - 1,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      gradient: LinearGradient(
                        colors: <Color>[theme.blockAccent, theme.block],
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: theme.block.withValues(alpha: 0.35),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _FallingPiece {
  const _FallingPiece(this.cells);

  final List<(int, int)> cells;

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
