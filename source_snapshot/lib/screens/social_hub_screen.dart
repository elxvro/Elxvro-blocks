import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/game_theme.dart';
import '../services/audio_service.dart';
import '../services/social_service.dart';
import '../widgets/coin_badge.dart';
import '../widgets/premium_background.dart';

class SocialHubScreen extends StatelessWidget {
  const SocialHubScreen({
    super.key,
    required this.appState,
    this.socialService = const LocalSocialService(),
  });

  final AppState appState;
  final SocialService socialService;

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
                            'LİDERLİK MERKEZİ',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFFFFD98B),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.7,
                            ),
                          ),
                        ),
                        CoinBadge(coins: appState.coins, compact: true),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
                      children: <Widget>[
                        _PlayerCard(appState: appState),
                        const SizedBox(height: 14),
                        const _SectionTitle('KİŞİSEL REKORLAR'),
                        const SizedBox(height: 10),
                        _RecordGrid(appState: appState),
                        const SizedBox(height: 18),
                        const _SectionTitle('BU HAFTA'),
                        const SizedBox(height: 10),
                        _WeeklyCard(appState: appState),
                        const SizedBox(height: 18),
                        const _SectionTitle('GOOGLE PLAY GAMES'),
                        const SizedBox(height: 10),
                        _ConnectionCard(service: socialService),
                        const SizedBox(height: 12),
                        Text(
                          'Play Console yapılandırıldığında bu ekran global sıralama ve başarımları aynı kayıt mimarisi üzerinden gösterecek. Şimdilik hiçbir çevrimiçi sıralama taklit edilmez.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.38),
                            fontSize: 10,
                            height: 1.45,
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

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFFFFC86E).withValues(alpha: 0.07),
        border: Border.all(
          color: const Color(0xFFFFC86E).withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: <Color>[Color(0xFFFFD98B), Color(0xFF9B5E24)],
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '${appState.playerLevel}',
              style: const TextStyle(
                color: Color(0xFF1A0F06),
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  appState.playerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'SEVİYE ${appState.playerLevel}  •  ${appState.xp} XP',
                  style: const TextStyle(
                    color: Color(0xFFFFD98B),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.shield_outlined, color: Color(0xFFFFCF7A)),
        ],
      ),
    );
  }
}

class _RecordGrid extends StatelessWidget {
  const _RecordGrid({required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final records = <({IconData icon, String label, int score})>[
      (icon: Icons.grid_view_rounded, label: 'KLASİK', score: appState.bestScore),
      (icon: Icons.timer_outlined, label: '2 DAKİKA', score: appState.timedBestScore),
      (icon: Icons.flag_outlined, label: 'HEDEF', score: appState.targetBestScore),
      (icon: Icons.today_outlined, label: 'GÜNLÜK', score: appState.dailyChallengeBestScore),
      (icon: Icons.spa_outlined, label: 'ZEN', score: appState.zenBestScore),
      (icon: Icons.whatshot_outlined, label: 'ZOR', score: appState.hardBestScore),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.65,
      ),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(record.icon, color: const Color(0xFFFFCF7A), size: 20),
              const Spacer(),
              Text(
                '${record.score}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                record.label,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WeeklyCard extends StatelessWidget {
  const _WeeklyCard({required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final completed = appState.weeklyScore >= AppState.weeklyGoal;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: completed
              ? const Color(0xFFFFC86E).withValues(alpha: 0.24)
              : Colors.white.withValues(alpha: 0.055),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.calendar_view_week_rounded, color: Color(0xFFFFCF7A)),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'HAFTALIK HEDEF',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Text(
                '${appState.weeklyScore}/${AppState.weeklyGoal}',
                style: const TextStyle(
                  color: Color(0xFFFFD98B),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: appState.weeklyProgress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFC86E)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(child: _MiniStat(label: 'OYUN', value: '${appState.weeklyGames}')),
              const SizedBox(width: 8),
              Expanded(child: _MiniStat(label: 'EN İYİ', value: '${appState.weeklyBestScore}')),
              const SizedBox(width: 8),
              const Expanded(child: _MiniStat(label: 'ÖDÜL', value: '250 C')),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: appState.weeklyRewardAvailable
                  ? () async {
                      final claimed = await appState.claimWeeklyReward();
                      if (!context.mounted || !claimed) return;
                      unawaited(AudioService.instance.playReward());
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('+250 coin haftalık ödül alındı.')),
                      );
                    }
                  : null,
              icon: Icon(
                appState.weeklyRewardClaimed
                    ? Icons.check_circle_rounded
                    : Icons.redeem_rounded,
              ),
              label: Text(
                appState.weeklyRewardClaimed
                    ? 'BU HAFTA ALINDI'
                    : completed
                        ? '250 COIN AL'
                        : 'HEDEFİ TAMAMLA',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC7863C),
                foregroundColor: const Color(0xFF160D06),
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.06),
                disabledForegroundColor: Colors.white38,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({required this.service});

  final SocialService service;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SocialConnectionInfo>(
      future: service.connectionInfo(),
      builder: (context, snapshot) {
        final info = snapshot.data;
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.055)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(Icons.sports_esports_rounded, color: Color(0xFFFFCF7A)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      info?.provider ?? 'Google Play Games',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                    child: Text(
                      info?.connected == true ? 'BAĞLI' : 'ÇEVRİMDIŞI',
                      style: const TextStyle(
                        color: Color(0xFFFFD98B),
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                info?.message ?? 'Bağlantı durumu kontrol ediliyor...',
                style: const TextStyle(color: Colors.white54, fontSize: 11, height: 1.4),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.cloud_outlined),
                  label: const Text('PLAY CONSOLE SONRASI AKTİF'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: <Widget>[
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 7,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFFFD98B),
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.3,
      ),
    );
  }
}
