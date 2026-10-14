#!/usr/bin/env python3
"""v0.28.4 supporter-only migration, applied to restored v0.28.3 Flutter source."""
from pathlib import Path
import re

def modify(path, fn):
    p=Path(path)
    before=p.read_text()
    after=fn(before)
    p.write_text(after)

def billing(s):
    start=s.index('  static const packs = <PlayProduct>[')
    end=s.index('  ];',start)+5
    s=s[:start]+"""  static const packs = <PlayProduct>[
    PlayProduct('elxvro_supporter_badge', 0, true),
  ];"""+s[end:]
    s=s.replace('return BillingAccountService.instance.checkoutEnabled &&', 'return BillingAccountService.instance.checkoutEnabled &&')
    # Only non-consumable checkout is reachable: the catalog has one supporter SKU.
    return s

modify('lib/services/play_billing_service.dart',billing)

Path('lib/widgets/coin_purchase_panel.dart').write_text("""import 'dart:async';
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../services/play_billing_service.dart';

/// Supporter-only Play Billing entry point. No paid coin store.
class CoinPurchasePanel extends StatelessWidget {
  const CoinPurchasePanel({super.key, required this.appState});
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final billing = PlayBillingService.instance;
    final isTr = appState.languageCode == 'tr';
    final product = PlayProduct.packs.single;
    return AnimatedBuilder(animation: billing, builder: (context, _) {
      final details = billing.productFor(product.id);
      final owned = appState.isSupporter;
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Icon(Icons.favorite_rounded, color: Color(0xFFFFC86E), size: 36),
        const SizedBox(height: 8),
        Text(isTr ? 'GELİŞTİRİCİYİ DESTEKLE' : 'SUPPORT THE DEVELOPER',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFFFD99A), fontWeight: FontWeight.w900, fontSize: 16)),
        const SizedBox(height: 8),
        Text(isTr ? 'İsteğe bağlı, tek seferlik destek. Oyun avantajı sağlamaz.'
                  : 'Optional one-time support. No gameplay benefits.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: billing.canBuy && details != null && !owned
            ? () => unawaited(billing.buy(product.id)) : null,
          icon: const Icon(Icons.workspace_premium_rounded),
          label: Text(owned
            ? (isTr ? 'DESTEKÇİ ROZETİN ETKİN' : 'SUPPORTER BADGE ACTIVE')
            : (details?.price ?? (isTr ? 'ÖDEME KULLANILAMIYOR' : 'PURCHASE UNAVAILABLE'))),
        ),
        if (billing.message != null)
          Text(billing.message!, textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        TextButton.icon(
          onPressed: billing.available && !billing.pending
            ? () => unawaited(billing.restore()) : null,
          icon: const Icon(Icons.restore_rounded, size: 17),
          label: Text(isTr ? 'Satın alımı geri yükle' : 'Restore purchase'),
        ),
      ]);
    });
  }
}
""")

def app(s):
    changes={
      "int get totalUndoInventory => undoInventory + BillingAccountService.instance.inventory('undo');":"int get totalUndoInventory => undoInventory;",
      "int get totalRefreshInventory => refreshInventory + BillingAccountService.instance.inventory('refresh');":"int get totalRefreshInventory => refreshInventory;",
      "int get totalSpecialInventory => specialInventory + BillingAccountService.instance.inventory('special');":"int get totalSpecialInventory => specialInventory;",
      "if (_unlockedThemes.contains(id) || BillingAccountService.instance.ownsTheme(id)) return true;":"if (_unlockedThemes.contains(id)) return true;",
      "final ok = await BillingAccountService.instance.transact('buy', 'theme:$id');\n      if (ok) await setTheme(id);\n      return ok;":"return false;",
      "final sku = undo == 5 ? 'power_bundle' : undo > 0 ? 'undo_3' : refresh > 0 ? 'refresh_3' : 'special_3';\n      return BillingAccountService.instance.transact('buy', sku);":"return false;",
      "if (undoInventory <= 0) return BillingAccountService.instance.transact('use', 'undo');":"if (undoInventory <= 0) return false;",
      "if (refreshInventory <= 0) return BillingAccountService.instance.transact('use', 'refresh');":"if (refreshInventory <= 0) return false;",
      "if (specialInventory <= 0) return BillingAccountService.instance.transact('use', 'special');":"if (specialInventory <= 0) return false;",
    }
    for a,b in changes.items():
        if a not in s: raise SystemExit('Missing app contract: '+a)
        s=s.replace(a,b)
    return s

modify('lib/app_state.dart',app)
modify('pubspec.yaml', lambda s: s.replace('version: 0.28.3+57','version: 0.28.4+58'))
for path in ['test/real_material_audio_test.dart','test/v0240_features_test.dart']:
    modify(path, lambda s:s.replace('version: 0.28.3+57','version: 0.28.4+58'))
# Contract tests must reflect removed paid products while retaining signed-in verification.
p=Path('test/v0283_wallet_test.dart')
if p.exists():
    p.write_text(p.read_text())
print('v0.28.4 supporter-only migration applied')
