<?php
declare(strict_types=1);
require __DIR__.'/../UPLOAD_TO_BLOCK_SUBDOMAIN/private/Billing.php';
require __DIR__.'/../UPLOAD_TO_BLOCK_SUBDOMAIN/private/SupporterPolicy.php';
function expectPolicy(bool $v): void {if(!$v)throw new RuntimeException('policy failed');}
function refused(callable $f): void {try{$f();}catch(BillingException $e){return;}throw new RuntimeException('unsafe payment accepted');}
$sub='12345678901234567890';
$test=['testPurchaseContext'=>['fopType'=>'TEST']];
$c=['payments_enabled'=>true,'billing_mode'=>'test','license_test_subjects'=>[$sub],'live_security_approved'=>false];
SupporterPolicy::authorize($c,$sub,$test);
refused(fn()=>SupporterPolicy::authorize($c,$sub,[]));
refused(fn()=>SupporterPolicy::authorize($c,'other',$test));
refused(fn()=>SupporterPolicy::authorize(array_replace($c,['payments_enabled'=>false]),$sub,$test));
refused(fn()=>SupporterPolicy::authorize(array_replace($c,['billing_mode'=>'disabled']),$sub,$test));
refused(fn()=>SupporterPolicy::authorize(array_replace($c,['billing_mode'=>'live']),$sub,[]));
SupporterPolicy::authorize(array_replace($c,['billing_mode'=>'live','live_security_approved'=>true]),$sub,[]);
expectPolicy(SupporterPolicy::canCheckout($c,$sub));
expectPolicy(!SupporterPolicy::canCheckout($c,'other'));
echo "PASS: test allowlist, disabled checkout, real-payment refusal, explicit live approval\n";
