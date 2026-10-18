#!/usr/bin/env python3
from pathlib import Path
import sys
root=Path(sys.argv[1] if len(sys.argv)>1 else 'extracted/elxvro-blocks')
def put(s,a,b,label):
    n=s.count(a)
    if n!=1: raise RuntimeError(f'{label}: expected one occurrence, got {n}')
    return s.replace(a,b,1)
def area(s,a,b,new):
    start=s.index(a); end=s.index(b,start)
    return s[:start]+new+s[end:]

p=root/'lib/screens/falling_blocks_screen.dart';s=p.read_text()
s=put(s,"import '../game/adventure_rise_rules.dart';","import '../game/adventure_rise_rules.dart';\nimport '../game/drag_step_accumulator.dart';",'import')
s=put(s,"  double _dragDx = 0;\n  double _dragDy = 0;","  final DragStepAccumulator _dragSteps = DragStepAccumulator();",'state')
s=put(s,"duration: const Duration(milliseconds: 880),","duration: Duration(milliseconds: widget.appState.performanceMode ? 440 : 880),",'duration')
s=put(s,"      _timer?.cancel();\n      if (mounted) setState(() => _paused = true);","      _timer?.cancel();\n      _fallImpactController.stop();\n      if (mounted && !_paused) setState(() => _paused = true);",'lifecycle')
s=put(s,"    _finishing = false;\n    _dragDx = 0;\n    _dragDy = 0;","    _finishing = false;\n    _dragSteps.reset();",'reset')
s=put(s,"if (mounted && !_paused && !_gameOver && !_finishing) {","if (mounted && !_paused && !_gameOver && !_finishing && !_locking) {",'timer')
s=area(s,'  void _stepDown() {','  void _rotate() {',"""  void _stepDown() => _softDrop(1);
  void _softDrop(int steps) {
    if (_paused || _gameOver || _finishing || _locking || steps <= 0) return;
    var moved=0; var landed=false;
    for (var i=0;i<steps;i++) {
      if (_canPlace(_piece,_row+moved+1,_col)) { moved++; }
      else { landed=true; break; }
    }
    if (moved>0) setState(() => _row+=moved);
    if (landed) unawaited(_lockPiece());
  }
  void _move(int delta) {
    if (_paused || _gameOver || _finishing || _locking || delta==0) return;
    var destination=_col;
    final direction=delta.sign;
    for (var i=0;i<delta.abs();i++) {
      if (!_canPlace(_piece,_row,destination+direction)) break;
      destination+=direction;
    }
    if (destination!=_col) {
      setState(() => _col=destination);
      if (widget.appState.hapticsEnabled) HapticFeedback.selectionClick();
    }
  }

""")
s=area(s,'  void _onPanUpdate(DragUpdateDetails details) {','  void _emitImpact(', """  void _onPanUpdate(DragUpdateDetails details) {
    if (_paused || _gameOver || _finishing || _locking) return;
    final steps = _dragSteps.update(details.delta.dx,details.delta.dy);
    if (steps.horizontal!=0) _move(steps.horizontal);
    if (steps.downward!=0) _softDrop(steps.downward);
  }
  void _onPanEnd(DragEndDetails details) => _dragSteps.reset();
  void _onPanCancel() => _dragSteps.reset();

""")
s=put(s,'    _fallImpactController.forward(from: 0);',"""    _fallImpactController.duration = Duration(
      milliseconds: widget.appState.performanceMode ? 440 : 880,
    );
    _fallImpactController.forward(from: 0);""",'FX duration')
s=put(s,'''    setState(() => _paused = !_paused);
    if (_paused) {
      _timer?.cancel();
    } else {
      _restartTimer();
    }''','''    setState(() => _paused = !_paused);
    _dragSteps.reset();
    if (_paused) {
      _timer?.cancel();
      _fallImpactController.stop();
    } else {
      if (_fallImpactCells.isNotEmpty) _fallImpactController.forward();
      _restartTimer();
    }''','pause')
