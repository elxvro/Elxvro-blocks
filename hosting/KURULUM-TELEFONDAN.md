# ELXVRO Blocks — block.elxvro.com ödeme doğrulama sunucusu

**Durum:** Güvenli *hazırlık paketi* (staging). Henüz block.elxvro.com adresine yüklenmedi. Gerçek ödeme kapalıdır. 

Bu proje ELXVRO Blocks v0.28.1 (Android paket kimliği: `com.elxvro.elxvro_blocks`) için hazırlanmıştır.
Sunucu adresi: `https://block.elxvro.com/verify_purchase.php`.

## 1) cPanel'de alt alan adını oluştur

- cPanel → **Domains / Alan Adları** → `block.elxvro.com` adresini oluştur.
- DNS doğru yönlendirilmeli ve **HTTPS / AutoSSL** etkin olmalı. Adres zaten varsa yeniden oluşturma.
- Alan adının **Document Root / Kök dizin** yolunu not et. Bu dizin `public_html/block` veya panelin ayarladığı başka bir klasör olabilir.
- PHP **8.1 veya üzeri** sürümünü ve `curl`, `openssl`, `pdo_mysql` eklentilerini seç.

## 2) Dosyaları yükle

- `ELXVRO-Blocks-block.elxvro.com-HOSTING.zip` dosyasını alt alan adının **belge kök dizinine** yükle.
- **Extract / Ayıkla** yap. `index.php`, `health.php`, `verify_purchase.php`, `wallet.php`, `private/` doğrudan alt alan adının kökünde görünmeli.
- `private/.htaccess` dosyasının gerçekten bulunduğunu kontrol et. Özel dosyalar HTTP üzerinden ASLA erişilebilir olmamalı. Apache veya LiteSpeed üzerinde `.htaccess` koruması doğrulanmalı; farklı sunucu kullanılıyorsa koruma ona göre yapılandırılmalı.
- `https://block.elxvro.com/health.php` adresini aç. İlk yüklemede `setup_required` görünmesi **normal**dir.

## 3) MySQL veritabanını oluştur

- cPanel → **MySQL Databases** → yeni bir veritabanı ve kullanıcı oluştur.
- Kullanıcıyı bu veritabanına ata; gerekli tablo oluşturma ve DML izinlerini ver.
- cPanel → **phpMyAdmin** → o veritabanını seç → **İçe Aktar / Import** → `schema.sql` dosyasını yükle.
- `player_wallets` ve `play_purchases` tablolarının oluştuğunu kontrol et.

## 4) Google Cloud servis hesabını yetkilendir

- Google Cloud Console'da mevcut Play Console hesabına bağlı bir proje kullan.
- **Google Play Android Developer API** (Android Publisher API) hizmetini etkinleştir.
- Google Play Console API erişimi ayarlarından ilgili hizmet hesabına, yalnızca ödeme/sipariş işlemlerinin doğrulanması için gereken yetkileri tanımla.
- Hizmet hesabının JSON anahtar dosyasını **Google Cloud'dan** indir.
- Bu dosyayı sadece alt alan adının `private/google-play-service-account.json` yoluna yükle. Google Play'e bağlı servis hesabının JSON dosyasını GitHub'a, sohbet ekranına, uygulamaya veya herkese açık dizine **ASLA** koyma.
- JSON özel anahtarı değiştirilebilen/iptal edilebilen bir sırdır. Gereksiz geniş erişim vermemek gerekir.

## 5) Google kullanıcı kimliğini doğrulamaya hazırla

- Google Cloud'dan oyuna ait **Web OAuth Client ID** değerini edin (sonu `.apps.googleusercontent.com` olur).
- Bu OAuth istemcisinin oyuncunun mobil Google ile giriş akışında sunucu için ID token üretecek şekilde kullanılması gerekir.
- DİKKAT: Mevcut v0.28.1 uygulaması henüz sunucuya `Authorization: Bearer <Google ID token>` göndermiyor. Bu durum düzeltilmeden ödeme açılmamalı.
- Yeni satın alma akışında Google Play Billing'e, oturum açmış Google `sub` kimliğine bağlı `obfuscatedAccountId = sha256('elxvro.blocks|' + googleSub)` değeri set edilmelidir.
- **Play Games hesabına giriş yapmak, tek başına sunucunun beklediği Google OAuth ID tokenının otomatik gönderildiği anlamına gelmez.** Uygulama tarafı buna göre geliştirilecektir.

## 6) Özel ayar dosyası

