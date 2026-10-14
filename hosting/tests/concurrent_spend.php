<?php
declare(strict_types=1);
require __DIR__.'/../UPLOAD_TO_BLOCK_SUBDOMAIN/private/Billing.php';
require __DIR__.'/../UPLOAD_TO_BLOCK_SUBDOMAIN/private/Wallet.php';
$db=new PDO(getenv('TEST_DSN'),getenv('TEST_DB_USER'),getenv('TEST_DB_PASSWORD'),[PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION,PDO::ATTR_DEFAULT_FETCH_MODE=>PDO::FETCH_ASSOC]);
$w=new Wallet($db,['purchase_token_hmac_secret'=>str_repeat('a',64),'token_encryption_key'=>base64_encode(str_repeat('b',32))]);
try{$w->spend('22222222222222222222','power_bundle',$argv[1]);echo 'OK';}catch(BillingException $e){if($e->getMessage()!=='insufficient_balance')throw $e;echo 'REFUSED';}
