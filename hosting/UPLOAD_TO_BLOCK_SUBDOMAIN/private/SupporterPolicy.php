<?php
declare(strict_types=1);
final class SupporterPolicy {
    public static function canCheckout(array $c,string $sub): bool {
        if(($c['payments_enabled']??false)!==true)return false;
        $mode=$c['billing_mode']??'disabled';
        if($mode==='test')return in_array($sub,$c['license_test_subjects']??[],true);
        return $mode==='live'&&($c['live_security_approved']??false)===true;
    }
    public static function authorize(array $c,string $sub,array $purchase): void {
        if(!self::canCheckout($c,$sub))throw new BillingException(503,'supporter_checkout_disabled');
        $test=($purchase['testPurchaseContext']['fopType']??null)==='TEST';
        if(($c['billing_mode']??'disabled')==='test'&&!$test)throw new BillingException(409,'license_test_purchase_required');
    }
}
