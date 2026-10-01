#!/usr/bin/env python3
from pathlib import Path
import sys

ROOT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path('.')


def read(rel: str) -> str:
    return (ROOT / rel).read_text(encoding='utf-8')


def write(rel: str, text: str) -> None:
    (ROOT / rel).write_text(text, encoding='utf-8')


def replace_once(rel: str, old: str, new: str) -> None:
    text = read(rel)
    count = text.count(old)
    if count != 1:
        raise SystemExit(f'v0.17 patch anchor mismatch: {rel}: expected 1, found {count}: {old[:90]!r}')
    write(rel, text.replace(old, new, 1))


def replace_block(rel: str, start: str, end: str, new_block: str) -> None:
    text = read(rel)
    if text.count(start) != 1:
        raise SystemExit(f'v0.17 block start mismatch: {rel}: {start!r}')
    start_i = text.index(start)
    end_i = text.find(end, start_i + len(start))
    if end_i < 0:
        raise SystemExit(f'v0.17 block end missing: {rel}: {end!r}')
    write(rel, text[:start_i] + new_block + text[end_i:])


# ---------------------------------------------------------------------------
# Combo Rush mode model and mode screen.
# ---------------------------------------------------------------------------
replace_once(
    'lib/models/game_mode.dart',
    "enum GameMode {\n  classic,\n  timed,\n  target,",
    "enum GameMode {\n  classic,\n  timed,\n  comboRush,\n  target,",
)
replace_once(
    'lib/models/game_mode.dart',
    "  GameMode.target: GameModeData(\n",
    "  GameMode.comboRush: GameModeData(\n"
    "    mode: GameMode.comboRush,\n"
    "    id: 'combo_rush',\n"
    "    title: 'COMBO RUSH',\n"
    "    subtitle: '120 saniyelik seri modu',\n"
    "    description: 'Temizlemeleri seri bağla; boş hamle combo zincirini sıfırlar.',\n"
    "    durationSeconds: 120,\n"
    "  ),\n"
    "  GameMode.target: GameModeData(\n",
)
replace_once(
    'lib/screens/modes_screen.dart',
    "      case GameMode.timed:\n        return appState.timedBestScore;\n      case GameMode.target:",
    "      case GameMode.timed:\n        return appState.timedBestScore;\n      case GameMode.comboRush:\n        return appState.comboRushBestScore;\n      case GameMode.target:",
)
replace_once(
    'lib/screens/modes_screen.dart',
    "      case GameMode.timed:\n        return Icons.timer_outlined;\n      case GameMode.target:",
    "      case GameMode.timed:\n        return Icons.timer_outlined;\n      case GameMode.comboRush:\n        return Icons.bolt_rounded;\n      case GameMode.target:",
)
replace_once(
    'lib/screens/modes_screen.dart',
    "'Klasik, challenge, Zen ve Zor mod ile aynı çekirdek mekaniği farklı ritimlerde oyna.'",
    "'Klasik, Combo Rush, challenge, Zen ve Zor mod ile aynı çekirdek mekaniği farklı ritimlerde oyna.'",
)

