import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  AudioService._();

  static final AudioService instance = AudioService._();

  static const Set<String> _profiles = <String>{
    'glass',
    'wood',
    'stone',
    'leaf',
    'crystal',
    'marble',
  };

  static const List<String> _musicTracks = <String>[
    'audio/bgm_magic_puzzle.ogg',
    'audio/bgm_cozy_puzzle_3.ogg',
    'audio/bgm_out_in_space.ogg',
  ];

  // Kept only as an emergency runtime fallback. Normal playback uses the
  // non-repeating playlist above, so the old track no longer loops forever.
  static const String _legacyMusicFallback = 'audio/cozy_puzzle_music.ogg';

  static const Map<String, Duration> _sfxDurations = <String, Duration>{
    'audio/ui_tap_v1.wav': Duration(milliseconds: 120),
    'audio/ui_tap_v2.wav': Duration(milliseconds: 120),
    'audio/ui_tap_v3.wav': Duration(milliseconds: 120),
    'audio/reward.wav': Duration(milliseconds: 1050),
    'audio/record_fanfare.wav': Duration(milliseconds: 2250),
    'audio/game_over.wav': Duration(milliseconds: 1300),
    'audio/glass_place.wav': Duration(milliseconds: 380),
    'audio/glass_clear.wav': Duration(milliseconds: 780),
    'audio/glass_combo.wav': Duration(milliseconds: 1100),
    'audio/glass_perfect.wav': Duration(milliseconds: 1600),
    'audio/wood_place.wav': Duration(milliseconds: 380),
    'audio/wood_clear.wav': Duration(milliseconds: 780),
    'audio/wood_combo.wav': Duration(milliseconds: 1100),
    'audio/wood_perfect.wav': Duration(milliseconds: 1600),
    'audio/stone_place.wav': Duration(milliseconds: 380),
    'audio/stone_clear.wav': Duration(milliseconds: 780),
    'audio/stone_combo.wav': Duration(milliseconds: 1100),
    'audio/stone_perfect.wav': Duration(milliseconds: 1600),
    'audio/leaf_place.wav': Duration(milliseconds: 380),
    'audio/leaf_clear.wav': Duration(milliseconds: 780),
    'audio/leaf_combo.wav': Duration(milliseconds: 1100),
    'audio/leaf_perfect.wav': Duration(milliseconds: 1600),
    'audio/crystal_place.wav': Duration(milliseconds: 380),
    'audio/crystal_clear.wav': Duration(milliseconds: 1050),
    'audio/crystal_combo.wav': Duration(milliseconds: 1100),
    'audio/crystal_perfect.wav': Duration(milliseconds: 1600),
    'audio/marble_place.wav': Duration(milliseconds: 380),
    'audio/marble_clear.wav': Duration(milliseconds: 1300),
    'audio/marble_combo.wav': Duration(milliseconds: 1100),
    'audio/marble_perfect.wav': Duration(milliseconds: 1600),
  };

  final AudioPlayer _musicPlayer = AudioPlayer();
  final Random _random = Random();
  final Map<String, Future<AudioPool>> _pools = <String, Future<AudioPool>>{};

  bool _initialized = false;
  Future<void>? _initializationFuture;
  bool _musicStarted = false;
  Future<void>? _musicStartFuture;
  StreamSubscription<void>? _musicCompletionSubscription;
  bool _musicPaused = false;
  int _currentMusicIndex = -1;
  bool _musicEnabled = true;
  bool _sfxEnabled = true;
  bool _uiEnabled = true;
  bool _suspended = false;
  bool _disposed = false;
  double _musicVolume = 0.20;
  double _sfxVolume = 0.74;
  double _uiVolume = 0.66;
  double _musicDuckFactor = 1.0;
  int _musicDuckToken = 0;
  String _activeProfile = 'glass';

  double get _effectiveMusicVolume =>
      (_musicVolume * _musicDuckFactor).clamp(0.0, 1.0).toDouble();

  static final AudioContext _gameContext = AudioContext(
    android: AudioContextAndroid(
      audioMode: AndroidAudioMode.normal,
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.game,
      audioFocus: AndroidAudioFocus.none,
    ),
  );

  static final AudioContext _sfxContext = AudioContext(
    android: AudioContextAndroid(
      audioMode: AndroidAudioMode.normal,
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.game,
      audioFocus: AndroidAudioFocus.none,
    ),
  );

  Future<void> configure({
    required bool musicEnabled,
    required bool sfxEnabled,
    required bool uiEnabled,
    required double musicVolume,
    required double sfxVolume,
    required double uiVolume,
    String themeProfile = 'glass',
  }) async {
    if (_disposed) return;

    final nextMusicEnabled = musicEnabled;
    final nextSfxEnabled = sfxEnabled;
    final nextUiEnabled = uiEnabled;
    final nextMusicVolume = musicVolume.clamp(0.0, 1.0).toDouble();
    final nextSfxVolume = sfxVolume.clamp(0.0, 1.0).toDouble();
    final nextUiVolume = uiVolume.clamp(0.0, 1.0).toDouble();
    final nextProfile = _safeProfile(themeProfile);

    final musicEnabledChanged = nextMusicEnabled != _musicEnabled;
    final sfxEnabledChanged = nextSfxEnabled != _sfxEnabled;
    final uiEnabledChanged = nextUiEnabled != _uiEnabled;
    final musicVolumeChanged = (nextMusicVolume - _musicVolume).abs() > 0.015;
    final sfxVolumeChanged = (nextSfxVolume - _sfxVolume).abs() > 0.005;
    final uiVolumeChanged = (nextUiVolume - _uiVolume).abs() > 0.005;
    final profileChanged = nextProfile != _activeProfile;

    _musicEnabled = nextMusicEnabled;
    _sfxEnabled = nextSfxEnabled;
    _uiEnabled = nextUiEnabled;
    _musicVolume = nextMusicVolume;
    _sfxVolume = nextSfxVolume;
    _uiVolume = nextUiVolume;
    _activeProfile = nextProfile;

    try {
      await _ensureInitialized();

      if (musicVolumeChanged || !_musicStarted) {
        await _musicPlayer.setVolume(_effectiveMusicVolume);
      }

      if (_musicEnabled && !_suspended) {
        if (!_musicStarted) {
          await _startMusic();
        } else if (_musicPaused || musicEnabledChanged) {
          await _resumeMusic();
        }
      } else if (_musicStarted && !_musicPaused) {
        await _pauseMusic();
      }

      if (_uiEnabled && uiEnabledChanged) {
        unawaited(_warmCommon());
      }
      if (_sfxEnabled &&
          (profileChanged || sfxEnabledChanged || !_hasThemePools(nextProfile))) {
        unawaited(_warmTheme(nextProfile));
      }

      if (sfxVolumeChanged || uiVolumeChanged) {
        // AudioPool volume is supplied at playback time. No platform call is
        // needed here; keeping this branch intentionally empty prevents the
        // settings slider from causing repeated native audio reconfiguration.
      }
    } catch (error, stackTrace) {
      debugPrint('ELXVRO audio configure failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _ensureInitialized() {
    if (_initialized || _disposed) return Future<void>.value();
    return _initializationFuture ??= _initializeAudio();
  }

  Future<void> _initializeAudio() async {
    try {
      await AudioPlayer.global.ensureInitialized();
      await AudioPlayer.global.setAudioContext(_gameContext);
      await _musicPlayer.setAudioContext(_gameContext);
      await _musicPlayer.setReleaseMode(ReleaseMode.stop);
      await _musicPlayer.setVolume(_effectiveMusicVolume);
      _musicCompletionSubscription ??=
          _musicPlayer.onPlayerComplete.listen((_) {
        if (_disposed || _suspended || !_musicEnabled) return;
        _musicStarted = false;
        _musicPaused = false;
        unawaited(_startMusic());
      });
      _initialized = true;

      if (_sfxEnabled || _uiEnabled) {
        unawaited(_warmCommon());
      }
      if (_sfxEnabled) {
        unawaited(_warmTheme(_activeProfile));
      }
    } finally {
      _initializationFuture = null;
    }
  }

  Future<void> _startMusic() {
    if (_disposed || _suspended || !_musicEnabled || _musicVolume <= 0) {
      return Future<void>.value();
    }
    if (_musicStarted) return Future<void>.value();
    return _musicStartFuture ??= _doStartMusic();
  }

  Future<void> _doStartMusic() async {
    try {
      if (_musicTracks.isEmpty) return;

      var nextIndex = _random.nextInt(_musicTracks.length);
      if (_musicTracks.length > 1 && nextIndex == _currentMusicIndex) {
        nextIndex = (nextIndex + 1 + _random.nextInt(_musicTracks.length - 1)) %
            _musicTracks.length;
      }

      final nextTrack = _musicTracks[nextIndex];
      await _musicPlayer.play(
        AssetSource(nextTrack),
        volume: _effectiveMusicVolume,
        ctx: _gameContext,
      );
      _currentMusicIndex = nextIndex;
      _musicStarted = true;
      _musicPaused = false;
      debugPrint('ELXVRO BGM: $nextTrack');
    } catch (error) {
      debugPrint('ELXVRO playlist track failed, using fallback: $error');
      try {
        await _musicPlayer.play(
          AssetSource(_legacyMusicFallback),
          volume: _effectiveMusicVolume,
          ctx: _gameContext,
        );
        _musicStarted = true;
        _musicPaused = false;
      } catch (fallbackError) {
        _musicStarted = false;
        _musicPaused = false;
        debugPrint('ELXVRO music fallback failed: $fallbackError');
      }
    } finally {
      _musicStartFuture = null;
    }
  }

  Future<void> _pauseMusic() async {
    if (!_musicStarted || _musicPaused) return;
    try {
      await _musicPlayer.pause();
      _musicPaused = true;
    } catch (error) {
      debugPrint('ELXVRO music pause failed: $error');
    }
  }

  Future<void> _resumeMusic() async {
    if (_disposed || _suspended || !_musicEnabled) return;
    if (!_musicStarted) {
      await _startMusic();
      return;
    }
    if (!_musicPaused) return;
    try {
      await _musicPlayer.resume();
      _musicPaused = false;
    } catch (error) {
      debugPrint('ELXVRO music resume failed: $error');
      _musicStarted = false;
      _musicPaused = false;
      await _startMusic();
    }
  }

  Future<void> setSuspended(bool value) async {
    if (_disposed || _suspended == value) return;
    _suspended = value;
    try {
      await _ensureInitialized();
      if (_suspended) {
        await _pauseMusic();
      } else if (_musicEnabled) {
        await _resumeMusic();
      }
    } catch (error) {
      debugPrint('ELXVRO audio lifecycle sync failed: $error');
    }
  }

  Future<void> _duckMusic({
    required double factor,
    required Duration duration,
  }) async {
    if (_disposed || !_musicEnabled || !_musicStarted || _musicPaused) return;
    final token = ++_musicDuckToken;
    _musicDuckFactor = factor.clamp(0.08, 1.0).toDouble();
    try {
      await _musicPlayer.setVolume(_effectiveMusicVolume);
      await Future<void>.delayed(duration);
      if (_disposed || token != _musicDuckToken) return;
      _musicDuckFactor = 1.0;
      await _musicPlayer.setVolume(_effectiveMusicVolume);
    } catch (error) {
      debugPrint('ELXVRO music duck failed: $error');
    }
  }

  Future<void> playClick() => _playUiVariant();

  Future<void> playPlace(String profile) =>
      _playVariant(_safeProfile(profile), 'place', 3, 0.70);

  Future<void> playClear(String profile) =>
      _playVariant(_safeProfile(profile), 'clear', 3, 0.62);

  Future<void> playClearTier(
    String profile, {
    required int lineCount,
    required int combo,
  }) async {
    final safe = _safeProfile(profile);

    Duration fractureDelay() {
      switch (safe) {
        case 'glass':
          return const Duration(milliseconds: 22);
        case 'crystal':
          return const Duration(milliseconds: 18);
        case 'wood':
          return const Duration(milliseconds: 38);
        case 'stone':
          return const Duration(milliseconds: 54);
        case 'marble':
          return const Duration(milliseconds: 50);
        case 'leaf':
          return const Duration(milliseconds: 30);
        default:
          return const Duration(milliseconds: 34);
      }
    }

    if (lineCount >= 3 || combo >= 4) {
      unawaited(
        _duckMusic(
          factor: 0.38,
          duration: const Duration(milliseconds: 860),
        ),
      );
      // A real fracture has a sharp material transient followed by body/impact.
      // Layer the existing real-material sample under the combo hit.
      unawaited(_playVariant(safe, 'clear', 3, 0.48));
      await Future<void>.delayed(fractureDelay());
      await _play('audio/${safe}_combo.wav', 0.69);
      return;
    }

    if (lineCount >= 2 || combo >= 2) {
      unawaited(_playVariant(safe, 'clear', 3, 0.57));
      await Future<void>.delayed(fractureDelay());
      await _playVariant(safe, 'clear', 3, 0.42);
      return;
    }

    await _playVariant(safe, 'clear', 3, 0.56);
  }

  Future<void> playCombo(String profile) =>
      _play('audio/${_safeProfile(profile)}_combo.wav', 0.74);

  Future<void> playPerfect(String profile) async {
    unawaited(
      _duckMusic(
        factor: 0.26,
        duration: const Duration(milliseconds: 1250),
      ),
    );
    await _play('audio/${_safeProfile(profile)}_perfect.wav', 0.80);
  }

  Future<void> playThemePreview(String profile) =>
      _playVariant(_safeProfile(profile), 'clear', 3, 0.56);

  Future<void> playReward() async {
    unawaited(
      _duckMusic(
        factor: 0.48,
        duration: const Duration(milliseconds: 780),
      ),
    );
    await _play('audio/reward.wav', 0.86);
  }

  Future<void> playLiveRecordCue() async {
    unawaited(
      _duckMusic(
        factor: 0.34,
        duration: const Duration(milliseconds: 1050),
      ),
    );
    await _play('audio/reward.wav', 0.94);
  }

  Future<void> playRecordCelebration() async {
    unawaited(
      _duckMusic(
        factor: 0.18,
        duration: const Duration(milliseconds: 2200),
      ),
    );
    await _play('audio/record_fanfare.wav', 0.96);
  }

  Future<void> playGameOver() => _play('audio/game_over.wav', 0.62);

  String _safeProfile(String profile) => _profiles.contains(profile) ? profile : 'glass';

  bool _hasThemePools(String profile) {
    return _pools.containsKey('audio/${profile}_place_v1.wav') &&
        _pools.containsKey('audio/${profile}_clear_v1.wav') &&
        _pools.containsKey('audio/${profile}_combo.wav') &&
        _pools.containsKey('audio/${profile}_perfect.wav');
  }

  Future<void> _warmCommon() async {
    for (final asset in <String>[
      'audio/ui_tap_v1.wav',
      'audio/ui_tap_v2.wav',
      'audio/ui_tap_v3.wav',
      'audio/reward.wav',
      'audio/record_fanfare.wav',
      'audio/game_over.wav',
    ]) {
      if (_disposed) return;
      try {
        await _poolFor(asset);
      } catch (error) {
        debugPrint('ELXVRO common SFX warmup failed ($asset): $error');
      }
    }
  }

  Future<void> _warmTheme(String profile) async {
    final safe = _safeProfile(profile);
    _disposeOtherThemePools(safe);
    final assets = <String>[
      for (var variant = 1; variant <= 3; variant++)
        'audio/${safe}_place_v$variant.wav',
      for (var variant = 1; variant <= 3; variant++)
        'audio/${safe}_clear_v$variant.wav',
      'audio/${safe}_combo.wav',
      'audio/${safe}_perfect.wav',
    ];
    for (final asset in assets) {
      if (_disposed) return;
      try {
        await _poolFor(asset);
      } catch (error) {
        debugPrint('ELXVRO theme SFX warmup failed ($asset): $error');
      }
    }
  }

  void _disposeOtherThemePools(String keepProfile) {
    final keepPrefix = 'audio/${_safeProfile(keepProfile)}_';
    final removable = _pools.keys.where((asset) {
      final isThemeAsset = _profiles.any((profile) => asset.startsWith('audio/${profile}_'));
      return isThemeAsset && !asset.startsWith(keepPrefix);
    }).toList(growable: false);

    for (final asset in removable) {
      final future = _pools.remove(asset);
      if (future != null) {
        unawaited(
          future.then((pool) => pool.dispose()).catchError((Object error) {
            debugPrint('ELXVRO pool dispose failed ($asset): $error');
          }),
        );
      }
    }
  }

  Future<void> _playUiVariant() async {
    if (_disposed || _suspended || !_uiEnabled || _uiVolume <= 0) return;
    final variant = 1 + _random.nextInt(3);
    await _playWithVolume(
      'audio/ui_tap_v$variant.wav',
      (_uiVolume * 0.68).clamp(0.0, 1.0).toDouble(),
      requireSfxEnabled: false,
    );
  }

  Future<void> _playVariant(
    String profile,
    String event,
    int variants,
    double gain,
  ) {
    final safeVariants = variants < 1 ? 1 : variants;
    final variant = 1 + _random.nextInt(safeVariants);
    return _play('audio/${profile}_${event}_v$variant.wav', gain);
  }

  Future<AudioPool> _poolFor(String asset) {
    final existing = _pools[asset];
    if (existing != null) return existing;

    final future = AudioPool.create(
      source: AssetSource(asset),
      maxPlayers: 4,
      minPlayers: 1,
      playerMode: PlayerMode.lowLatency,
      audioContext: _sfxContext,
    );
    _pools[asset] = future;
    return future;
  }

  Future<void> _play(String asset, double gain) {
    if (!_sfxEnabled || _sfxVolume <= 0) return Future<void>.value();
    return _playWithVolume(
      asset,
      (_sfxVolume * gain).clamp(0.0, 1.0).toDouble(),
    );
  }

  Future<void> _playWithVolume(
    String asset,
    double volume, {
    bool requireSfxEnabled = true,
  }) async {
    if (_disposed || _suspended || volume <= 0) return;
    if (requireSfxEnabled && !_sfxEnabled) return;
    if (!requireSfxEnabled && !_uiEnabled) return;

    try {
      await _ensureInitialized();
      final pool = await _poolFor(asset);
      if (_disposed || _suspended) return;
      if (requireSfxEnabled && !_sfxEnabled) return;
      if (!requireSfxEnabled && !_uiEnabled) return;

      final stop = await pool.start(volume: volume.clamp(0.0, 1.0).toDouble());

      final duration = _sfxDurations[asset] ?? _fallbackDuration(asset);
      Timer(duration, () {
        if (!_disposed) {
          unawaited(stop());
        }
      });
    } catch (error) {
      debugPrint('ELXVRO SFX failed ($asset): $error');
    }
  }

  Duration _fallbackDuration(String asset) {
    if (asset.contains('_place_v')) {
      return const Duration(milliseconds: 380);
    }
    if (asset.contains('_clear_v')) {
      return const Duration(milliseconds: 1100);
    }
    return const Duration(seconds: 2);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    final pools = _pools.values.toList(growable: false);
    _pools.clear();

    for (final poolFuture in pools) {
      try {
        final pool = await poolFuture;
        await pool.dispose();
      } catch (error) {
        debugPrint('ELXVRO audio pool dispose failed: $error');
      }
    }

    try {
      await _musicCompletionSubscription?.cancel();
      _musicCompletionSubscription = null;
      await _musicPlayer.dispose();
    } catch (error) {
      debugPrint('ELXVRO audio dispose failed: $error');
    }
  }
}
