import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/game_theme.dart';
import '../widgets/coin_badge.dart';
import '../widgets/premium_background.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.appState});

  final AppState appState;

  Future<void> _editName(BuildContext context) async {
    final controller = TextEditingController(text: appState.playerName);
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF12100E),
          title: const Text('OYUNCU ADI'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 18,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'ELXVRO PLAYER',
              counterText: '',
            ),
            onSubmitted: (text) => Navigator.of(dialogContext).pop(text),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('İPTAL'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: const Text('KAYDET'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (value == null || value.trim().isEmpty) return;
    await appState.setPlayerName(value);
  }

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
              final nextMilestone = ((appState.playerLevel ~/ 5) + 1) * 5;
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
                            'PROFİL',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFFFFD98B),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
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
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            color: Colors.white.withValues(alpha: 0.045),
                            border: Border.all(
                              color: const Color(0xFFFFC86E)
                                  .withValues(alpha: 0.22),
                            ),
                          ),
                          child: Column(
                            children: <Widget>[
                              Container(
                                width: 76,
                                height: 76,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: <Color>[
                                      Color(0xFFFFD98B),
                                      Color(0xFF9B5E24),
                                    ],
                                  ),
                                  boxShadow: <BoxShadow>[
                                    BoxShadow(
                                      color: const Color(0xFFFFB84D)
                                          .withValues(alpha: 0.18),
                                      blurRadius: 24,
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${appState.playerLevel}',
                                  style: const TextStyle(
                                    color: Color(0xFF1B1007),
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Flexible(
                                    child: Text(
                                      appState.playerName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.3,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    tooltip: 'Oyuncu adını değiştir',
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => _editName(context),
                                    icon: const Icon(
                                      Icons.edit_rounded,
                                      size: 17,
                                      color: Color(0xFFFFCF7A),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'SEVİYE ${appState.playerLevel}',
                                style: const TextStyle(
                                  color: Color(0xFFFFD98B),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: appState.levelProgress,
                                  minHeight: 9,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.07),
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    Color(0xFFFFC86E),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${appState.currentLevelXp} / ${appState.currentLevelXpTarget} XP  •  TOPLAM ${appState.xp} XP',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _ProfileStat(
                                icon: Icons.emoji_events_rounded,
                                label: 'EN İYİ',
                                value: '${appState.bestScore}',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _ProfileStat(
                                icon: Icons.local_fire_department_rounded,
                                label: 'MAX COMBO',
                                value: 'x${appState.maxCombo}',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _ProfileStat(
                                icon: Icons.grid_view_rounded,
                                label: 'BLOK',
                                value: '${appState.totalBlocks}',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _ProfileStat(
                                icon: Icons.auto_awesome_rounded,
                                label: 'PERFECT CLEAR',
                                value: '${appState.perfectClears}',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'SEVİYE ÖDÜLLERİ',
                          style: TextStyle(
                            color: Color(0xFFFFD98B),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _MilestoneCard(
                          level: nextMilestone,
                          currentLevel: appState.playerLevel,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Her 5 seviyede coin + 2 özel blok kazanırsın. Seviye 5, 10, 15, 20 ve 25 ilerlemelerinde premium temalar da otomatik açılır.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
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

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: const Color(0xFFFFCF7A), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({required this.level, required this.currentLevel});

  final int level;
  final int currentLevel;

  @override
  Widget build(BuildContext context) {
    final themeName = switch (level) {
      5 => 'GECE TEMASI',
      10 => 'MERMER TEMASI',
      15 => 'ATEŞ TEMASI',
      20 => 'DOĞA TEMASI',
      25 => 'AURORA TEMASI',
      _ => 'PREMIUM ÖDÜL',
    };
    final coinReward = 200 + level * 10;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC86E).withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFFFC86E).withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFC86E).withValues(alpha: 0.12),
            ),
            alignment: Alignment.center,
            child: Text(
              '$level',
              style: const TextStyle(
                color: Color(0xFFFFD98B),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'SEVİYE $level ÖDÜLÜ',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '+$coinReward coin  •  +2 özel blok  •  $themeName',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 9,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${(level - currentLevel).clamp(0, 99)} LV',
            style: const TextStyle(
              color: Color(0xFFFFC86E),
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