# ---------------------------------------------------------------------------
# AppState persistence + Perfect Clear fixed event reward.
# ---------------------------------------------------------------------------
replace_once(
    'lib/app_state.dart',
    "  static const String _hardBestScoreKey = 'hard_best_score';\n",
    "  static const String _hardBestScoreKey = 'hard_best_score';\n"
    "  static const String _comboRushBestScoreKey = 'combo_rush_best_score';\n"
    "  static const String _comboRushBestComboKey = 'combo_rush_best_combo';\n",
)
replace_once(
    'lib/app_state.dart',
    "  int hardBestScore = 0;\n  int dailyChallengeBestScore = 0;",
    "  int hardBestScore = 0;\n  int comboRushBestScore = 0;\n  int comboRushBestCombo = 0;\n  int dailyChallengeBestScore = 0;",
)
replace_once(
    'lib/app_state.dart',
    "      hardBestScore = prefs.getInt(_hardBestScoreKey) ?? 0;\n",
    "      hardBestScore = prefs.getInt(_hardBestScoreKey) ?? 0;\n"
    "      comboRushBestScore = prefs.getInt(_comboRushBestScoreKey) ?? 0;\n"
    "      comboRushBestCombo = prefs.getInt(_comboRushBestComboKey) ?? 0;\n",
)
replace_once(
    'lib/app_state.dart',
    "\n  Future<int> recordModeResult({\n",
    "\n  Future<void> recordComboRushResult({\n"
    "    required int score,\n"
    "    required int bestCombo,\n"
    "  }) async {\n"
    "    if (score > comboRushBestScore) comboRushBestScore = score;\n"
    "    if (bestCombo > comboRushBestCombo) comboRushBestCombo = bestCombo;\n"
    "    notifyListeners();\n"
    "    try {\n"
    "      final prefs = await SharedPreferences.getInstance();\n"
    "      await prefs.setInt(_comboRushBestScoreKey, comboRushBestScore);\n"
    "      await prefs.setInt(_comboRushBestComboKey, comboRushBestCombo);\n"
    "    } catch (error) {\n"
    "      debugPrint('ELXVRO Combo Rush save failed: $error');\n"
    "    }\n"
    "  }\n\n"
    "  Future<void> grantPerfectClearBonus() async {\n"
    "    coins += 100;\n"
    "    xp += 75;\n"
    "    notifyListeners();\n"
    "    try {\n"
    "      final prefs = await SharedPreferences.getInstance();\n"
    "      await prefs.setInt(_coinsKey, coins);\n"
    "      await prefs.setInt(_xpKey, xp);\n"
    "    } catch (error) {\n"
    "      debugPrint('ELXVRO Perfect Clear bonus save failed: $error');\n"
    "    }\n"
    "  }\n\n"
    "  Future<int> recordModeResult({\n",
)
replace_once(
    'lib/app_state.dart',
    "      perfectClears: perfectClearsThisGame,\n",
    "      perfectClears: 0,\n",
)
replace_once(
    'lib/app_state.dart',
    "    final perfectClearCoinBonus = perfectClearsThisGame * 30;\n",
    "    const perfectClearCoinBonus = 0;\n",
)

