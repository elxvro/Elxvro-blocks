import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/block_piece.dart';
import '../models/game_theme.dart';
import '../services/audio_service.dart';
import '../widgets/coin_badge.dart';
import '../widgets/piece_preview.dart';
import '../widgets/premium_background.dart';
import '../widgets/themed_block_tile.dart';

class ThemesScreen extends StatelessWidget {
  const ThemesScreen({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final selected = gameThemes.firstWhere(
          (theme) => theme.id == appState.themeId,
          orElse: () => gameThemes.first,
        );

        return Scaffold(
          body: PremiumBackground(
            top: selected.backgroundTop,
            bottom: selected.backgroundBottom,
            material: selected.material,
            accent: selected.blockAccent,
            child: SafeArea(
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 18, 6),
                    child: Row(
                      children: <Widget>[
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const SizedBox(width: 4),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'TEMALAR',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2.5,
                                  color: Color(0xFFFFD99A),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Coin ile aç, kalıcı olarak kullan',
                                style: TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        CoinBadge(coins: appState.coins, compact: true),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
                    child: _ThemeLivePreview(theme: selected),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
                      itemCount: gameThemes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final theme = gameThemes[index];
                        final isSelected = appState.themeId == theme.id;
                        final unlocked = appState.isThemeUnlocked(theme.id);
                        final price = appState.themePrice(theme.id);
                        return _ThemeCard(
                          theme: theme,
                          isSelected: isSelected,
                          unlocked: unlocked,
                          price: price,
                          onTap: () async {
                            if (unlocked) {
                              await appState.setTheme(theme.id);
                              unawaited(
                                AudioService.instance.playThemePreview(
                                  theme.audioProfile,
                                ),
                              );
                              return;
                            }
                            final ok = await appState.unlockTheme(theme.id);
                            if (!context.mounted) return;
                            if (ok) {
                              unawaited(AudioService.instance.playReward());
                              unawaited(
                                AudioService.instance.playThemePreview(
                                  theme.audioProfile,
                                ),
                              );
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  ok
                                      ? '${theme.name} teması açıldı.'
                                      : 'Yeterli coin yok.',
                                ),
                              ),
                            );
                          },
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

class _ThemeLivePreview extends StatelessWidget {
  const _ThemeLivePreview({required this.theme});

  final GameThemeData theme;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      height: 158,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            theme.backgroundTop.withValues(alpha: 0.96),
            theme.board.withValues(alpha: 0.96),
            theme.backgroundBottom,
          ],
        ),
        border: Border.all(
          color: theme.blockAccent.withValues(alpha: 0.30),
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  theme.name.toUpperCase(),
                  style: TextStyle(
                    color: theme.blockAccent,
                    fontWeight: FontWeight.w900,
                    fontSize: 19,
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  theme.subtitle,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'CANLI ÖNİZLEME',
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 122,
            height: 122,
            child: Stack(
              children: <Widget>[
                Positioned(
                  left: 6,
                  top: 8,
                  width: 52,
                  height: 52,
                  child: ThemedBlockTile(
                    material: theme.material,
                    base: theme.block,
                    accent: theme.blockAccent,
                  ),
                ),
                Positioned(
                  right: 5,
                  top: 8,
                  width: 52,
                  height: 52,
                  child: ThemedBlockTile(
                    material: theme.material,
                    base: theme.block,
                    accent: theme.blockAccent,
                  ),
                ),
                Positioned(
                  left: 35,
                  bottom: 5,
                  width: 52,
                  height: 52,
                  child: ThemedBlockTile(
                    material: theme.material,
                    base: theme.block,
                    accent: theme.blockAccent,
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

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.theme,
    required this.isSelected,
    required this.unlocked,
    required this.price,
    required this.onTap,
  });

  final GameThemeData theme;
  final bool isSelected;
  final bool unlocked;
  final int price;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? theme.blockAccent.withValues(alpha: 0.95)
                  : Colors.white.withValues(alpha: 0.10),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 76,
                height: 76,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      theme.board,
                      theme.backgroundTop.withValues(alpha: 0.96),
                    ],
                  ),
                  border: Border.all(
                    color: theme.blockAccent.withValues(alpha: 0.24),
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: theme.blockAccent.withValues(alpha: 0.12),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    Opacity(
                      opacity: unlocked ? 1 : 0.35,
                      child: PiecePreview(
                        piece: blockCatalog[8],
                        color: theme.block,
                        accent: theme.blockAccent,
                        material: theme.material,
                        cellSize: 20,
                      ),
                    ),
                    if (!unlocked)
                      const Icon(Icons.lock_rounded, color: Colors.white70),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      theme.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      theme.subtitle,
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                    if (!unlocked) ...<Widget>[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(
                            Icons.monetization_on_rounded,
                            color: Color(0xFFFFC86E),
                            size: 15,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$price',
                            style: const TextStyle(
                              color: Color(0xFFFFD98B),
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.block.withValues(alpha: 0.38),
                  ),
                  child: Icon(Icons.check_rounded, color: theme.blockAccent),
                )
              else if (unlocked)
                const Icon(Icons.chevron_right_rounded, color: Colors.white30),
            ],
          ),
        ),
      ),
    );
  }
}
