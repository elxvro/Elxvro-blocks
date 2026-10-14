<?php
declare(strict_types=1);
require __DIR__.'/private/v0283.php';
try{
 $data=api_start();$c=billing_config();$sub=api_auth_subject($c);$db=api_db($c);
 $id=$data['productId']??null;$token=$data['purchaseToken']??null;
 if(($data['platform']??null)!=='google_play'||!is_string($id)||!is_string($token)||strlen($token)<16||strlen($token)>4096)throw new BillingException(400,'invalid_purchase_request');
 Products::get($id);$google=new GoogleApi($c);$purchase=$google->playPurchase($token);$w=new Wallet($db,$c);
 $refundable=$purchase['productLineItem'][0]['productOfferDetails']['refundableQuantity']??null;
 if(($purchase['purchaseStateContext']['purchaseState']??null)==='CANCELLED'||$refundable===0){$w->revoke($token);throw new BillingException(409,'purchase_revoked');}
 PurchaseRules::verify($purchase,$id,$sub);
 // Verification/restoration remains available with checkout disabled. New real
 // orders are gated independently from purchase callbacks and pending UI state.
 $test=($purchase['testPurchaseContext']['fopType']??null)==='TEST';
 if(!$test&&(($c['billing_mode']??'disabled')!=='live'||($c['live_security_approved']??false)!==true))throw new BillingException(503,'live_payments_not_approved');
 if(!worker_healthy($db))throw new BillingException(503,'refund_sync_unavailable');
 $consumed=($purchase['productLineItem'][0]['productOfferDetails']['consumptionState']??null)==='CONSUMPTION_STATE_CONSUMED';
 $w->grant($sub,$id,$token,(string)($purchase['orderId']??''),$consumed);
 // Durable receipt is the retry queue. The cron worker owns consume/ack.
 json_response(200,['verified'=>true,'productId'=>$id]+wallet_response($w,$sub,$c,$db));
}catch(BillingException $e){json_response($e->httpStatus,['error'=>$e->getMessage()]);}
