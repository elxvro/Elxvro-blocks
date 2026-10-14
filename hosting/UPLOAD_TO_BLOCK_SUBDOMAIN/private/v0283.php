<?php
declare(strict_types=1);
require_once __DIR__.'/bootstrap.php';
require_once __DIR__.'/Wallet.php';
require_once __DIR__.'/SupporterPolicy.php';
function billing_config(): array {
    $c=api_config();$p=__DIR__.'/deployment.php';
    if(is_file($p))$c=array_replace($c,require $p);
    return $c;
}
function worker_healthy(PDO $db): bool {
    $last=$db->query('SELECT last_success FROM billing_worker_state WHERE id=1')->fetchColumn();
    return $last!==false&&(int)$last>time()-300;
}
function billing_ready(array $c,PDO $db): bool {
    $mode=$c['billing_mode']??'disabled';
    return ($c['payments_enabled']??false)===true&&in_array($mode,['test','live'],true)
        &&($mode!=='live'||($c['live_security_approved']??false)===true)&&worker_healthy($db);
}
function wallet_response(Wallet $w,string $sub,array $c,PDO $db): array {
    $snapshot=$w->snapshot($sub);$healthy=worker_healthy($db);
    if(!$healthy)$snapshot['supporter']=false; // Do not expose a stale refunded entitlement.
    return $snapshot+['checkoutEnabled'=>SupporterPolicy::canCheckout($c,$sub)&&$healthy,'billingMode'=>$c['billing_mode']??'disabled'];
}
