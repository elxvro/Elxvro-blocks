from pathlib import Path
import sys

app=Path(sys.argv[1])

def patch(relative,old,new):
    f=app/relative
    s=f.read_text(encoding='utf-8')
    n=s.count(old)
    if n != 1:
        raise RuntimeError(f'v0.28.1 upgrade: {relative} anchor count {n} ({old[:75]})')
    f.write_text(s.replace(old,new,1),encoding='utf-8')

patch('pubspec.yaml','version: 0.28.0+54','version: 0.28.1+55')
for f in ('test/real_material_audio_test.dart','test/v0240_features_test.dart'):
    patch(f,'version: 0.28.0+54','version: 0.28.1+55')
patch('lib/screens/home_screen.dart',"badge: 'v0.28.0'","badge: 'v0.28.1'")
patch('lib/screens/settings_screen.dart',"'v0.28.0  •  ","'v0.28.1  •  ")

billing='lib/services/play_billing_service.dart'
patch(billing,
"""  static const verificationUrl =
      String.fromEnvironment('ELXVRO_BILLING_VERIFY_URL');""",
"""  static const verificationUrl =
      String.fromEnvironment('ELXVRO_BILLING_VERIFY_URL');
  // Even a configured endpoint cannot initiate payments until the owner
  // explicitly authorizes checkout in a new signed Play test build.
  static const bool checkoutApproved =
      bool.fromEnvironment('ELXVRO_BILLING_ENABLED', defaultValue: false);""")
patch(billing,
    '  bool get canBuy => available && serverConfigured && !pending;',
    '  bool get canBuy => available && serverConfigured && checkoutApproved && !pending;')
patch(billing,
"""      if (!serverConfigured) {
        message = 'Ödeme doğrulama sunucusu henüz bağlanmadı.';
      }""",
"""      if (!serverConfigured) {
        message = 'Ödeme doğrulama sunucusu henüz bağlanmadı.';
      } else if (!checkoutApproved) {
        message = 'Coin ürünleri hazırlanıyor. Test satın alımları henüz açık değil.';
      }""")

(app/'test/v0281_billing_release_gate_test.dart').write_text(
"""import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:elxvro_blocks/services/play_billing_service.dart';

void main() {
  test('the default signed build refuses to open real payment checkout', () {
    expect(PlayBillingService.checkoutApproved, isFalse);
    expect(PlayBillingService.instance.canBuy, isFalse);
    expect(PlayBillingService.instance.serverConfigured, isFalse);
  });

  test('no checkout without explicit enable flag AND trusted verifier URL', () {
    final source = File('lib/services/play_billing_service.dart').readAsStringSync();
    expect(source, contains("bool.fromEnvironment('ELXVRO_BILLING_ENABLED'"));
    expect(source, contains('available && serverConfigured && checkoutApproved && !pending'));
    expect(source, contains('ELXVRO_BILLING_VERIFY_URL'));
    expect(source, contains("data['verified'] != true"));
  });

  test('same four stable IDs are shared with Google Play Console', () {
    expect(PlayProduct.packs.map((p) => p.id).toList(), <String>[
      'elxvro_coins_500',
      'elxvro_coins_1500',
      'elxvro_coins_4000',
      'elxvro_supporter_badge',
    ]);
  });
}
""", encoding='utf-8')

(app/'V0281_PLAY_BILLING_HANDOFF.md').write_text("""ELXVRO Blocks v0.28.1 - WORK + GOOGLE PLAY BILLING HANDOFF

This is the staging build for preparing payments in parallel.
The default build has checkout OFF. It must not charge any player.

PLAY CONSOLE / TURKEY BASE PRICES (subject to Google's allowed minimums):
  elxvro_coins_500        : TRY 9.99   consumable / one-time product
  elxvro_coins_1500       : TRY 24.99  consumable / one-time product
  elxvro_coins_4000       : TRY 49.99  consumable / one-time product
  elxvro_supporter_badge  : TRY 19.99  non-consumable cosmetic badge
Product IDs must be identical to the app, and prices are managed in Play
Console. Localized prices come from Google Play Billing queryProductDetails.

REQUIRED SECURE SERVER (WORK TASK, NOT YET CONFIGURED):
POST https://YOUR-DOMAIN/verify_purchase
Content-Type: application/json
  {"platform":"google_play",
   "productId":"elxvro_coins_500",
   "purchaseToken":"<Google Play purchase token>"}

On success, server may reply HTTP 200:
  {"verified":true,"productId":"elxvro_coins_500"}

CRITICAL SERVER RESPONSIBILITIES:
- Authenticate the player and maintain a server-authoritative player/wallet ID.
- Use Google Play Developer API, not a client-side "purchased" claim.
- Validate Android package name, product ID, state PURCHASED, token ownership,
  not cancelled/refunded, transaction type and user binding.
- Prevent duplicate grants globally with a durable UNIQUE purchase-token ledger.
- Make grants and idempotency atomic in a database transaction.
- Avoid replaying consumables across accounts or app reinstall.
- Implement a durable wallet with reliable recovery across devices.
- Handle delayed payment, restoration, cancellations/refunds, reconciliation.
- Server-side service-account credentials must remain outside the APK/repo.
- Client presently writes coins and badge locally after verification: production
  must also implement authenticated wallet synchronization. This staging
  architecture alone is NOT production-monetization safe.
- The endpoint URL must not contain embedded credentials or tokens.
- Do not activate live checkout without owner's explicit authorization.

GITHUB ACTIONS BUILD-TIME VARIABLES:
  vars.ELXVRO_BILLING_VERIFY_URL = https://YOUR-DOMAIN/verify_purchase
  No enabled variable: regular push builds ALWAYS keep paid checkout OFF.
ONLY after license-tester payments, security and wallet integration pass:
  Manually dispatch build-v0.28.1.yml, choose enable_paid_checkout=true
  after the owner explicitly approves. Default is false.
Both the APK and AAB embed the same build settings.
Without a URL and enabled=true, buy buttons remain disabled.

Use Google Play license testers and a closed/internal testing track.
Real transactions should not be enabled until Play Console settings and
server-side verification are ready and the owner expressly approves.
""",encoding='utf-8')
print('v0.28.1 prepared: signed-staging checkout off by default; Work handoff added')
