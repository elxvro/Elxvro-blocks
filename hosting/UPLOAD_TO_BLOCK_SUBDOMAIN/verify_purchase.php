<?php
declare(strict_types=1);
require_once __DIR__ . '/private/bootstrap.php';
try {
    if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') {
        header('Allow: POST');
        json_response(405, ['error' => 'method_not_allowed']);
    }
    $config = api_config();
    $data = api_start();
    $sub = api_auth_subject($config);
    if (($config['payments_enabled'] ?? false) !== true) {
        json_response(503, ['error' => 'payments_not_enabled']);
    }
    $productId = $data['productId'] ?? '';
    $token = $data['purchaseToken'] ?? '';
    if (($data['platform'] ?? null) !== 'google_play' || !is_string($productId) ||
        !is_string($token) || strlen($token) < 16 || strlen($token) > 4096) {
        json_response(400, ['error' => 'invalid_purchase_request']);
    }
    Products::get($productId);
    $google = new GoogleApi($config);
    $purchase = $google->playPurchase($token);
    $product = PurchaseRules::verify($purchase, $productId, $sub);
    $result = (new Ledger(api_db($config), $config))->grant(
        $sub, $productId, $token, $product, (string)($purchase['orderId'] ?? ''));
    // Existing v0.28.1 client consumes/acknowledges after verified response.
    // The server does not double-consume here. Next release must switch
    // fulfilment/acknowledgement to a backend retry worker before live sale.
    json_response(200, $result);
} catch (BillingException $e) {
    json_response($e->httpStatus, ['error' => $e->getMessage()]);
} catch (Throwable $e) {
    error_log('ELXVRO verify_purchase internal failure: ' . get_class($e));
    json_response(503, ['error' => 'verification_temporarily_unavailable']);
}