s=put(s,"    final active = _activeCells;\n    final levelAccent = _palette.first;", """    final active = _activeCells;
    final palette = _palette;
    final levelAccent = palette.first;
    final emptyCell = Container(
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
    );""",'palette cache')
s=area(s,'                              if (!filled) {','                              final displayIndex = colorIndex;',
    '                              if (!filled) return emptyCell;\n\n')
s=put(s,'''                              final base =
                                  _palette[displayIndex % _palette.length];''','''                              final base = palette[displayIndex % palette.length];''','tile cache')
s=put(s,'                            itemCount: _rows * _cols,','''                            itemCount: _rows * _cols,
                            addAutomaticKeepAlives: false,
                            addSemanticIndexes: false,
                            addRepaintBoundaries: false,''','grid')
s=put(s,'                        onPanEnd: _onPanEnd,','                        onPanEnd: _onPanEnd,\n                        onPanCancel: _onPanCancel,','cancel')
s=put(s,'                              GridView.builder(','                              RepaintBoundary(\n                                child: GridView.builder(','board boundary')
s=put(s,'                            },\n                          ),\n                              if (_fallImpactCells.isNotEmpty)','                            },\n                          ),\n                              ),\n                              if (_fallImpactCells.isNotEmpty)','boundary close')
p.write_text(s)

p=root/'lib/widgets/falling_impact_overlay.dart';s=p.read_text()
s=put(s,'    final targets = cells.toList()..sort();',"""    final targets = cells.toList()..sort();
    final sprites = List<Image>.generate(
      5,
      (index) => Image.asset(
        'assets/images/material_shards/${material.name}_$index.webp',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.low,
        gaplessPlayback: true,
      ),
      growable: false,
    );""",'reuse sprites')
s=put(s,'    return IgnorePointer(child: AnimatedBuilder(','    return RepaintBoundary(child: IgnorePointer(child: AnimatedBuilder(','particle repaint')
s=put(s,'                _fragment(targets[n], n, shard, t, alpha, cellW, cellH),','                _fragment(targets[n], n, shard, t, alpha, cellW, cellH, sprites),','sprites arg')
s=put(s,'    ));\n  }\n\n  Widget _fragment','    )));\n  }\n\n  Widget _fragment','particle close')
s=put(s,'      double alpha, double cellW, double cellH) {','      double alpha, double cellW, double cellH, List<Image> sprites) {','sprites type')
s=put(s,"""            child: Image.asset(
              'assets/images/material_shards/${material.name}_${shard % 5}.webp',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.low,
            ),""",'            child: sprites[shard % sprites.length],','sprites reuse')
p.write_text(s)

p=root/'lib/services/audio_service.dart';s=p.read_text()
s=put(s,'  Future<void> _playWithVolume(\n','  final Stopwatch _effectClock = Stopwatch()..start();\n  final Map<String, int> _shortEffectAtMs = <String, int>{};\n\n  Future<void> _playWithVolume(\n','audio state')
s=put(s,'    if (!requireSfxEnabled && !_uiEnabled) return;\n\n    try {',"""    if (!requireSfxEnabled && !_uiEnabled) return;
    // Avoid duplicate rapid UI/placement sounds; never throttle clear or reward.
    final gate = asset.contains('menu_fun_v')
        ? 'ui' : asset.contains('_place_v') ? 'place' : null;
    if (gate != null) {
      final now = _effectClock.elapsedMilliseconds;
      final previous = _shortEffectAtMs[gate];
      if (previous != null && now - previous < 45) return;
      _shortEffectAtMs[gate] = now;
    }

    try {""",'audio gate')
p.write_text(s)

p=root/'pubspec.yaml'
p.write_text(put(p.read_text(),'version: 0.30.0+74','version: 0.30.1+75','version'))
for p in (root/'test').glob('*.dart'):
    s=p.read_text()
    if 'version: 0.30.0+74' in s:
      p.write_text(s.replace('version: 0.30.0+74','version: 0.30.1+75'))
print('v0.30.1 input/graphics/audio optimizations applied')
