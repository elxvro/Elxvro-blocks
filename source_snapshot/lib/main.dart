import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'app_state.dart';
import 'models/game_theme.dart';
import 'screens/launch_screen.dart';
import 'services/audio_service.dart';

void main() {
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();

      final appState = AppState();

      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        Zone.current.handleUncaughtError(
          details.exception,
          details.stack ?? StackTrace.current,
        );
      };

      PlatformDispatcher.instance.onError = (error, stackTrace) {
        debugPrint('ELXVRO uncaught platform error: $error');
        debugPrintStack(stackTrace: stackTrace);
        return true;
      };

      ErrorWidget.builder = (FlutterErrorDetails details) {
        return const Material(
          color: Color(0xFF050505),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFFFC86E),
                      size: 42,
                    ),
                    SizedBox(height: 14),
                    Text(
                      'ELXVRO Blocks',
                      style: TextStyle(
                        color: Color(0xFFFFD99A),
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Arayüz yüklenirken bir sorun oluştu.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      };

      runApp(ElxvroBlocksApp(appState: appState));
      unawaited(appState.load());
    },
    (error, stackTrace) {
      debugPrint('ELXVRO uncaught zone error: $error');
      debugPrintStack(stackTrace: stackTrace);
    },
  );
}

class ElxvroBlocksApp extends StatefulWidget {
  const ElxvroBlocksApp({super.key, required this.appState});

  final AppState appState;

  @override
  State<ElxvroBlocksApp> createState() => _ElxvroBlocksAppState();
}

class _ElxvroBlocksAppState extends State<ElxvroBlocksApp>
    with WidgetsBindingObserver {
  bool _isResumed = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.appState.addListener(_handleAppStateChanged);
    unawaited(_syncAudio());
  }

  void _handleAppStateChanged() {
    unawaited(_syncAudio());
  }

  Future<void> _syncAudio() async {
    if (!_isResumed) return;
    final selectedTheme = gameThemes.firstWhere(
      (theme) => theme.id == widget.appState.themeId,
      orElse: () => gameThemes.first,
    );
    await AudioService.instance.configure(
      musicEnabled: widget.appState.isLoaded && widget.appState.musicEnabled,
      sfxEnabled: widget.appState.soundEnabled,
      uiEnabled: widget.appState.uiSoundEnabled,
      musicVolume: widget.appState.musicVolume,
      sfxVolume: widget.appState.sfxVolume,
      uiVolume: widget.appState.uiVolume,
      themeProfile: selectedTheme.audioProfile,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _isResumed = true;
        unawaited(_handleResume());
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _isResumed = false;
        unawaited(AudioService.instance.setSuspended(true));
        break;
    }
  }

  Future<void> _handleResume() async {
    await widget.appState.refreshTemporalState();
    await AudioService.instance.setSuspended(false);
    await _syncAudio();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.appState.removeListener(_handleAppStateChanged);
    unawaited(AudioService.instance.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final selectedTheme = gameThemes.firstWhere(
          (theme) => theme.id == widget.appState.themeId,
          orElse: () => gameThemes.first,
        );
        final accent = selectedTheme.blockAccent;
        final scheme = ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.dark,
        );
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'ELXVRO Blocks',
          theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: selectedTheme.backgroundBottom,
            colorScheme: scheme,
            sliderTheme: SliderThemeData(
              activeTrackColor: accent,
              inactiveTrackColor: selectedTheme.cell,
              thumbColor: accent,
              overlayColor: accent.withValues(alpha: 0.14),
            ),
            useMaterial3: true,
          ),
          home: LaunchScreen(appState: widget.appState),
        );
      },
    );
  }
}