# ---------------------------------------------------------------------------
# Gameplay integration: Combo Rush scoring, fixed rewards, Fracture 2.0,
# optional Play Games sync.
# ---------------------------------------------------------------------------
replace_once(
    'lib/screens/game_screen.dart',
    "import '../game/board_engine.dart';\n",
    "import '../effects/fracture_effect.dart';\n"
    "import '../game/board_engine.dart';\n"
    "import '../game/combo_rush_rules.dart';\n",
)
replace_once(
    'lib/screens/game_screen.dart',
    "import '../services/audio_service.dart';\n",
    "import '../services/audio_service.dart';\n"
    "import '../services/play_games_ids.dart';\n"
    "import '../services/play_games_service.dart';\n",
)
replace_once(
    'lib/screens/game_screen.dart',
    "      case GameMode.timed:\n        return widget.appState.timedBestScore;\n      case GameMode.target:",
    "      case GameMode.timed:\n        return widget.appState.timedBestScore;\n      case GameMode.comboRush:\n        return widget.appState.comboRushBestScore;\n      case GameMode.target:",
)
replace_once(
    'lib/screens/game_screen.dart',
    "    if (widget.mode == GameMode.timed) {\n      await _finishGame(success: true, reason: 'SÜRE DOLDU');",
    "    if (widget.mode == GameMode.timed || widget.mode == GameMode.comboRush) {\n      await _finishGame(success: true, reason: 'SÜRE DOLDU');",
)
replace_once(
    'lib/screens/game_screen.dart',
    "    final nextCombo = didClear ? _combo + 1 : 0;\n",
    "    final nextCombo = widget.mode == GameMode.comboRush\n"
    "        ? nextComboRushCombo(currentCombo: _combo, clearedAnyLine: didClear)\n"
    "        : didClear\n"
    "            ? _combo + 1\n"
    "            : 0;\n",
)
replace_once(
    'lib/screens/game_screen.dart',
    "    final baseMoveScore = result.placedCells * 10 +\n        lineCount * 120 * max(1, nextCombo) +\n        _specialBonus(result) +\n        clearTierBonus;\n    var moveScore = (baseMoveScore * _modeData.scoreMultiplier).round();",
    "    final comboFactor = widget.mode == GameMode.comboRush ? 1 : max(1, nextCombo);\n"
    "    final baseMoveScore = result.placedCells * 10 +\n"
    "        lineCount * 120 * comboFactor +\n"
    "        _specialBonus(result) +\n"
    "        clearTierBonus;\n"
    "    var moveScore = (baseMoveScore * _modeData.scoreMultiplier).round();\n"
    "    if (widget.mode == GameMode.comboRush) {\n"
    "      moveScore = applyComboRushMultiplier(baseScore: moveScore, combo: nextCombo);\n"
    "    }",
)
replace_once(
    'lib/screens/game_screen.dart',
    "      if (isPerfectClear) {\n        _perfectClearHaptic();",
    "      if (isPerfectClear) {\n        unawaited(widget.appState.grantPerfectClearBonus());\n        _showEventBanner('PERFECT CLEAR  •  +100 COIN  •  +75 XP  •  +$moveScore');\n        _perfectClearHaptic();",
)
replace_block(
    'lib/screens/game_screen.dart',
    "  void _triggerClearFx(\n",
    "  void _triggerPlacementFx(",
    "  void _triggerClearFx(\n"
    "    List<BoardCell> cells, {\n"
    "    bool perfect = false,\n"
    "    int impact = 1,\n"
    "  }) {\n"
    "    if (cells.isEmpty) return;\n"
    "    final burst = buildFractureBurst(\n"
    "      clearedCells: cells,\n"
    "      material: _theme.material,\n"
    "      lineCount: impact.clamp(1, 4),\n"
    "      performanceMode: widget.appState.performanceMode,\n"
    "      seed: DateTime.now().microsecondsSinceEpoch,\n"
    "    );\n"
    "    final flash = cells\n"
    "        .map((cell) => cell.row * _boardSize + cell.col)\n"
    "        .toSet();\n"
    "    final particles = burst.particles.map((particle) {\n"
    "      return _Particle(\n"
    "        x: (particle.cell.col + 0.5) / _boardSize,\n"
    "        y: (particle.cell.row + 0.5) / _boardSize,\n"
    "        vx: particle.vx * 0.11,\n"
    "        vy: particle.vy * 0.11,\n"
    "        radius: particle.size * (perfect ? 4.4 : 3.2),\n"
    "        angle: _random.nextDouble() * pi * 2,\n"
    "        spin: particle.spin,\n"
    "      );\n"
    "    }).toList(growable: false);\n"
    "    setState(() {\n"
    "      _flashCells = flash;\n"
    "      _particles = particles;\n"
    "      _perfectClearFx = perfect;\n"
    "      _impactLevel = (impact + burst.shakeAmplitude * 2).round().clamp(1, 6);\n"
    "    });\n"
    "    _clearController.forward(from: 0);\n"
    "  }\n\n",
)
replace_once(
    'lib/screens/game_screen.dart',
    "    final timedSuccess = widget.mode == GameMode.timed && _score >= 1000;\n",
    "    final timedSuccess =\n        (widget.mode == GameMode.timed || widget.mode == GameMode.comboRush) &&\n            _score >= 1000;\n",
)
replace_once(
    'lib/screens/game_screen.dart',
    "    final modeReward = await widget.appState.recordModeResult(\n      modeId: _modeData.id,\n      score: _score,\n      success: success,\n    );\n",
    "    final modeReward = await widget.appState.recordModeResult(\n"
    "      modeId: _modeData.id,\n"
    "      score: _score,\n"
    "      success: success,\n"
    "    );\n"
    "    if (widget.mode == GameMode.comboRush) {\n"
    "      await widget.appState.recordComboRushResult(\n"
    "        score: _score,\n"
    "        bestCombo: _bestComboThisGame,\n"
    "      );\n"
    "    }\n"
    "    await _syncPlayGamesAfterRound();\n",
)
replace_once(
    'lib/screens/game_screen.dart',
    "  Future<void> _finishGame({\n",
    "  Future<void> _syncPlayGamesAfterRound() async {\n"
    "    const ids = PlayGamesIds.fromEnvironment();\n"
    "    if (!ids.hasAnyRemoteConfiguration) return;\n"
    "    final service = PlayGamesService(ids: ids);\n"
    "    if (widget.mode == GameMode.classic) {\n"
    "      await service.submitScore(\n"
    "        leaderboardId: ids.classicLeaderboardId,\n"
    "        score: _score,\n"
    "      );\n"
    "    } else if (widget.mode == GameMode.comboRush) {\n"
    "      await service.submitScore(\n"
    "        leaderboardId: ids.comboRushLeaderboardId,\n"
    "        score: _score,\n"
    "      );\n"
    "    }\n"
    "    for (final localId in ids.achievementIds.keys) {\n"
    "      if (!widget.appState.achievementUnlocked(localId)) continue;\n"
    "      final remoteId = ids.achievementIdFor(localId);\n"
    "      if (remoteId != null) {\n"
    "        await service.unlockAchievement(achievementId: remoteId);\n"
    "      }\n"
    "    }\n"
    "  }\n\n"
    "  Future<void> _finishGame({\n",
)
replace_once(
    'lib/screens/game_screen.dart',
    "      if (widget.mode == GameMode.timed) {\n        title = reason;",
    "      if (widget.mode == GameMode.timed || widget.mode == GameMode.comboRush) {\n        title = widget.mode == GameMode.comboRush ? 'COMBO RUSH BİTTİ' : reason;",
)
replace_once(
    'lib/screens/game_screen.dart',
    "text: 'Tahtayı tamamen boşaltırsan +1000 skor ve bonus coin kazanırsın.',",
    "text: 'Tahtayı tamamen boşaltırsan +1000 skor, +100 coin ve +75 XP kazanırsın.',",
)

