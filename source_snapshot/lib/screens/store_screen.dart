import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n/app_strings.dart';
import '../models/game_theme.dart';
import '../services/audio_service.dart';
import '../widgets/coin_badge.dart';
import '../widgets/premium_background.dart';

class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
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
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 18, 10),
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
                                AppStrings.current.f('MAĞAZA','STORE'),
                                style: TextStyle(
                                  color: Color(0xFFFFD99A),
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2.1,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                AppStrings.current.f('Coinlerini güçlere dönüştür','Turn coins into power ups'),
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        CoinBadge(coins: appState.coins),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                      children: <Widget>[
                        _InventoryPanel(appState: appState),
                        const SizedBox(height: 14),
                        _StoreCard(
                          icon: Icons.undo_rounded,
                          title: AppStrings.current.f('Geri Al Paketi','Undo Pack'),
                          subtitle: AppStrings.current.f('3 ekstra geri al hakkı','3 extra undo uses'),
                          price: 120,
                          onBuy: appState.buyUndoPack,
                        ),
                        const SizedBox(height: 10),
                        _StoreCard(
                          icon: Icons.autorenew_rounded,
                          title: AppStrings.current.f('Yenile Paketi','Refresh Pack'),
                          subtitle: AppStrings.current.f('3 ekstra blok yenileme hakkı','3 extra piece refreshes'),
                          price: 120,
                          onBuy: appState.buyRefreshPack,
                        ),
                        const SizedBox(height: 10),
                        _StoreCard(
                          icon: Icons.auto_awesome_rounded,
                          title: AppStrings.current.f('Özel Blok Paketi','Special Block Pack'),
                          subtitle: AppStrings.current.f('3 kez anında özel blok üret','Create special blocks 3 times'),
                          price: 180,
                          onBuy: appState.buySpecialPack,
                        ),
                        const SizedBox(height: 10),
                        _StoreCard(
                          icon: Icons.workspace_premium_rounded,
                          title: 'Power Bundle',
                          subtitle: AppStrings.current.f('5 geri al + 5 yenile + 2 özel blok','5 undo + 5 refresh + 2 special blocks'),
                          price: 300,
                          highlighted: true,
                          onBuy: appState.buyPowerBundle,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          AppStrings.current.f('Coinler yalnızca oyun içi ilerleme ile kazanılır. Bu sürümde gerçek para ile satın alma yoktur.','Coins are earned only through gameplay. No real money purchases in this version.'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.32),
                            fontSize: 10,
                            height: 1.4,
                          ),
                        ),
                      ],
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

class _InventoryPanel extends StatelessWidget {
  const _InventoryPanel({required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withValues(alpha: 0.045),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          _Stock(icon: Icons.undo_rounded, label: AppStrings.current.f('GERİ AL','UNDO'), value: appState.undoInventory),
          _Stock(icon: Icons.autorenew_rounded, label: AppStrings.current.f('YENİLE','REFRESH'), value: appState.refreshInventory),
          _Stock(icon: Icons.auto_awesome_rounded, label: AppStrings.current.f('ÖZEL','SPECIAL'), value: appState.specialInventory),
        ],
      ),
    );
  }
}

class _Stock extends StatelessWidget {
  const _Stock({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Icon(icon, color: const Color(0xFFFFC86E), size: 24),
        const SizedBox(height: 5),
        Text(
          '$value',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 8,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _StoreCard extends StatelessWidget {
  const _StoreCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.onBuy,
    this.highlighted = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final int price;
  final Future<bool> Function() onBuy;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: highlighted
            ? const Color(0xFFFFC86E).withValues(alpha: 0.075)
            : Colors.white.withValues(alpha: 0.04),
        border: Border.all(
          color: highlighted
              ? const Color(0xFFFFC86E).withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFC86E).withValues(alpha: 0.10),
            ),
            child: Icon(icon, color: const Color(0xFFFFC86E)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: () async {
              final bought = await onBuy();
              if (!context.mounted) return;
              if (bought) {
                unawaited(AudioService.instance.playReward());
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    bought
                        ? AppStrings.current.f('Satın alındı.','Purchased.')
                        : AppStrings.current.f('Yeterli coin yok.','Not enough coins.'),
                  ),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC98B42),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.monetization_on_rounded, size: 16),
                const SizedBox(width: 4),
                Text('$price'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
