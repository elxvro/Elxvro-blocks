#!/usr/bin/env python3
"""ELXVRO Blocks v0.28.6: disable and remove all supporter purchase UI.
This migration deliberately preserves earned coins and Play Games sign-in.
"""
from pathlib import Path
root=Path('.')
p=root/'lib/widgets/coin_purchase_panel.dart'
assert p.exists(), 'Purchase panel missing'
p.write_text("""import 'package:flutter/material.dart';
import '../app_state.dart';

/// Legacy placement retained for compatibility; no storefront or purchases.
class CoinPurchasePanel extends StatelessWidget {
  const CoinPurchasePanel({super.key, required this.appState});
  final AppState appState;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
""")
# Prevent accidental use of the old billing implementation, even from other
# application entry points. A separate audit is required before deleting all
# account/billing files and dependencies.
billing=root/'lib/services/play_billing_service.dart'
if billing.exists():
    source=billing.read_text()
    source=source.replace("PlayProduct('elxvro_supporter_badge', 0, true),", "")
    billing.write_text(source)
pub=root/'pubspec.yaml'
assert 'version: 0.28.5+59' in pub.read_text()
pub.write_text(pub.read_text().replace('version: 0.28.5+59','version: 0.28.6+60'))
for t in ['test/real_material_audio_test.dart','test/v0240_features_test.dart']:
    q=root/t
    if q.exists(): q.write_text(q.read_text().replace('version: 0.28.5+59','version: 0.28.6+60'))
# Billing tests asserting a paid product are obsolete.
for t in ['test/v0270_billing_contract_test.dart','test/v0281_billing_release_gate_test.dart']:
    q=root/t
    if q.exists(): q.unlink()
print('Removed purchase panel and product catalog; remaining integration audit required.')
