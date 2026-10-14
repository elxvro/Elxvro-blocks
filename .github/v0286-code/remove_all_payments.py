#!/usr/bin/env python3
"""v0.28.6: completely remove real-money purchasing from the Flutter app."""
from pathlib import Path
import re

def change(name, pairs):
    p = Path(name)
    s = p.read_text()
    for old, new in pairs:
        assert old in s, f'Unrecognized source in {name}: {old[:60]}'
        s = s.replace(old, new)
    p.write_text(s)

change('lib/main.dart', [
    ("import 'services/play_billing_service.dart';\n", ''),
    ("import 'services/billing_account_service.dart';\n", ''),
    ("      unawaited(appState.load().then(\n        (_) => PlayBillingService.instance.initialize(appState),\n      ));", "      unawaited(appState.load());"),
    ("    unawaited(BillingAccountService.instance.refreshWallet());\n", '')
])
change('lib/screens/store_screen.dart', [
    ("import '../widgets/coin_purchase_panel.dart';\n", ''),
    ("                        CoinPurchasePanel(appState: appState),\n                        const SizedBox(height: 8),\n", ''),
    ("AppStrings.current.f('Oyun içi coinler satın alınabilir veya oynayarak kazanılabilir. Satın almalar Google Play üzerinden doğrulanır.', 'Coins can be earned or purchased. Paid orders are verified through Google Play.')",
     "AppStrings.current.f('Coinler yalnızca oynayarak kazanılır. Gerçek para ile satın alma bulunmaz.', 'Coins are earned only by playing. No real-money purchases.')")
])
p = Path('lib/app_state.dart')
s = p.read_text()
for old in [
    "import 'services/billing_account_service.dart';\n",
    "  static const String _supporterKey = 'play_supporter_badge_v1';\n",
    "  bool get isSupporter => BillingAccountService.instance.serverSupporter;\n  set isSupporter(bool value) { /* legacy preferences are not proof of payment */ }\n  bool _walletListenerAttached = false;\n",
    "    if (!_walletListenerAttached) {\n      BillingAccountService.instance.addListener(_walletChanged);\n      _walletListenerAttached = true;\n    }\n",
    "      isSupporter = prefs.getBool(_supporterKey) ?? false;\n",
    "    if (_walletListenerAttached) BillingAccountService.instance.removeListener(_walletChanged);\n"
]:
    assert old in s, old[:70]
    s = s.replace(old, '')
s, n = re.subn(r'  void _walletChanged\(\) \{\n.*?\n  \}\n', '', s, count=1, flags=re.S)
assert n == 1
s, n = re.subn(r'  /// Only invoke after a trusted Google Play Developer API verification\.\n  /// Processed purchase tokens are persisted so repeated Play callbacks cannot\n  /// award the same item a second time on this installation\.\n  Future<bool> grantVerifiedPlayProduct\(\{.*?\n  \}\n\n', '', s, count=1, flags=re.S)
assert n == 1
assert 'BillingAccountService' not in s and 'isSupporter' not in s
p.write_text(s)
for name in [
    'lib/widgets/coin_purchase_panel.dart',
    'lib/services/play_billing_service.dart',
    'lib/services/billing_account_service.dart',
    'lib/services/wallet_snapshot.dart',
    'test/v0270_billing_contract_test.dart',
    'test/v0281_billing_release_gate_test.dart',
    'test/v0282_server_wallet_preview_test.dart',
    'test/v0283_wallet_test.dart'
]:
    Path(name).unlink()
change('pubspec.yaml', [
    ('  in_app_purchase: ^3.3.1\n', ''),
    ('  in_app_purchase_android: ^0.5.0\n', ''),
    ('  http: ^1.6.0\n', ''),
    ('  google_sign_in: ^6.3.0\n', ''),
    ('  crypto: ^3.0.6\n', ''),
    ('version: 0.28.5+59', 'version: 0.28.6+60')
])
for name in ['test/real_material_audio_test.dart', 'test/v0240_features_test.dart']:
    change(name, [('version: 0.28.5+59', 'version: 0.28.6+60')])
Path('test/v0286_no_payments_test.dart').write_text("""import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no Play purchases, login or supporter code ships', () {
    final spec = File('pubspec.yaml').readAsStringSync();
    expect(spec, contains('version: 0.28.6+60'));
    for (final key in <String>['in_app_purchase:', 'google_sign_in:', 'http:', 'crypto:']) {
      expect(spec, isNot(contains(key)));
    }
    for (final name in <String>[
      'lib/services/play_billing_service.dart',
      'lib/services/billing_account_service.dart',
      'lib/widgets/coin_purchase_panel.dart',
    ]) {
      expect(File(name).existsSync(), isFalse);
    }
  });
  test('earned coins and ordinary coin-power store survive', () {
    final game = File('lib/app_state.dart').readAsStringSync();
    final store = File('lib/screens/store_screen.dart').readAsStringSync();
    expect(game, contains('Future<bool> buyUndoPack()'));
    expect(store, contains('Coinler yalnızca oynayarak kazanılır'));
    expect(store, isNot(contains('CoinPurchasePanel')));
  });
}
""")
for file in list(Path('lib').rglob('*.dart')):
    code = file.read_text()
    for forbidden in ('BillingAccountService', 'PlayBillingService', 'CoinPurchasePanel', 'google_sign_in', 'in_app_purchase', 'grantVerifiedPlayProduct'):
        assert forbidden not in code, f'{file}: {forbidden}'
print('v0.28.6: payment and supporter implementation removed, earned coins retained.')
