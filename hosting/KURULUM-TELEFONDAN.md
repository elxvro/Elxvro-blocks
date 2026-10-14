# ELXVRO Blocks v0.28.3 — telefondan kurulum

Bu paket canlı sunucuya kurulmuş değildir. Dağıtılan uygulamada satın alma
kapalıdır. Mevcut config.php ve veritabanı korunacak şekilde hazırlanmıştır.

1. Hosting panelinde dosya yöneticisini ve phpMyAdmin'i aç. Mevcut veritabanını
   ve private/config.php dosyasını özel bir konuma yedekle.
2. UPLOAD_TO_BLOCK_SUBDOMAIN içeriğini block.elxvro.com belge köküne yükle.
   Pakette config.php yoktur; mevcut dosyanı silme veya değiştirme.
3. Mevcut veritabanına SQL/schema.sql, ardından SQL/v0283.sql dosyasını içe aktar.
   Bunlar eksik tabloları ekler; mevcut tabloları silmez.
4. private/deployment.example.php dosyasını private/deployment.php olarak kopyala.
   token_encryption_key için sunucuda base64_encode(random_bytes(32)) ile bir
   anahtar üret. Mevcut HMAC anahtarını ve yeni anahtarı özel olarak yedekle.
   Gizli anahtarları sohbete, GitHub'a veya dağıtılan ZIP'e ekleme.
5. Mevcut Google web istemci kimliği, paket adı, veritabanı ve servis hesabı
   bilgilerini koru. Servis hesabına Play satın alma okuma ve sipariş yönetimi
   yetkileri gerekir.
6. Hosting'in zamanlanmış görevler bölümünde private/reconcile.php dosyasını
   PHP CLI ile her dakika çalıştır. Web adresinden çalıştırılamaz. Görev beş
   dakikadan uzun süredir başarılı çalışmadıysa satın alma ve harcama engellenir.
7. HTTPS'i ve private klasörünün dışarıdan erişime kapalı olduğunu kontrol et.
   Apache'de .htaccess desteği; Nginx'te eşdeğer erişim yasağı gerekir.
8. Test ortamında billing_mode=test ve payments_enabled=true kullanılır;
   live_security_approved=false kalır. Bu mod gerçek ödemeleri reddeder.
   Dağıtılan APK ayrıca ELXVRO_BILLING_ENABLED=false ile derlenmiştir.
   Ödeme denemesi için yalnızca lisans test hesaplarına dağıtılacak, bu bayrağı
   açılmış ayrı test derlemesi gerekir. Üretim satışını açma.

## Cüzdan davranışı

Satın alınan coinler, ücretli envanter ve rozet Google hesabına bağlı sunucu
kaydından geri yüklenir. Çevrimdışı kazanılan coinler ve ilerleme cihazda kalır.
Yerel coinler yeterliyse önce onlar kullanılır; yetersizse tüm bedel sunucu
cüzdanından alınır. İki bakiye birleştirilmez. Ücretli envanter internet gerektirir.

İadelerde kalan coin geri alınır. Harcanmış tutar borç olur; borç kapanana kadar
ücretli harcama ve envanter engellenir. İade takibi anlık değildir; Google'ın
veriyi sunması ve cron görevinin çalışması gerekir.

## Canlı ortamda henüz yapılmayan kontroller

- Google OAuth ve servis hesabı doğrulaması.
- Üç coin paketi ve rozet için lisans test ödemeleri; bekleyen/reddedilen ödeme.
- İki cihaz, yeniden kurulum, iade ve bağlantı kesilmesi senaryoları.
- Cron'un durması/yeniden başlaması ve yük altında yeterli hızda çalışması.
- Yedekli veritabanı geçişi ve özel dosyaların HTTP erişimine kapatılması.

API ve yapılandırma ayrıntıları README.md içindedir. Kontroller tamamlanmadan
ve açık onay verilmeden gerçek para testi veya üretim yayını yapılmamalıdır.
