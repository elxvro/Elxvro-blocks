import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/game_theme.dart';
import '../services/audio_service.dart';
import '../widgets/premium_background.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final selectedTheme = gameThemes.firstWhere(
      (theme) => theme.id == appState.themeId,
      orElse: () => gameThemes.first,
    );

    return Scaffold(
      body: PremiumBackground(
        top: selectedTheme.backgroundTop,
        bottom: selectedTheme.backgroundBottom,
        material: selectedTheme.material,
        accent: selectedTheme.blockAccent,
        child: SafeArea(
          child: AnimatedBuilder(
            animation: appState,
            builder: (context, _) {
              return Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6, 14, 8),
                    child: Row(
                      children: <Widget>[
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const Expanded(
                          child: Text(
                            'AYARLAR',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFFFFD98B),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                      children: <Widget>[
                        _SettingCard(
                          icon: Icons.music_note_rounded,
                          title: 'ARKA PLAN MÜZİĞİ',
                          subtitle: 'Cozy Puzzle • bestelenmiş, sakin ve melodik oyun müziği',
                          value: appState.musicEnabled,
                          onChanged: appState.setMusicEnabled,
                        ),
                        const SizedBox(height: 12),
                        _VolumeCard(
                          icon: Icons.graphic_eq_rounded,
                          title: 'MÜZİK SEVİYESİ',
                          value: appState.musicVolume,
                          enabled: appState.musicEnabled,
                          onChanged: (value) {
                            unawaited(appState.setMusicVolume(value));
                          },
                        ),
                        const SizedBox(height: 12),
                        _SettingCard(
                          icon: Icons.volume_up_rounded,
                          title: 'SES EFEKTLERİ',
                          subtitle: 'Temaya özel yumuşak yerleştirme, temizleme ve combo sesleri',
                          value: appState.soundEnabled,
                          onChanged: appState.setSoundEnabled,
                        ),
                        const SizedBox(height: 12),
                        _VolumeCard(
                          icon: Icons.surround_sound_rounded,
                          title: 'EFEKT SEVİYESİ',
                          value: appState.sfxVolume,
                          enabled: appState.soundEnabled,
                          onChanged: (value) {
                            unawaited(appState.setSfxVolume(value));
                          },
                          onPreview: appState.soundEnabled
                              ? () => unawaited(
                                  AudioService.instance.playThemePreview(
                                    selectedTheme.audioProfile,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 12),
                        _SettingCard(
                          icon: Icons.touch_app_rounded,
                          title: 'ARAYÜZ SESLERİ',
                          subtitle: 'Menü ve butonlarda yumuşak dokunuş sesleri',
                          value: appState.uiSoundEnabled,
                          onChanged: appState.setUiSoundEnabled,
                        ),
                        const SizedBox(height: 12),
                        _VolumeCard(
                          icon: Icons.tune_rounded,
                          title: 'ARAYÜZ SES SEVİYESİ',
                          value: appState.uiVolume,
                          enabled: appState.uiSoundEnabled,
                          onChanged: (value) {
                            unawaited(appState.setUiVolume(value));
                          },
                          onPreview: appState.uiSoundEnabled
                              ? () => unawaited(AudioService.instance.playClick())
                              : null,
                        ),
                        const SizedBox(height: 12),
                        _SettingCard(
                          icon: Icons.vibration_rounded,
                          title: 'TİTREŞİM',
                          subtitle: 'Yerleştirme ve temizleme haptikleri',
                          value: appState.hapticsEnabled,
                          onChanged: appState.setHapticsEnabled,
                        ),
                        const SizedBox(height: 12),
                        _SettingCard(
                          icon: Icons.speed_rounded,
                          title: 'PERFORMANS MODU',
                          subtitle: '2D kırılma, toz, yaprak ve combo efektlerini azaltır; düşük güçlü cihazlarda daha akıcıdır',
                          value: appState.performanceMode,
                          onChanged: appState.setPerformanceMode,
                        ),
                        const SizedBox(height: 12),
                        _ActionCard(
                          icon: Icons.school_outlined,
                          title: 'EĞİTİMİ TEKRAR GÖSTER',
                          subtitle: 'Bir sonraki oyunda başlangıç eğitimini yeniden aç',
                          onTap: () async {
                            await appState.resetTutorial();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Eğitim bir sonraki oyunda gösterilecek.',
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        const _StatusCard(
                          icon: Icons.sports_esports_rounded,
                          title: 'GOOGLE PLAY GAMES',
                          subtitle: 'Altyapı hazır • Play Console bağlantısı sonraki sürümde açılabilir',
                          status: 'HAZIRLIK',
                        ),
                        const SizedBox(height: 22),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.035),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'ELXVRO BLOCKS',
                                style: TextStyle(
                                  color: Color(0xFFFFD98B),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.4,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'v0.10.1  •  2D FX Engine',
                                style: TextStyle(color: Colors.white54),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'com.elxvro.elxvro_blocks',
                                style: TextStyle(
                                  color: Colors.white30,
                                  fontSize: 10,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
}

class _VolumeCard extends StatelessWidget {
  const _VolumeCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.enabled,
    required this.onChanged,
    this.onPreview,
  });

  final IconData icon;
  final String title;
  final double value;
  final bool enabled;
  final ValueChanged<double> onChanged;
  final VoidCallback? onPreview;

  @override
  Widget build(BuildContext context) {
    final percent = (value * 100).round();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: enabled ? 0.04 : 0.025),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.055)),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                icon,
                color: enabled ? const Color(0xFFFFCF7A) : Colors.white24,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: enabled ? Colors.white : Colors.white38,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
              Text(
                '%$percent',
                style: TextStyle(
                  color: enabled ? const Color(0xFFFFD98B) : Colors.white30,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (onPreview != null) ...<Widget>[
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Sesi dene',
                  visualDensity: VisualDensity.compact,
                  onPressed: onPreview,
                  icon: const Icon(
                    Icons.play_circle_outline_rounded,
                    color: Color(0xFFFFD98B),
                  ),
                ),
              ],
            ],
          ),
          Slider(
            value: value,
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: <Widget>[
              Icon(icon, color: const Color(0xFFFFCF7A)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.055)),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: const Color(0xFFFFCF7A)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFFC86E).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              status,
              style: const TextStyle(
                color: Color(0xFFFFD98B),
                fontSize: 8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  const _SettingCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.055)),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        secondary: Icon(icon, color: const Color(0xFFFFCF7A)),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.9,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.white38, fontSize: 11),
        ),
        activeThumbColor: const Color(0xFFFFD98B),
        activeTrackColor: const Color(0xFFC7863C),
      ),
    );
  }
}