# ---------------------------------------------------------------------------
# Music 2.0: six-track shuffle bag + transition gain + fade pause/resume.
# Assets are supplied by the release workflow.
# ---------------------------------------------------------------------------
replace_once(
    'lib/services/audio_service.dart',
    "import 'package:flutter/foundation.dart';\n",
    "import 'package:flutter/foundation.dart';\n\n"
    "import 'music_shuffle_bag.dart';\n"
    "import 'music_volume_state.dart';\n",
)
replace_once(
    'lib/services/audio_service.dart',
    "  static const List<String> _musicTracks = <String>[\n    'audio/bgm_magic_puzzle.ogg',\n    'audio/bgm_cozy_puzzle_3.ogg',\n    'audio/bgm_out_in_space.ogg',\n  ];",
    "  static const List<String> _musicTracks = <String>[\n"
    "    'audio/bgm_magic_puzzle.ogg',\n"
    "    'audio/bgm_cozy_puzzle_3.ogg',\n"
    "    'audio/bgm_out_in_space.ogg',\n"
    "    'audio/bgm_calm_4.ogg',\n"
    "    'audio/bgm_calm_5.ogg',\n"
    "    'audio/bgm_calm_6.ogg',\n"
    "  ];",
)
replace_once(
    'lib/services/audio_service.dart',
    "  final AudioPlayer _musicPlayer = AudioPlayer();\n  final Random _random = Random();",
    "  final AudioPlayer _musicPlayer = AudioPlayer();\n"
    "  final Random _random = Random();\n"
    "  late final MusicShuffleBag _musicBag = MusicShuffleBag(_musicTracks, random: _random);",
)
replace_once(
    'lib/services/audio_service.dart',
    "  int _currentMusicIndex = -1;\n",
    "",
)
replace_once(
    'lib/services/audio_service.dart',
    "  double _musicDuckFactor = 1.0;\n",
    "  double _musicDuckFactor = 1.0;\n  double _musicTransitionGain = 1.0;\n",
)
replace_once(
    'lib/services/audio_service.dart',
    "  double get _effectiveMusicVolume =>\n      (_musicVolume * _musicDuckFactor).clamp(0.0, 1.0).toDouble();",
    "  double get _effectiveMusicVolume => calculateEffectiveMusicVolume(\n"
    "        userVolume: _musicVolume,\n"
    "        duckFactor: _musicDuckFactor,\n"
    "        transitionGain: _musicTransitionGain,\n"
    "      );",
)
replace_block(
    'lib/services/audio_service.dart',
    "  Future<void> _doStartMusic() async {\n",
    "  Future<void> _pauseMusic() async {",
    "  Future<void> _doStartMusic() async {\n"
    "    try {\n"
    "      if (_musicTracks.isEmpty) return;\n"
    "      for (var attempt = 0; attempt < _musicTracks.length; attempt++) {\n"
    "        final nextTrack = _musicBag.takeNext();\n"
    "        if (nextTrack == null) return;\n"
    "        try {\n"
    "          _musicTransitionGain = 0.0;\n"
    "          await _musicPlayer.play(\n"
    "            AssetSource(nextTrack),\n"
    "            volume: _effectiveMusicVolume,\n"
    "            ctx: _gameContext,\n"
    "          );\n"
    "          _musicStarted = true;\n"
    "          _musicPaused = false;\n"
    "          await _fadeMusicTo(1.0, const Duration(milliseconds: 420));\n"
    "          debugPrint('ELXVRO BGM: $nextTrack');\n"
    "          return;\n"
    "        } catch (trackError) {\n"
    "          debugPrint('ELXVRO playlist track skipped: $trackError');\n"
    "          _musicStarted = false;\n"
    "          _musicPaused = false;\n"
    "        }\n"
    "      }\n"
    "      _musicTransitionGain = 1.0;\n"
    "      await _musicPlayer.play(\n"
    "        AssetSource(_legacyMusicFallback),\n"
    "        volume: _effectiveMusicVolume,\n"
    "        ctx: _gameContext,\n"
    "      );\n"
    "      _musicStarted = true;\n"
    "      _musicPaused = false;\n"
    "    } catch (error) {\n"
    "      _musicStarted = false;\n"
    "      _musicPaused = false;\n"
    "      debugPrint('ELXVRO music fallback failed: $error');\n"
    "    } finally {\n"
    "      _musicStartFuture = null;\n"
    "    }\n"
    "  }\n\n"
    "  Future<void> _fadeMusicTo(double target, Duration duration) async {\n"
    "    final start = _musicTransitionGain;\n"
    "    const steps = 6;\n"
    "    final delay = Duration(milliseconds: max(1, duration.inMilliseconds ~/ steps));\n"
    "    for (var step = 1; step <= steps; step++) {\n"
    "      if (_disposed) return;\n"
    "      final t = step / steps;\n"
    "      _musicTransitionGain = start + (target - start) * t;\n"
    "      await _musicPlayer.setVolume(_effectiveMusicVolume);\n"
    "      if (step < steps) await Future<void>.delayed(delay);\n"
    "    }\n"
    "  }\n\n",
)
replace_once(
    'lib/services/audio_service.dart',
    "    try {\n      await _musicPlayer.pause();\n      _musicPaused = true;",
    "    try {\n      await _fadeMusicTo(0.0, const Duration(milliseconds: 180));\n      await _musicPlayer.pause();\n      _musicPaused = true;",
)
replace_once(
    'lib/services/audio_service.dart',
    "      await _musicPlayer.resume();\n      _musicPaused = false;",
    "      await _musicPlayer.resume();\n      _musicPaused = false;\n      await _fadeMusicTo(1.0, const Duration(milliseconds: 260));",
)

