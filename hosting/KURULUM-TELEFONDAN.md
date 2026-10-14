# ELXVRO Blocks v0.28.5 — destekçi rozeti

Tek ürün: `elxvro_supporter_badge`. Tek seferlik, tüketilmeyen dijital rozet.
Ücretli coin satışı ve sunucu coin harcaması kapalıdır. Oyunda kazanılan coinler
ve yerel oyun özellikleri bu güncellemeyle değiştirilmez.

## Mevcut kurulumu koruyarak güncelleme

1. Mevcut veritabanını ve private/config.php dosyasını özel olarak yedekle.
2. UPLOAD_TO_BLOCK_SUBDOMAIN içeriğini mevcut API dizinine yükle. Pakette canlı
   config.php, deployment.php veya servis hesabı anahtarı bulunmaz. Bunları silme.
3. Eksik tablolar varsa SQL/schema.sql ve SQL/v0283.sql dosyalarını sırayla uygula.
   CREATE TABLE IF NOT EXISTS kullanılır; mevcut veriler silinmez.
4. Mevcut private/deployment.php içine örnek dosyadaki eksik alanları ekle.
   HMAC ve şifreleme anahtarlarını değiştirme. Yeni kurulumda token_encryption_key
   base64_encode(random_bytes(32)) ile sunucuda üretilmelidir.
5. Hizmet hesabı JSON dosyasını tercihen web kökünün dışında tut; mevcut
   service_account_json ayarına özel mutlak dosya yolunu yaz. JSON'u GitHub'a,
   uygulamaya, ZIP'e veya sohbete koyma. private klasörüne HTTP erişimini engelle.
6. PHP CLI ile `private/check_setup.php` çalıştır. `--google` seçeneği OAuth ve
   satın alma API erişimini salt okunur kontrol eder; satın alma oluşturmaz.
7. `private/reconcile.php` her dakika PHP CLI cron ile çalışmalıdır. Terminal
   erişimi yoksa hosting panelinin zamanlanmış görevler bölümünü kullan.
   Beş dakika içinde başarılı senkronizasyon yoksa rozet doğrulaması ve ödeme
   kapısı kapanır. Eski coin ürünleri doğrulama kuyruğunu artık durdurmaz.

## Google Cloud ve Play izinleri

Doğru proje, oyunun Google OAuth istemci kimliği ve mevcut servis hesabının
project_id alanıyla doğrulanmalıdır; benzer ada bakarak proje seçilmemelidir.
`androidpublisher.googleapis.com` etkin olmalıdır. Hizmet hesabına Cloud Owner
veya Editor vermek gerekmez. Play Console Kullanıcılar ve izinler bölümünde
yalnızca ELXVRO Blocks uygulaması için satın alma API'sinin gerektirdiği
“Finansal verileri, siparişleri ve iptal anketi yanıtlarını görüntüleme” ve
“Siparişleri ve abonelikleri yönetme” izinlerini değerlendirin. Diğer uygulamalar,
üretim yayını, kullanıcı yönetimi ve yönetici erişimi verilmemelidir.
Hesap oluşturma/anahtar çıkarma ve izin atama kullanıcı onayı gerektirir.
Kaynak: https://developers.google.com/android-publisher/getting_started

## Önce lisans testi

- Play lisans test kullanıcısını ve dahili test dağıtımını Console'da doğrula.
- deployment.php: payments_enabled=true, billing_mode=test,
  live_security_approved=false. license_test_subjects içine yalnızca doğrulanmış
  test Google hesaplarının subject değerlerini ekle; e-posta adresi değildir.
  Bu değerler hesap girişinden sonra player_wallets.google_sub kaydında bulunur.
- Hem oyunda hem Play Store'da doğru test hesabını kullan. Satın alma ekranında
  Google'ın test ödeme aracını görmeden işlemi tamamlama.
- Dağıtılan v0.28.5 APK/AAB, ELXVRO_BILLING_ENABLED=false ile derlenir.
  Canlı bağlantı ve lisans test hesabı hazırlandıktan sonra yalnızca test kanalına
  dağıtılacak ayrı ödeme etkin derleme gerekir. Bu teslimat satış açmaz.
- Başarılı/reddedilen/bekleyen ödeme, yinelenen callback, oturum değişikliği,
  yeniden kurulum, aynı hesapla ikinci cihaz, iade ve cron kesintisini dene.
- Test modu yalnızca Google API'nin TEST olarak işaretlediği ödemeleri kabul eder.
  Bu sunucu kontrolü, yanlış Play hesabındaki ödeme ekranının gerçek para istemesini
  önleyemez; bu yüzden lisans test hesabının doğrulanması zorunludur.
- Üretim ancak test kanıtı ve açık kullanıcı onayı sonrasında açılır.

## API

Tüm hesap işlemleri Authorization: Bearer <Google ID token> kullanır.
GET /wallet.php: protocol, source, supporter, revision, checkoutEnabled, billingMode
ve eski istemciler için bakiye alanları. Uygulama yalnızca rozet durumunu kullanır.
POST /verify_purchase.php:
{"platform":"google_play","productId":"elxvro_supporter_badge","purchaseToken":"..."}
Başarılı yanıt: verified:true, productId ve güncel hesap durumu.
Google API satın alımı ve hesaba bağlanan obfuscatedExternalAccountId doğrulanır.
Kalıcı kayıt önce yazılır; ardından satın alma acknowledge edilir, consume edilmez.
Ack hatasında kayıt korunur ve cron/geri yükleme aynı tokenı yeniden işler.
Tekrar token başka hesaba taşınamaz; iade edilen token yeniden rozet veremez.
POST /spend.php her zaman 410 paid_coin_wallet_retired döndürür.
GET /verify_purchase.php için method_not_allowed normaldir; bu uç POST bekler.

## Yapılandırma ve teslimat sınırı

API varsayılanı https://block.elxvro.com; doğrulama URL'si
https://block.elxvro.com/verify_purchase.php. Google web OAuth istemcisi sunucunun
izin verdiği audience ile aynı olmalıdır. Android OAuth için paket adı
com.elxvro.elxvro_blocks ve Play imzalama sertifikası eşleşmelidir.
Mevcut imzalama anahtarları ve v0.28.4 workflow değiştirilmez; yeni sürüm aynı
adımlarla ayrı work-v0.28.5-supporter dalında derlenir. Sürüm 0.28.5+59.

Bu paket canlı kurulumun veya Google lisans ödemesinin başarılı olduğuna dair
kanıt değildir. Cloud/Play/hosting erişimi olmadan bunlar doğrulanamaz. İade
tespiti Google verisinin görünürlüğü ve cron aralığına bağlıdır; anlık değildir.
