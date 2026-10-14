<?php
declare(strict_types=1);
require __DIR__.'/private/v0283.php';
if(($_SERVER['REQUEST_METHOD']??'')!=='GET')json_response(405,['error'=>'method_not_allowed']);
$c=billing_config();$sub=api_auth_subject($c);$db=api_db($c);
json_response(200,wallet_response(new Wallet($db,$c),$sub,$c,$db));
