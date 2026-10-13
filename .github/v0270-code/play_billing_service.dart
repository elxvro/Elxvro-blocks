import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../app_state.dart';

class PlayProduct {
  const PlayProduct(this.id, this.coins, this.isSupporter);
  final String id;
  final int coins;
  final bool isSupporter;
  static const packs = <PlayProduct>[
    PlayProduct('elxvro_coins_500', 500, false),
    PlayProduct('elxvro_coins_1500', 1500, false),
    PlayProduct('elxvro_coins_4000', 4000, false),
    PlayProduct('elxvro_supporter_badge', 0, true),
  ];
  static PlayProduct? byId(String id) {
    for (final p in packs) {
      if (p.id == id) return p;
    }
    return null;
  }
}

/// No user will be charged unless the trusted purchase-verification endpoint
/// has been configured. Store price comes from Google Play, never hardcoded.
class PlayBillingService extends ChangeNotifier {
  PlayBillingService._();
  static final PlayBillingService instance = PlayBillingService._();
  static const verificationUrl =
      String.fromEnvironment('ELXVRO_BILLING_VERIFY_URL');

  final InAppPurchase _store = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _stream;
  AppState? _app;
  Map<String, ProductDetails> _products = <String, ProductDetails>{};
  bool _initialized = false;
  bool loading = false;
  bool available = false;
  bool pending = false;
  String? message;

  bool get serverConfigured => verificationUrl.startsWith('https://') &&
      (Uri.tryParse(verificationUrl)?.host.isNotEmpty ?? false);
  bool get canBuy => available && serverConfigured && !pending;

  ProductDetails? productFor(String id) => _products[id];

  Future<void> initialize(AppState app) async {
    _app = app;
    if (_initialized) return;
    _initialized = true;
    loading = true;
    notifyListeners();
    _stream = _store.purchaseStream.listen(
      (updates) => unawaited(_handlePurchases(updates)),
      onError: (Object error) {
        pending = false;
        message = 'Google Play bağlantısı kesildi.';
        notifyListeners();
      },
    );
    try {
      available = await _store.isAvailable();
      if (available) {
        final response = await _store.queryProductDetails(
            PlayProduct.packs.map((p) => p.id).toSet());
        _products = {for (final p in response.productDetails) p.id: p};
        if (response.error != null) {
          message = 'Ürün bilgileri alınamadı.';
        } else if (_products.isEmpty) {
          message = 'Ürünler Play Console üzerinde henüz etkin değil.';
        }
      } else {
        message = 'Google Play ödeme hizmeti kullanılamıyor.';
      }
      if (!serverConfigured) {
        message = 'Ödeme doğrulama sunucusu henüz bağlanmadı.';
      }
    } catch (_) {
      message = 'Google Play ürünleri yüklenemedi.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> buy(String id) async {
    final product = PlayProduct.byId(id);
    final details = productFor(id);
    if (!canBuy || product == null || details == null) return;
    pending = true;
    message = null;
    notifyListeners();
    try {
      final param = PurchaseParam(productDetails: details);
      final started = product.isSupporter
          ? await _store.buyNonConsumable(purchaseParam: param)
          : await _store.buyConsumable(
              purchaseParam: param, autoConsume: false);
      if (!started) {
        pending = false;
        message = 'Ödeme başlatılamadı.';
        notifyListeners();
      }
    } catch (_) {
      pending = false;
      message = 'Google Play ödeme ekranı açılamadı.';
      notifyListeners();
    }
  }

  Future<void> restore() => _store.restorePurchases();

  @override
  void dispose() {
    unawaited(_stream?.cancel());
    super.dispose();
  }


  Future<void> _handlePurchases(List<PurchaseDetails> items) async {
    for (final item in items) {
      if (item.status == PurchaseStatus.pending) {
        pending = true;
        message = 'Google Play ödemenin tamamlanmasını bekliyor.';
      } else if (item.status == PurchaseStatus.error) {
        pending = false;
        message = item.error?.message ?? 'Ödeme başarısız.';
      } else if (item.status == PurchaseStatus.canceled) {
        pending = false;
        message = 'Satın alma iptal edildi.';
      } else if (item.status == PurchaseStatus.purchased ||
          item.status == PurchaseStatus.restored) {
        await _deliver(item);
      }
      notifyListeners();
    }
  }

  Future<void> _deliver(PurchaseDetails item) async {
    final product = PlayProduct.byId(item.productID);
    final app = _app;
    if (product == null || app == null || !serverConfigured) return;
    final token = item.verificationData.serverVerificationData;
    if (token.isEmpty) {
      pending = false;
      message = 'Google Play satın alma kimliği eksik.';
      return;
    }
    try {
      // A "purchased" flag on the phone does NOT verify payment.
      final response = await http.post(
        Uri.parse(verificationUrl),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(<String, String>{
          'platform': 'google_play',
          'productId': product.id,
          'purchaseToken': token,
        }),
      ).timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) throw const FormatException();
      final data = jsonDecode(response.body);
      if (data is! Map ||
          data['verified'] != true ||
          data['productId'] != product.id) {
        throw const FormatException('unverified');
      }
      await app.grantVerifiedPlayProduct(
        token: token,
        coinsToAdd: product.coins,
        supporter: product.isSupporter,
      );
      if (product.isSupporter) {
        if (item.pendingCompletePurchase) {
          await _store.completePurchase(item);
        }
        message = 'Destekçi rozeti açıldı. Teşekkürler!';
      } else {
        final android = _store
            .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
        await android.consumePurchase(item);
        message = '+' + product.coins.toString() + ' coin eklendi.';
      }
    } catch (_) {
      message = 'Ödeme doğrulanamadı. Hak tanımlanmadı; tekrar dene.';
    } finally {
      pending = false;
      notifyListeners();
    }
  }
}
