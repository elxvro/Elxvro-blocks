<?php
declare(strict_types=1);
require __DIR__.'/../UPLOAD_TO_BLOCK_SUBDOMAIN/private/Billing.php';
require __DIR__.'/../UPLOAD_TO_BLOCK_SUBDOMAIN/private/Wallet.php';
function ok(bool $value,string $message): void {if(!$value)throw new RuntimeException($message);}
function rejects(callable $fn,string $code): void {try{$fn();}catch(BillingException $e){ok($e->getMessage()===$code,'wrong rejection');return;}throw new RuntimeException('expected '.$code);}
$db=null;
for($attempt=0;$attempt<30;$attempt++){
    try{$db=new PDO(getenv('TEST_DSN'),getenv('TEST_DB_USER'),getenv('TEST_DB_PASSWORD'),[PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION,PDO::ATTR_DEFAULT_FETCH_MODE=>PDO::FETCH_ASSOC]);break;}
    catch(PDOException $e){if($attempt===29)throw $e;usleep(1000000);}
}

$db->exec(file_get_contents(__DIR__.'/../SQL/schema.sql'));
$db->exec(file_get_contents(__DIR__.'/../SQL/v0283.sql'));
$config=['purchase_token_hmac_secret'=>str_repeat('a',64),'token_encryption_key'=>base64_encode(str_repeat('b',32))];
$w=new Wallet($db,$config);$sub='12345678901234567890';
foreach(['elxvro_coins_500','elxvro_coins_1500','elxvro_coins_4000'] as $id) rejects(fn()=>Products::get($id),'unknown_product');
$w->grant($sub,'elxvro_supporter_badge','badge-token','GPA.badge');
ok($w->snapshot($sub)['supporter']===true,'supporter granted');
ok($w->snapshot($sub)['balance']===0,'no paid coins');
$w->grant($sub,'elxvro_supporter_badge','badge-token','GPA.badge');
ok($w->snapshot($sub)['supporter']===true,'idempotent badge');
rejects(fn()=>$w->grant('11111111111111111111','elxvro_supporter_badge','badge-token','GPA.badge'),'purchase_owner_mismatch');
rejects(fn()=>$w->grant($sub,'elxvro_supporter_badge','other-token','GPA.badge'),'order_already_used');
$receipt=$db->query("SELECT token_hmac,encrypted_token FROM billing_receipts WHERE order_id='GPA.badge'")->fetch();
ok($w->decrypt($receipt['encrypted_token'],$receipt['token_hmac'])==='badge-token','encrypted token');
$w->markFinalized('badge-token');
ok((int)$db->query("SELECT finalized FROM billing_receipts WHERE order_id='GPA.badge'")->fetchColumn()===1,'ack finalization durable');
ok((new Wallet($db,$config))->snapshot($sub)['supporter'],'new device restores badge');
$w->revoke('badge-token');$w->revoke('badge-token');
ok(!$w->snapshot($sub)['supporter'],'refund revokes supporter');
rejects(fn()=>$w->grant($sub,'elxvro_supporter_badge','badge-token','GPA.badge'),'purchase_revoked');
ok($w->snapshot($sub)['balance']===0,'refund does not alter earned coins');
echo "PASS supporter-only: catalog, grant, duplicate, account isolation, order replay, encryption, refund\n";

$w->grant($sub,'elxvro_supporter_badge','replacement-badge-token','GPA.replacement');
ok($w->snapshot($sub)['supporter'],'repurchase after refund');
$w->revoke('badge-token');ok($w->snapshot($sub)['supporter'],'old refund cannot revoke replacement');
echo "PASS: durable acknowledgement, device restore, repurchase after refund\n";