- `private/config.example.php` dosyasını kopyalayıp **`private/config.php`** olarak kaydet.
- `db_dsn`, `db_user`, `db_password`, `google_oauth_audience`, `service_account_json`, `purchase_token_hmac_secret` alanlarını doldur.
- HMAC sırrı, rastgele oluşturulmuş en az 32 karakter (tercihen 64 karakterlik hex) olmalı ve sonradan değiştirilmemelidir.
- **`payments_enabled => false` değerini değiştirme!** Bu sunucu paketi otomatik olarak ödeme açmaz.
- cPanel dosya yöneticisinde config.php dosyasının dosya izinlerini uygun biçimde kısıtla (genellikle 600/640, hosting yapılandırmasına göre).

## 7) GitHub Actions bağlantısı (henüz uygulamayı ödeme almaya açmaz)

ELXVRO Blocks GitHub deposu → Settings → Secrets and variables → Actions → Variables:

`ELXVRO_BILLING_VERIFY_URL = https://block.elxvro.com/verify_purchase.php`

Mevcut `work-v0.28.1` derleme akışında **varsayılan checkout kapalıdır**.
Sadece URL eklemek gerçek ödemeleri açmaz; Android uygulamasının sunucuya Google ID token yollayacak şekilde geliştirilmesi ve test edilmesi gerekir.

## Sunucunun erişim sözleşmesi

**GET** `/health.php` — gizli bilgi vermeyen servis durumu.

**GET** `/wallet.php`
Header: `Authorization: Bearer GOOGLE_ID_TOKEN`
Yanıt: `{"balance":1500,"supporter":false,"source":"verified_purchases"}` (örnek)

**POST** `/verify_purchase.php`
Headers: `Content-Type: application/json`, `Authorization: Bearer GOOGLE_ID_TOKEN`
Gövde:

```json
{"platform":"google_play","productId":"elxvro_coins_500","purchaseToken":"GERCEK_GOOGLE_PLAY_TOKEN"}
```

Yalnızca doğru hesaba bağlı, Google Play tarafından **PURCHASED** olduğu doğrulanmış, tam olarak tek ürünlü, iade edilmemiş satın alımlarda sunucu coinleri **bir kez** hesaba ekler.

```json
{"verified":true,"productId":"elxvro_coins_500","alreadyGranted":false,"awardedCoins":500,"balance":500,"supporter":false}
```

Tekrar edilen bir token `alreadyGranted:true`, `awardedCoins:0` sonucu üretir ve bakiyeye tekrar eklenmez. Aynı token başka hesapta tekrar kullanılamaz.

## Ürün kimlikleri

| Ürün | Ürün ID | Türkiye fiyatı |
|---|---|---|
| 500 Coin | `elxvro_coins_500` | ₺9,99 |
| 1500 Coin | `elxvro_coins_1500` | ₺24,99 |
| 4000 Coin | `elxvro_coins_4000` | ₺49,99 |
| Destekçi Paketi | `elxvro_supporter_badge` | ₺19,99 |

Bu fiyatlar sunucudan değil **Google Play Console** üzerinden yönetilir.

## Yayınlamadan ÖNCE zorunlu kalan işler

1. Uygulamada oturum açmış oyuncudan sunucu için **Google ID token** edinme ve API'ye aktarma.
2. Billing satın alımlarında **obfuscatedAccountId** gönderme ve destekçi geri yüklemeyi doğru hesapla ilişkilendirme.
3. Sunucudan gelen `balance` / `alreadyGranted` alanlarına göre oyun cüzdanını senkronize etme; mevcut APK'nın yerel `SharedPreferences` coin bakiyesine güvenip tekrar coin eklemeyi bırakma.
4. Mevcut oyunda oynayarak kazanılan coinlerle satın alınan coinlerin birlikte tutarlı biçimde nasıl saklanacağını belirleme. Şimdiki örnek sunucu **yalnızca doğrulanmış satın alım coinlerini** kaydeder.
5. Sipariş tüketimi/onayı için güvenli ve tekrar deneyen sunucu işlemleri; uygulamanın bağlantı kesintilerinde 3 günlük onay süresini kaçırmaması.
6. Google Play Voided Purchases API / RTDN ile **iptal ve iade takibi**, geri alma ve mutabakat.
7. Sunucu erişim sınırları, saldırı önleme, SQL yedekleri, uygulama entegrasyon testleri.
8. Google Play lisans testi hesabıyla, ücret çekmeden test satın alımları; üretim ödemelerini ancak sahibinin onayıyla aç.

Bu dosyalar güvenlik kilidi açık olan üretim sunucusu değildir; **staging kurulum paketidir**. Gerçek ödemeler aktif edilemez.

## Gerekli teknik doğrulama

- `private/config.php`, `.json` ve `private/Billing.php` dosyaları doğrudan web tarayıcısıyla okunamamalı (403/404).
- HTTPS sertifikası geçerli olmalı.
- Yapılandırma sonrası `health.php` → `configured_staging` (ödeme hâlâ kapalı).
- Test için `php tests/test_rules.php` yerel olarak çalıştırıldığında güvenlik kontrolleri geçmelidir.
