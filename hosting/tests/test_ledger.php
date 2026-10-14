<?php
declare(strict_types=1);
require __DIR__.'/../UPLOAD_TO_BLOCK_SUBDOMAIN/private/Billing.php';
require __DIR__.'/../UPLOAD_TO_BLOCK_SUBDOMAIN/private/Wallet.php';
function ok(bool $v,string $m): void {if(!$v) throw new RuntimeException($m);}
function rejects(callable $f,string $code): void {try{$f();}catch(BillingException $e){ok($e->getMessage()===$code,'wrong error '.$e->getMessage());return;}throw new RuntimeException('expected '.$code);}
$db=new PDO(getenv('TEST_DSN'),getenv('TEST_DB_USER'),getenv('TEST_DB_PASSWORD'),[PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION,PDO::ATTR_DEFAULT_FETCH_MODE=>PDO::FETCH_ASSOC]);
$db->exec(file_get_contents(__DIR__.'/../SQL/schema.sql'));
$db->exec(file_get_contents(__DIR__.'/../SQL/v0283.sql'));
$config=['purchase_token_hmac_secret'=>str_repeat('a',64),'token_encryption_key'=>base64_encode(str_repeat('b',32))];
$w=new Wallet($db,$config);$sub='12345678901234567890';
foreach([500,1500,4000] as $n){$w->grant($sub,'elxvro_coins_'.$n,'test-token-'.$n,'GPA.'.$n);}
ok($w->snapshot($sub)['balance']===6000,'all packs');
$w->grant($sub,'elxvro_coins_500','test-token-500','GPA.500');
ok($w->snapshot($sub)['balance']===6000,'duplicate token');
rejects(fn()=>$w->grant('11111111111111111111','elxvro_coins_500','test-token-500','GPA.500'),'purchase_owner_mismatch');
rejects(fn()=>$w->grant($sub,'elxvro_coins_500','other-token','GPA.500'),'order_already_used');
$op='01234567-89ab-4cde-8fab-012345678901';
$w->spend($sub,'undo_3',$op);$w->spend($sub,'undo_3',$op);
ok($w->snapshot($sub)['balance']===5880,'idempotent spend');
ok($w->snapshot($sub)['inventory']['undo']===3,'durable inventory');
rejects(fn()=>$w->spend($sub,'refresh_3',$op),'operation_conflict');
$w->useItem($sub,'undo','01234567-89ab-4cde-8fab-012345678902');
$w->useItem($sub,'undo','01234567-89ab-4cde-8fab-012345678902');
ok($w->snapshot($sub)['inventory']['undo']===2,'idempotent use');
$w->grant($sub,'elxvro_supporter_badge','badge-token','GPA.badge');
ok((new Wallet($db,$config))->snapshot($sub)['supporter']===true,'device restore badge');
$w->revoke('test-token-4000');$w->revoke('test-token-4000');
ok($w->snapshot($sub)['balance']===1880,'idempotent refund');
$w->revoke('test-token-1500');$w->revoke('test-token-500');
ok($w->snapshot($sub)['balance']===0 && $w->snapshot($sub)['debt']===120,'refund after spend creates debt');
rejects(fn()=>$w->spend($sub,'undo_3','01234567-89ab-4cde-8fab-012345678903'),'wallet_debt');
$w->revoke('badge-token');ok(!$w->snapshot($sub)['supporter'],'refunded badge removed');
rejects(fn()=>$w->grant($sub,'elxvro_coins_500','test-token-500','GPA.500'),'purchase_revoked');
echo "PASS ledger: packs, token/order replay, account isolation, spend/use retry, restore, refund/debt/badge\n";
