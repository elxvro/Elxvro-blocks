from pathlib import Path
import sys

root=Path(sys.argv[1])
def patch(f,old,new):
    p=root/f; s=p.read_text(encoding='utf-8')
    if s.count(old)!=1: raise RuntimeError(f'FX anchor {f}: {s.count(old)} {old[:65]!r}')
    p.write_text(s.replace(old,new,1),encoding='utf-8')

f='lib/screens/falling_blocks_screen.dart'
patch(f,"import '../widgets/themed_block_tile.dart';",
        "import '../widgets/themed_block_tile.dart';\nimport '../widgets/falling_impact_overlay.dart';")
patch(f,"with WidgetsBindingObserver {",
        "with WidgetsBindingObserver, SingleTickerProviderStateMixin {")
patch(f,"  Timer? _timer;",
"""  Timer? _timer;
  late final AnimationController _fallImpactController;
  Set<int> _fallImpactCells = <int>{};
  bool _fallImpactIsClear = false;""")
patch(f,
"""    WidgetsBinding.instance.addObserver(this);
    _reset();""",
"""    WidgetsBinding.instance.addObserver(this);
    _fallImpactController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 880),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _fallImpactCells = <int>{});
        }
      });
    _reset();""")
patch(f,
"""    _timer?.cancel();
    super.dispose();""",
"""    _timer?.cancel();
    _fallImpactController.dispose();
    super.dispose();""")
patch(f,
"""    _timer?.cancel();
    _board = List<List<int>>.generate(""",
"""    _timer?.cancel();
    _fallImpactController.reset();
    _fallImpactCells = <int>{};
    _board = List<List<int>>.generate(""")
patch(f,
"""    var overflow = false;
    for (final cell in _piece.cells) {""",
"""    var overflow = false;
    final contactCells = <int>{};
    for (final cell in _piece.cells) {""")
patch(f,
"""        _board[r][c] = _piece.colorIndex;
      }
    }

    if (overflow) {""",
"""        _board[r][c] = _piece.colorIndex;
        contactCells.add(r * _cols + c);
      }
    }

    if (overflow) {""")
patch(f,
"""    if (cleared.isNotEmpty) {
      for (final r in cleared.reversed) {""",
"""    if (cleared.isNotEmpty) {
      _emitImpact(<int>{
        for (final r in cleared)
          for (var c = 0; c < _cols; c++)
            r * _cols + c,
      }, cleared: true);
      for (final r in cleared.reversed) {""")
patch(f,
"""    } else {
      _combo = 0;
      _score += 12;""",
"""    } else {
      _emitImpact(contactCells, cleared: false);
      _combo = 0;
      _score += 12;""")
# Add actual, bounded burst. AnimatedBuilder handles repaints independently.
patch(f,
"""  Future<void> _lockPiece() async {""",
"""  void _emitImpact(Set<int> cells, {required bool cleared}) {
    if (!mounted || cells.isEmpty) return;
    setState(() {
      _fallImpactCells = cells;
      _fallImpactIsClear = cleared;
    });
    _fallImpactController.forward(from: 0);
  }

  Future<void> _lockPiece() async {""")
# Remove landing projection entirely, while leaving real board glow alone.
p=root/f; data=p.read_text(encoding='utf-8')
start=data.index('  Map<int, int> get _ghostCells {')
end=data.index('  @override\n  Widget build(BuildContext context) {',start)
data=data[:start]+data[end:]
p.write_text(data,encoding='utf-8')
patch(f,"    final ghost = _ghostCells;\n", "")
patch(f,"                              final ghostColor = ghost[index];\n","")
patch(f,"                              if (!filled && ghostColor == null) {",
        "                              if (!filled) {")
patch(f,
"""                              final displayIndex =
                                  filled ? colorIndex : ghostColor!;""",
"""                              final displayIndex = colorIndex;""")
patch(f,
"""                              if (!filled && ghostColor != null) {
                                return Opacity(opacity: 0.22, child: tile);
                              }
                              return tile;""",
"""                              return tile;""")
patch(f,'                          child: GridView.builder(',
"""                          child: Stack(
                            children: <Widget>[
                              GridView.builder(""")
patch(f,
"""                              return tile;
                            },
                          ),
                        ),
                      ),
                    );""",
"""                              return tile;
                            },
                          ),
                              if (_fallImpactCells.isNotEmpty)
                                Positioned.fill(
                                  child: FallingImpactOverlay(
                                    progress: _fallImpactController,
                                    cells: _fallImpactCells,
                                    material: _theme.material,
                                    accent: _theme.blockAccent,
                                    cleared: _fallImpactIsClear,
                                    lowFx: widget.appState.performanceMode,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );""")
path=root/'lib/widgets/falling_impact_overlay.dart'
path.write_text((Path(__file__).parent/'falling_impact_overlay.dart').read_text(encoding='utf-8'),encoding='utf-8')
# Make clear explosions substantially visible without resurrecting unrelated
# lines, preserve performance mode limits.
patch('lib/widgets/localized_shatter_overlay.dart','final limit = lowFx ? 18 : 42;',
      'final limit = lowFx ? 18 : 72;')
patch('lib/widgets/localized_shatter_overlay.dart',
      'final particlesPerCell = lowFx ? 1 : 2;',
      'final particlesPerCell = lowFx ? 1 : 4;')
patch('lib/screens/game_screen.dart',
"""    final maxVisibleParticles = widget.appState.performanceMode
        ? 20
        : cells.length >= 18
            ? 42
            : 55;""",
"""    final maxVisibleParticles = widget.appState.performanceMode
        ? 20
        : cells.length >= 18
            ? 92
            : 125;""")
patch('lib/screens/game_screen.dart',"vx: particle.vx * 0.042,",
      "vx: particle.vx * 0.072,")
patch('lib/screens/game_screen.dart',"vy: particle.vy * 0.042,",
      "vy: particle.vy * 0.072,")
# Prevent shadow presence even in landing guides: no ghost computation remains.
(root/'test/v0280_falling_impact_test.dart').write_text("""import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('falling blocks have no ghost landing shadow and localized effects', () {
    final screen = File('lib/screens/falling_blocks_screen.dart').readAsStringSync();
    expect(screen, isNot(contains('_ghostCells')));
    expect(screen, isNot(contains('ghostColor')));
    expect(screen, contains('FallingImpactOverlay('));
    expect(screen, contains('_emitImpact(contactCells, cleared: false)'));
    expect(screen, contains('cleared: true'));
  });
  test('regular breakup particles remain attached to cleared cells', () {
    final board = File('lib/screens/game_screen.dart').readAsStringSync();
    expect(board, contains('cells: _flashCells,'));
    expect(board, contains('LocalizedShatterOverlay('));
    expect(board, contains('maxVisibleParticles'));
  });
}
""",encoding='utf-8')
print('Falling ghosts removed, contact and clear bursts wired, regular fx intensified')
