import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/adventure_level.dart';
import '../models/game_theme.dart';
import '../widgets/coin_badge.dart';
import '../widgets/premium_background.dart';
import 'falling_blocks_screen.dart';

class AdventureScreen extends StatelessWidget {
  const AdventureScreen({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final theme = gameThemes.firstWhere(
          (item) => item.id == appState.themeId,
          orElse: () => gameThemes.first,
        );
        final accent = theme.blockAccent;
        final completed = appState.adventureCompletedCount;

        return Scaffold(
          body: PremiumBackground(
            top: theme.backgroundTop,
            bottom: theme.backgroundBottom,
            material: theme.material,
            accent: accent,
            child: SafeArea(
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6, 14, 6),
                    child: Row(
                      children: <Widget>[
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        Expanded(
                          child: Text(
                            'MACERA',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: accent,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.2,
                            ),
                          ),
                        ),
                        CoinBadge(coins: appState.coins, compact: true),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        color: theme.board.withValues(alpha: 0.78),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Column(
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Icon(Icons.map_rounded, color: accent),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  '60 BÖLÜMLÜK YOLCULUK',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                              Text(
                                '$completed/$adventureLevelCount',
                                style: TextStyle(
                                  color: accent,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              minHeight: 7,
                              value: completed / adventureLevelCount,
                              backgroundColor: Colors.white.withValues(alpha: 0.06),
                              valueColor: AlwaysStoppedAnimation<Color>(accent),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Her bölümde hedef puan yükselir, düşüş hızlanır, başlangıç alanı zorlaşır ve renk paleti değişir.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.52),
                              fontSize: 10,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: adventureLevels.length,
                      itemBuilder: (context, index) {
                        final level = adventureLevels[index];
                        final unlocked =
                            appState.isAdventureLevelUnlocked(level.number);
                        final done =
                            appState.isAdventureLevelCompleted(level.number);
                        final levelAccent = _adventureAccent(level.number, accent);
                        return _AdventureLevelCard(
                          level: level,
                          unlocked: unlocked,
                          completed: done,
                          accent: levelAccent,
                          surface: theme.board,
                          onTap: unlocked
                              ? () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => FallingBlocksScreen(
                                        appState: appState,
                                        adventureLevel: level,
                                      ),
                                    ),
                                  );
                                }
                              : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AdventureLevelCard extends StatelessWidget {
  const _AdventureLevelCard({
    required this.level,
    required this.unlocked,
    required this.completed,
    required this.accent,
    required this.surface,
    required this.onTap,
  });

  final AdventureLevel level;
  final bool unlocked;
  final bool completed;
  final Color accent;
  final Color surface;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = unlocked ? Colors.white : Colors.white30;
    return Material(
      color: Color.lerp(surface, Colors.black, 0.14)!.withValues(
        alpha: unlocked ? 0.88 : 0.46,
      ),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: completed
                  ? accent.withValues(alpha: 0.52)
                  : Colors.white.withValues(alpha: unlocked ? 0.08 : 0.035),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '${level.number}',
                      style: TextStyle(
                        color: completed ? accent : foreground,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Icon(
                    completed
                        ? Icons.check_circle_rounded
                        : unlocked
                            ? Icons.play_circle_fill_rounded
                            : Icons.lock_rounded,
                    color: completed
                        ? accent
                        : unlocked
                            ? Colors.white54
                            : Colors.white24,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                'BÖLÜM ${level.chapter} • ${level.difficultyLabel}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: unlocked ? accent.withValues(alpha: 0.86) : Colors.white24,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                '${level.fallingTargetScore}',
                style: TextStyle(
                  color: foreground,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'PUAN',
                style: TextStyle(
                  color: unlocked ? Colors.white38 : Colors.white.withValues(alpha: 0.18),
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 7),
              Row(
                children: <Widget>[
                  Icon(
                    Icons.monetization_on_rounded,
                    size: 11,
                    color: unlocked ? accent : Colors.white.withValues(alpha: 0.18),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '+${level.reward}',
                    style: TextStyle(
                      color: unlocked ? accent : Colors.white.withValues(alpha: 0.18),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _adventureAccent(int level, Color themeAccent) {
  const colors = <Color>[
    Color(0xFF6FE7FF),
    Color(0xFFB38CFF),
    Color(0xFFFF826B),
    Color(0xFF72E99A),
    Color(0xFFFFD56A),
    Color(0xFFFF78C8),
    Color(0xFF82A8FF),
  ];
  final levelColor = colors[(level - 1) % colors.length];
  return Color.lerp(levelColor, themeAccent, 0.22)!;
}
