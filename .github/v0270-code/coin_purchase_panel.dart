import 'dart:async';
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../services/play_billing_service.dart';

/// The same gold/navy storefront as the existing gameplay economy.
class CoinPurchasePanel extends StatelessWidget {
  const CoinPurchasePanel({super.key, required this.appState});
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final billing = PlayBillingService.instance;
    final isTr = appState.languageCode == 'tr';
    return AnimatedBuilder(animation: billing, builder: (context, _) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
        _heading(Icons.toll_rounded, isTr ? 'COIN SATIN AL' : 'BUY COINS',
            isTr ? 'Google Play ile güvenli ödeme' : 'Secure Google Play checkout'),
        const SizedBox(height: 12),
        for (final product in PlayProduct.packs.where((p) => !p.isSupporter)) ...<Widget>[
          _tile(
            product: product,
            title: product.coins.toString() + ' COIN',
            subtitle: isTr ? 'Güçler ve temalar için' : 'For power-ups and themes',
            icon: Icons.monetization_on_rounded,
          ),
          const SizedBox(height: 9),
        ],
        const SizedBox(height: 16),
        _heading(Icons.favorite_rounded,
            isTr ? 'GELİŞTİRİCİYİ DESTEKLE' : 'SUPPORT THE DEVELOPER',
            isTr ? 'İsteğe bağlı, tek seferlik destek'
                : 'Optional one-time support'),
        const SizedBox(height: 12),
        _tile(
          product: PlayProduct.packs.last,
          title: isTr ? 'DESTEKÇİ PAKETİ' : 'SUPPORTER PACK',
          subtitle: appState.isSupporter
              ? (isTr ? 'Destekçi rozetin etkin' : 'Supporter badge active')
              : (isTr ? 'Kalıcı teşekkür rozeti; oyun avantajı sağlamaz'
                      : 'Permanent thank-you badge; no gameplay advantage'),
          icon: Icons.workspace_premium_rounded,
        ),
        const SizedBox(height: 12),
        if (billing.message != null)
          Text(billing.message!, textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        if (!billing.serverConfigured)
          Text(isTr
                ? 'Ödeme doğrulama sunucusu ve Play ürünleri açılana kadar satın alma devre dışıdır.'
                : 'Purchases are disabled until server verification and Play products are active.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
        TextButton.icon(
          onPressed: billing.available && !billing.pending
              ? () => unawaited(billing.restore()) : null,
          icon: const Icon(Icons.restore_rounded, size: 17),
          label: Text(isTr ? 'Satın alımları geri yükle' : 'Restore purchases'),
        ),
        const Divider(color: Colors.white12, height: 32),
      ]);
    });
  }

  Widget _heading(IconData icon, String title, String subtitle) {
    return Row(children: <Widget>[
      Icon(icon, color: const Color(0xFFFFC86E), size: 22),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: const TextStyle(color: Color(0xFFFFD99A),
              fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1)),
          Text(subtitle, style: const TextStyle(
              color: Colors.white60, fontSize: 11)),
        ],
      )),
    ]);
  }

  Widget _tile({required PlayProduct product, required String title,
      required String subtitle, required IconData icon}) {
    final billing = PlayBillingService.instance;
    final details = billing.productFor(product.id);
    final owned = product.isSupporter && appState.isSupporter;
    final canTap = billing.canBuy && details != null && !owned;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(18),
        color: const Color(0xFFFFC86E).withValues(alpha: .06),
        border: Border.all(color: const Color(0xFFFFC86E).withValues(alpha: .19))),
      child: Row(children: <Widget>[
        CircleAvatar(backgroundColor: const Color(0xFF3A2E23),
            child: Icon(icon, color: const Color(0xFFFFD78F))),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: const TextStyle(color: Colors.white,
                fontWeight: FontWeight.w800, fontSize: 14)),
            Text(subtitle, style: const TextStyle(
                color: Colors.white60, fontSize: 10)),
          ],
        )),
        const SizedBox(width: 6),
        FilledButton(
          onPressed: canTap ? () => unawaited(billing.buy(product.id)) : null,
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFC98B42),
              padding: const EdgeInsets.symmetric(horizontal: 12)),
          child: Text(owned ? '✓' : (details?.price ?? '—'),
              style: const TextStyle(fontSize: 12)),
        ),
      ]),
    );
  }
}
