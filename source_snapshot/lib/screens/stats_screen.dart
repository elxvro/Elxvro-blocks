import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/game_theme.dart';
import '../widgets/premium_background.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final selectedTheme = gameThemes.firstWhere(
      (theme) => theme.id == appState.themeId,
      orElse: () => gameThemes.first,
    );

    final stats = <_StatData>[
      _StatData(
        title: 'Oyuncu Seviyesi',
        value: 'LV ${appState.playerLevel}',
        icon: Icons.workspace_premium_rounded,
      ),
      _StatData(
        title: 'Toplam XP',
        value: '${appState.xp}',
        icon: Icons.trending_up_rounded,
      ),
      _StatData(
        title: 'Perfect Clear',
        value: '${appState.perfectClears}',
        icon: Icons.auto_awesome_rounded,
      ),
      _StatData(
        title: 'En Yüksek Skor',
        value: '${appState.bestScore}',
        icon: Icons.emoji_events_rounded,
      ),
      _StatData(
        title: 'Oynanan Oyun',
        value: '${appState.gamesPlayed}',
        icon: Icons.sports_esports_rounded,
      ),
      _StatData(
        title: 'Maksimum Combo',
        value: 'x${appState.maxCombo}',
        icon: Icons.bolt_rounded,
      ),
      _StatData(
        title: 'Toplam Puan',
        value: '${appState.totalScore}',
        icon: Icons.stars_rounded,
      ),
      _StatData(
        title: 'Temizlenen Çizgi',
        value: '${appState.totalLines}',
        icon: Icons.auto_awesome_rounded,
      ),
      _StatData(
        title: 'Yerleştirilen Parça',
        value: '${appState.totalBlocks}',
        icon: Icons.grid_view_rounded,
      ),
      _StatData(
        title: '2 Dakika Rekoru',
        value: '${appState.timedBestScore}',
        icon: Icons.timer_outlined,
      ),
      _StatData(
        title: 'Hedef 5000 Rekoru',
        value: '${appState.targetBestScore}',
        icon: Icons.flag_rounded,
      ),
      _StatData(
        title: 'Günlük Rekor',
        value: '${appState.dailyChallengeBestScore}',
        icon: Icons.local_fire_department_rounded,
      ),
      _StatData(
        title: 'Zen Rekoru',
        value: '${appState.zenBestScore}',
        icon: Icons.spa_rounded,
      ),
      _StatData(
        title: 'Zor Mod Rekoru',
        value: '${appState.hardBestScore}',
        icon: Icons.whatshot_rounded,
      ),
    ];

    return Scaffold(
      body: PremiumBackground(
        top: selectedTheme.backgroundTop,
        bottom: selectedTheme.backgroundBottom,
        material: selectedTheme.material,
        accent: selectedTheme.blockAccent,
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 14),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'İSTATİSTİKLER',
                            style: TextStyle(
                              color: selectedTheme.blockAccent,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'ELXVRO Blocks kariyerin',
                            style: TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.12,
                  ),
                  itemCount: stats.length,
                  itemBuilder: (context, index) => _StatCard(
                    data: stats[index],
                    accent: selectedTheme.blockAccent,
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

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data, required this.accent});

  final _StatData data;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withValues(alpha: 0.045),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(data.icon, color: accent, size: 25),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              data.value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            data.title,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _StatData {
  const _StatData({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;
}