# ---------------------------------------------------------------------------
# Brighter pseudo-3D blocks without changing layout/navigation.
# ---------------------------------------------------------------------------
replace_once(
    'lib/widgets/themed_block_tile.dart',
    "            Colors.white.withValues(alpha: 0.19),",
    "            Colors.white.withValues(alpha: 0.27),",
)
replace_once(
    'lib/widgets/themed_block_tile.dart',
    "      ThemeMaterial.glass => 0.34,\n      ThemeMaterial.crystal => 0.38,\n      ThemeMaterial.marble => 0.24,",
    "      ThemeMaterial.glass => 0.44,\n      ThemeMaterial.crystal => 0.49,\n      ThemeMaterial.marble => 0.32,",
)

# ---------------------------------------------------------------------------
# Social Hub uses the real optional service and exposes manual retry/actions.
# ---------------------------------------------------------------------------
replace_once(
    'lib/screens/social_hub_screen.dart',
    "import '../services/social_service.dart';\n",
    "import '../services/play_games_service.dart';\nimport '../services/social_service.dart';\n",
)
replace_once(
    'lib/screens/social_hub_screen.dart',
    "    this.socialService = const LocalSocialService(),\n",
    "    this.socialService,\n",
)
replace_once(
    'lib/screens/social_hub_screen.dart',
    "  final SocialService socialService;\n",
    "  final SocialService? socialService;\n\n  static final SocialService _productionSocialService = PlayGamesService.production();\n",
)
replace_once(
    'lib/screens/social_hub_screen.dart',
    "                        _ConnectionCard(service: socialService),",
    "                        _ConnectionCard(\n                          service: socialService ?? _productionSocialService,\n                        ),",
)
replace_once(
    'lib/screens/social_hub_screen.dart',
    "      (icon: Icons.timer_outlined, label: '2 DAKİKA', score: appState.timedBestScore),\n",
    "      (icon: Icons.timer_outlined, label: '2 DAKİKA', score: appState.timedBestScore),\n"
    "      (icon: Icons.bolt_rounded, label: 'COMBO RUSH', score: appState.comboRushBestScore),\n",
)
replace_once(
    'lib/screens/social_hub_screen.dart',
    "                  onPressed: null,\n                  icon: const Icon(Icons.cloud_outlined),\n                  label: const Text('PLAY CONSOLE SONRASI AKTİF'),",
    "                  onPressed: () async {\n"
    "                    final connected = await service.signIn();\n"
    "                    if (!context.mounted) return;\n"
    "                    ScaffoldMessenger.of(context).showSnackBar(\n"
    "                      SnackBar(\n"
    "                        content: Text(connected\n"
    "                            ? 'Google Play Games bağlandı.'\n"
    "                            : 'Bağlantı kurulamadı; yerel oyun devam ediyor.'),\n"
    "                      ),\n"
    "                    );\n"
    "                    if (connected) await service.showLeaderboards();\n"
    "                  },\n"
    "                  icon: const Icon(Icons.cloud_outlined),\n"
    "                  label: const Text('PLAY GAMES’E BAĞLAN'),",
)

print('ELXVRO Blocks v0.17.0 patch applied successfully.')
