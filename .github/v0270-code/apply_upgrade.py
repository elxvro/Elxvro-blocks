from pathlib import Path
import sys

root = Path(sys.argv[1])
overlays = Path(__file__).resolve().parent

def patch(name, old, new):
    file = root / name
    text = file.read_text(encoding='utf-8')
    if text.count(old) != 1:
        raise RuntimeError('Patch anchor mismatch: ' + name + ' count=' + str(text.count(old)))
    file.write_text(text.replace(old, new, 1), encoding='utf-8')

patch('pubspec.yaml', 'version: 0.26.2+52', 'version: 0.27.0+53')
patch('pubspec.yaml', '  share_plus: 10.1.4',
      '  share_plus: 10.1.4\n  in_app_purchase: ^3.3.1\n'
      '  in_app_purchase_android: ^0.5.0\n  http: ^1.6.0')
patch('pubspec.yaml', '  min_sdk_android: 23', '  min_sdk_android: 24')
patch('test/real_material_audio_test.dart',
      'version: 0.26.2+52', 'version: 0.27.0+53')
patch('test/v0240_features_test.dart',
      'version: 0.26.2+52', 'version: 0.27.0+53')
patch('lib/screens/home_screen.dart',
      "badge: 'v0.26.2'", "badge: 'v0.27.0'")
patch('lib/screens/settings_screen.dart',
      "'v0.26.2  •  ", "'v0.27.0  •  ")

patch('lib/app_state.dart',
      "  static const String _coinsKey = 'coins';",
      "  static const String _coinsKey = 'coins';\n"
      "  static const String _iapTokensKey = 'play_purchase_tokens_v1';\n"
      "  static const String _supporterKey = 'play_supporter_badge_v1';")
patch('lib/app_state.dart', '  int coins = 0;',
      '  int coins = 0;\n  bool isSupporter = false;')
patch('lib/app_state.dart', '      coins = prefs.getInt(_coinsKey) ?? 0;',
      '      coins = prefs.getInt(_coinsKey) ?? 0;\n'
      '      isSupporter = prefs.getBool(_supporterKey) ?? false;')
needle = '  Future<bool> buyUndoPack() => _purchase('
method = """  /// Only invoke after a trusted Google Play Developer API verification.
  /// Processed purchase tokens are persisted so repeated Play callbacks cannot
  /// award the same item a second time on this installation.
  Future<bool> grantVerifiedPlayProduct({
    required String token,
    required int coinsToAdd,
    required bool supporter,
  }) async {
    if (token.isEmpty || coinsToAdd < 0 || coinsToAdd > 4000) return false;
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_iapTokensKey) ?? <String>[];
    if (existing.contains(token)) return false;
    if (!await prefs.setStringList(_iapTokensKey, <String>[...existing, token])) {
      throw StateError('Unable to record verified purchase token');
    }
    if (supporter) {
      isSupporter = true;
      await prefs.setBool(_supporterKey, true);
    } else {
      coins = (coins + coinsToAdd).clamp(0, 2147483647).toInt();
      await prefs.setInt(_coinsKey, coins);
    }
    notifyListeners();
    return true;
  }

"""
patch('lib/app_state.dart', needle, method + needle)
patch('lib/main.dart', "import 'services/audio_service.dart';",
      "import 'services/audio_service.dart';\n"
      "import 'services/play_billing_service.dart';")
patch('lib/main.dart',
      '      unawaited(appState.load());',
      '      unawaited(appState.load().then(\n'
      '        (_) => PlayBillingService.instance.initialize(appState),\n'
      '      ));')
patch('lib/screens/store_screen.dart',
      "import '../widgets/coin_badge.dart';",
      "import '../widgets/coin_badge.dart';\n"
      "import '../widgets/coin_purchase_panel.dart';")
patch('lib/screens/store_screen.dart',
      """                        _InventoryPanel(appState: appState),
                        const SizedBox(height: 14),""",
      """                        _InventoryPanel(appState: appState),
                        const SizedBox(height: 18),
                        CoinPurchasePanel(appState: appState),
                        const SizedBox(height: 8),""")
patch('lib/screens/store_screen.dart',
      "AppStrings.current.f('Coinler yalnızca oyun içi ilerleme ile kazanılır. Bu sürümde gerçek para ile satın alma yoktur.','Coins are earned only through gameplay. No real money purchases in this version.')",
      "AppStrings.current.f('Oyun içi coinler satın alınabilir veya oynayarak kazanılabilir. Satın almalar Google Play üzerinden doğrulanır.', 'Coins can be earned or purchased. Paid orders are verified through Google Play.')")

for name in ('play_billing_service.dart', 'coin_purchase_panel.dart'):
    target = 'lib/services/' + name if name.startswith('play_') else 'lib/widgets/' + name
    (root / target).write_text((overlays / name).read_text(encoding='utf-8'),
                               encoding='utf-8')

(root / 'test/v0270_billing_contract_test.dart').write_text("""import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:elxvro_blocks/services/play_billing_service.dart';

void main() {
  test('coin products and supporter are distinct one-time Play products', () {
    expect(PlayProduct.packs.length, 4);
    expect(PlayProduct.packs.map((p) => p.id).toSet().length, 4);
    expect(PlayProduct.packs.where((p) => !p.isSupporter)
        .map((p) => p.coins), <int>[500, 1500, 4000]);
    expect(PlayProduct.packs.last.isSupporter, isTrue);
  });
  test('no charge without a trusted verification server', () {
    final src = File('lib/services/play_billing_service.dart').readAsStringSync();
    expect(src, contains("if (!canBuy || product == null"));
    expect(src, contains("data['verified'] != true"));
    expect(src, contains('consumePurchase(item)'));
  });
}
""", encoding='utf-8')

(root / 'V0270_BILLING_SETUP.md').write_text("""ELXVRO Blocks v0.27.0 - Google Play Billing Setup

Four one-time Google Play products (create under Monetize / Products):
  elxvro_coins_500        Consumable - 500 coins
  elxvro_coins_1500       Consumable - 1500 coins
  elxvro_coins_4000       Consumable - 4000 coins
  elxvro_supporter_badge  Non-consumable - permanent cosmetic badge

Prices and local currencies come exclusively from Google Play.
The Supporter Pack is a digital cosmetic item, NOT a charitable donation.
The player's existing earned coins and game progress are unchanged.

IMPORTANT: Charging is intentionally disabled without a configured HTTPS
server-side purchase verifier. Build with:
  --dart-define=ELXVRO_BILLING_VERIFY_URL=https://YOUR_HOST/verify_purchase.php

The verifier MUST use Google Play Developer API (not trust client flags),
validate package name, product ID, purchase token, PURCHASED status,
and reject duplicate consumable purchase tokens. Use a secure server-side
ledger and Google Play service-account credentials. Never embed credentials
in the APK or GitHub repository. Configure merchant account, product prices,
billing API, license testers, and test track in Play Console first.

Note: local SharedPreferences coins do not sync between devices; a server-side
wallet and authenticated account are necessary before a public paid launch.
""", encoding='utf-8')
print('v0.27.0 four billing products, UI and purchase-flow safety gates added')
