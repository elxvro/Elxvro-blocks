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
# Strictly disable the legacy billing service at its public entry points.
# No SKU can be queried or bought; any call returns without initiating payment.
source=billing.read_text()
source=source.replace('bool get canBuy => available && serverConfigured && checkoutApproved &&','bool get canBuy => false && available && serverConfigured && checkoutApproved &&')
source=source.replace("bool.fromEnvironment('ELXVRO_BILLING_ENABLED', defaultValue: false)","false")
billing.write_text(source)
# Remove visible supporter ownership and any need to refresh its server wallet.
state=root/'lib/app_state.dart'
if state.exists():
    st=state.read_text()
    st=st.replace('bool get isSupporter => BillingAccountService.instance.serverSupporter;', 'bool get isSupporter => false;')
    st=st.replace('BillingAccountService.instance.addListener(_walletChanged);', '// Paid account listener removed.')
    st=st.replace('BillingAccountService.instance.removeListener(_walletChanged);', '// Paid account listener removed.')
    state.write_text(st)
main=root/'lib/main.dart'
if main.exists():
    m=main.read_text()
    m=m.replace('unawaited(BillingAccountService.instance.refreshWallet());','// Paid wallet sync removed.')
    main.write_text(m)
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
print('Payment storefront removed; purchases forcibly disabled, product catalog empty.')
