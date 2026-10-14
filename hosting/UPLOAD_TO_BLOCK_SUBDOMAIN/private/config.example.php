<?php
// cPanel dosya yöneticisinde config.php olarak kopyala. Bu dosyayı paylaşma.
// Service account JSON'u Google Cloud'dan indir ve sadece private/ içine koy.
return [
    'db_dsn' => 'mysql:host=localhost;dbname=CPANELUSER_elxvroblocks;charset=utf8mb4',
    'db_user' => 'CPANELUSER_blocks',
    'db_password' => 'REPLACE_WITH_MYSQL_PASSWORD',
    'google_oauth_audience' => 'REPLACE_WITH_WEB_OAUTH_CLIENT_ID.apps.googleusercontent.com',
    'android_package' => 'com.elxvro.elxvro_blocks',
    'service_account_json' => __DIR__ . '/google-play-service-account.json',
    'purchase_token_hmac_secret' => 'REPLACE_WITH_AT_LEAST_64_RANDOM_HEX_CHARACTERS',
    // DOKUNMA: OAuth, backend refund reconciliation, and app wallet syncing
    // tamamlanmadan TRUE yapma. İşin başında false olarak kalmalı.
    'payments_enabled' => false,
];
