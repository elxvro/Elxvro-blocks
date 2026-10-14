<?php
declare(strict_types=1);
require_once __DIR__ . '/../UPLOAD_TO_BLOCK_SUBDOMAIN/private/Billing.php';
function check(bool $value, string $message): void {if (!$value) throw new RuntimeException($message);}
function denied(callable $fn, string $code): void {
    try { $fn(); } catch (BillingException $e) {check($e->getMessage() === $code, 'Wrong rejection ' . $e->getMessage());return;}
    throw new RuntimeException('Expected refusal ' . $code);
}
$sub='12345678901234567890';
$binding=hash('sha256','elxvro.blocks|'.$sub);
$sample=['purchaseStateContext'=>['purchaseState'=>'PURCHASED'],
 'productLineItem'=>[['productId'=>'elxvro_supporter_badge','productOfferDetails'=>['quantity'=>1,'refundableQuantity'=>1]]],
 'obfuscatedExternalAccountId'=>$binding];
check(PurchaseRules::verify($sample,'elxvro_supporter_badge',$sub)['supporter']===true,'supporter');
check(count(Products::CATALOG)===1,'supporter-only product count');
denied(fn()=>Products::get('elxvro_coins_500'),'unknown_product');
denied(fn()=>Products::get('elxvro_coins_1500'),'unknown_product');
denied(fn()=>Products::get('elxvro_coins_4000'),'unknown_product');
$mismatch=$sample;$mismatch['productLineItem'][0]['productId']='elxvro_coins_500';
denied(fn()=>PurchaseRules::verify($mismatch,'elxvro_supporter_badge',$sub),'product_mismatch');
denied(fn()=>PurchaseRules::verify($sample,'elxvro_supporter_badge','11111111111111111111'),'purchase_account_binding_required');
$pending=$sample;$pending['purchaseStateContext']['purchaseState']='PENDING';
denied(fn()=>PurchaseRules::verify($pending,'elxvro_supporter_badge',$sub),'payment_not_completed');
$refund=$sample;$refund['productLineItem'][0]['productOfferDetails']['refundableQuantity']=0;
denied(fn()=>PurchaseRules::verify($refund,'elxvro_supporter_badge',$sub),'quantity_or_refund_mismatch');
$multiple=$sample;$multiple['productLineItem'][]=$sample['productLineItem'][0];
denied(fn()=>PurchaseRules::verify($multiple,'elxvro_supporter_badge',$sub),'product_mismatch');
$malformed=$sample;$malformed['productLineItem'][0]['productOfferDetails']['quantity']='1garbage';
denied(fn()=>PurchaseRules::verify($malformed,'elxvro_supporter_badge',$sub),'quantity_or_refund_mismatch');
$malformed=$sample;$malformed['productLineItem'][0]['productOfferDetails']['refundableQuantity']='1garbage';
denied(fn()=>PurchaseRules::verify($malformed,'elxvro_supporter_badge',$sub),'quantity_or_refund_mismatch');
// Ensure the catalogue never contains a zero-coin consumable.
foreach (Products::CATALOG as $id => $entry) {
    check(($entry['supporter'] === true) || $entry['coins'] > 0, 'invalid catalog ' . $id);
}
echo "PASS: 10 checks; catalog, product, purchaser, refund and pending payment rules.\n";
$missing=$sample;unset($missing['productLineItem'][0]['productOfferDetails']['refundableQuantity']);
denied(fn()=>PurchaseRules::verify($missing,'elxvro_supporter_badge',$sub),'quantity_or_refund_mismatch');
$cancelled=$sample;$cancelled['purchaseStateContext']['purchaseState']='CANCELLED';
denied(fn()=>PurchaseRules::verify($cancelled,'elxvro_supporter_badge',$sub),'payment_not_completed');
try{(new GoogleIdentity(['google_oauth_audience'=>'test']))->subject('eyJhbGciOiJub25lIn0.eyJzdWIiOiIxMjM0NTY3ODkwMTIzNDU2Nzg5MCJ9.ZmFrZQ');throw new LogicException('Unsigned identity accepted');}catch(RuntimeException $e){check(!($e instanceof LogicException),'identity');}
echo "PASS: missing refund fields, cancelled payment, forged identity\n";
