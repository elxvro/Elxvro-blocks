<?php
declare(strict_types=1);
// Cron CLI only. Never expose an unauthenticated HTTP worker endpoint.
if(PHP_SAPI!=='cli'){http_response_code(404);exit;}
require __DIR__.'/v0283.php';
$c=billing_config();$db=api_db($c);$w=new Wallet($db,$c);$g=new GoogleApi($c);
if(!$db->query("SELECT GET_LOCK('elxvro_billing_reconcile',0)")->fetchColumn())exit(0);
try{
 // Overlapping 30-day full pagination catches refunds on consumed purchases.
 $page=null;do{$data=$g->voided($page);foreach($data['voidedPurchases']??[] as $v){if(is_string($v['purchaseToken']??null))$w->revoke($v['purchaseToken']);}$page=$data['tokenPagination']['nextPageToken']??null;}while($page);
 $rows=$db->query('SELECT p.*,r.encrypted_token FROM play_purchases p JOIN billing_receipts r USING(token_hmac) WHERE r.revoked=0 AND r.encrypted_token<>\'\' ORDER BY r.checked_at ASC LIMIT 200')->fetchAll();
 foreach($rows as $r){
  $token=$w->decrypt($r['encrypted_token'],$r['token_hmac']);$p=$g->playPurchase($token);
  if(($p['purchaseStateContext']['purchaseState']??null)==='CANCELLED'||($p['productLineItem'][0]['productOfferDetails']['refundableQuantity']??null)===0){$w->revoke($token);continue;}
  PurchaseRules::verify($p,$r['product_id'],$r['google_sub']);
  $support=Products::get($r['product_id'])['supporter'];
  $finished=$support?($p['acknowledgementState']??'')==='ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED':($p['productLineItem'][0]['productOfferDetails']['consumptionState']??'')==='CONSUMPTION_STATE_CONSUMED';
  if(!$finished)$g->finishPurchase($r['product_id'],$token,$support);
  $s=$db->prepare('UPDATE billing_receipts SET finalized=1,checked_at=CURRENT_TIMESTAMP WHERE token_hmac=?');$s->execute([$r['token_hmac']]);
 }
 $db->exec('UPDATE billing_worker_state SET last_success='.time().' WHERE id=1');echo "Reconciliation OK\n";
}catch(Throwable $e){fwrite(STDERR,'Reconciliation failed: '.get_class($e)."\n");exit(1);}
finally{$db->query("SELECT RELEASE_LOCK('elxvro_billing_reconcile')");}
