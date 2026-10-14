<?php
declare(strict_types=1);
require __DIR__.'/private/v0283.php';
try{
 $input=api_start();$c=billing_config();$sub=api_auth_subject($c);$db=api_db($c);
 if(!worker_healthy($db))throw new BillingException(503,'refund_sync_unavailable');
 $sku=$input['sku']??null;$op=$input['operationId']??null;
 if(!is_string($sku)||!is_string($op))throw new BillingException(400,'invalid_request');
 $w=new Wallet($db,$c);$action=$input['action']??'buy';
 if($action==='buy')$w->spend($sub,$sku,$op);
 elseif($action==='use')$w->useItem($sub,$sku,$op);
 else throw new BillingException(400,'invalid_action');
 json_response(200,wallet_response($w,$sub,$c,$db));
}catch(BillingException $e){json_response($e->httpStatus,['error'=>$e->getMessage()]);}
