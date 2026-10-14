from pathlib import Path
root=Path('.')
def replace(path,old,new):
 p=root/path
 s=p.read_text()
 assert old in s, f'{path}: missing anchor {old[:55]}'
 p.write_text(s.replace(old,new,1))

replace('pubspec.yaml','version: 0.28.6+60','version: 0.28.7+61')
replace('pubspec.yaml','  shared_preferences: ^2.5.3','  shared_preferences: ^2.5.3\n  in_app_purchase: ^3.2.3')
replace('lib/screens/settings_screen.dart',"import '../services/audio_service.dart';","import '../services/audio_service.dart';\nimport '../widgets/developer_support_card.dart';")
replace('lib/screens/settings_screen.dart',"                        const SizedBox(height: 22),\n                        Container(","                        const SizedBox(height: 12),\n                        const DeveloperSupportCard(),\n                        const SizedBox(height: 22),\n                        Container(")
replace('lib/screens/settings_screen.dart',"'v0.28.2  •  ", "'v0.28.7  •  ")
for t in ['test/real_material_audio_test.dart','test/v0240_features_test.dart']:
 replace(t,'version: 0.28.6+60','version: 0.28.7+61')
(root/'test/v0286_no_payments_test.dart').unlink()
(root/'test/v0287_support_test.dart').write_text("""import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
 test('single nonconsumable support product and no subscription or server', () {
  final billing=File('lib/services/developer_support_service.dart').readAsStringSync();
  expect(billing,contains('elxvro_supporter_badge'));
  expect(billing,contains('buyNonConsumable'));
  expect(billing,contains('restorePurchases'));
  expect(billing,isNot(contains('http')));
  expect(billing,isNot(contains('buyConsumable(')));
  final pubspec=File('pubspec.yaml').readAsStringSync();
  expect(pubspec,contains('version: 0.28.7+61'));
  expect(pubspec,contains('in_app_purchase:'));
  expect(pubspec,isNot(contains('google_sign_in:')));
 });
 test('support appears in settings and earned coins are unchanged', () {
  expect(File('lib/screens/settings_screen.dart').readAsStringSync(),contains('DeveloperSupportCard'));
  expect(File('lib/app_state.dart').readAsStringSync(),contains('Future<bool> buyUndoPack()'));
 });
}
""")
(root/'lib/services/developer_support_service.dart').write_text("""import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Optional, one-time Google Play support. No account, backend or in-game perks.
class DeveloperSupportService extends ChangeNotifier {
  DeveloperSupportService._();
  static final DeveloperSupportService instance = DeveloperSupportService._();

  static const productId = 'elxvro_supporter_badge';
  final InAppPurchase _store = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  ProductDetails? product;
  bool available = false;
  bool busy = false;
  bool supported = false;
  bool initialized = false;
  String? error;

  Future<void> initialize() async {
    if (initialized) return;
    initialized = true;
    _subscription = _store.purchaseStream.listen(
      (items) => unawaited(_handlePurchases(items)),
      onError: (Object _) {
        busy = false;
        error = 'Google Play bağlantısı kurulamadı.';
        notifyListeners();
      },
    );
    try {
      available = await _store.isAvailable();
      if (available) {
        final response = await _store.queryProductDetails({productId});
        if (response.productDetails.isNotEmpty) {
          product = response.productDetails.first;
        }
        if (response.error != null) error = response.error!.message;
      }
    } catch (_) {
      error = 'Google Play ürün bilgisi alınamadı.';
    }
    notifyListeners();
  }

  Future<void> buy() async {
    if (busy || supported || product == null || !available) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      final started = await _store.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product!),
      );
      if (!started) {
        busy = false;
        error = 'Satın alma başlatılamadı.';
      }
    } catch (_) {
      busy = false;
      error = 'Satın alma başlatılamadı.';
    }
    notifyListeners();
  }

  Future<void> restore() async {
    if (busy || !available) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await _store.restorePurchases();
    } catch (_) {
      error = 'Satın alma geri yüklenemedi.';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != productId) continue;
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // Client-side Play callback only: no financial entitlement or gameplay reward.
          supported = true;
          busy = false;
          break;
        case PurchaseStatus.error:
          busy = false;
          error = purchase.error?.message ?? 'Satın alma tamamlanamadı.';
          break;
        case PurchaseStatus.canceled:
          busy = false;
          break;
        case PurchaseStatus.pending:
          busy = true;
          break;
      }
      if (purchase.pendingCompletePurchase &&
          (purchase.status == PurchaseStatus.purchased ||
           purchase.status == PurchaseStatus.restored)) {
        try {
          await _store.completePurchase(purchase);
        } catch (_) {
          error = 'Google Play işlemi tamamlanamadı. Satın alımı geri yükleyin.';
        }
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
""")
(root/'lib/widgets/developer_support_card.dart').write_text("""import 'dart:async';

import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../services/developer_support_service.dart';

class DeveloperSupportCard extends StatefulWidget {
  const DeveloperSupportCard({super.key});

  @override
  State<DeveloperSupportCard> createState() => _DeveloperSupportCardState();
}

class _DeveloperSupportCardState extends State<DeveloperSupportCard> {
  final service = DeveloperSupportService.instance;

  @override
  void initState() {
    super.initState();
    unawaited(service.initialize());
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: service,
      builder: (context, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFD98B).withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.favorite_rounded, color: Color(0xFFFFD98B), size: 30),
            const SizedBox(height: 8),
            Text(
              AppStrings.current.f('GELİŞTİRİCİYİ DESTEKLE', 'SUPPORT THE DEVELOPER'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFFFD98B), fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              AppStrings.current.f(
                'Tamamen isteğe bağlı, tek seferlik destek. Abonelik değildir. Oyun avantajı sağlamaz.',
                'Optional one-time support. Not a subscription. No gameplay advantages.',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            if (service.supported)
              Text(AppStrings.current.f('Desteğin için teşekkürler!', 'Thank you for your support!'),
                textAlign: TextAlign.center, style: const TextStyle(color: Colors.white))
            else
              FilledButton.icon(
                onPressed: service.busy || service.product == null ? null : () => unawaited(service.buy()),
                icon: const Icon(Icons.favorite_outline),
                label: Text(service.busy
                  ? AppStrings.current.f('İşlem sürüyor...', 'Processing...')
                  : AppStrings.current.f('Tek seferlik destek', 'Support once') +
                    (service.product == null ? '' : ' • ${service.product!.price}')),
              ),
            TextButton(
              onPressed: service.busy || !service.available ? null : () => unawaited(service.restore()),
              child: Text(AppStrings.current.f('Satın alımı geri yükle', 'Restore purchase')),
            ),
            if (service.error != null)
              Text(service.error!, textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.orangeAccent)),
          ],
        ),
      ),
    );
  }
}
""")
print('Applied one-time optional support with no custom server.')
