<?php
declare(strict_types=1);
require_once __DIR__ . '/private/bootstrap.php';
try {
    if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') {
        header('Allow: POST');
        json_response(405, ['error' => 'method_not_allowed']);
    }
    $input = api_start();
    $config = api_config();
    $sub = api_auth_subject($config);
    $catalog = [
        'theme' => [], // Theme catalog must be validated against the game catalog before activation.
        'undo_3' => 60,
        'refresh_3' => 90,
        'special_3' => 180,
        'power_bundle' => 300,
    ];
    $sku = $input['sku'] ?? null;
    $operation = $input['operationId'] ?? null;
    if (!is_string($sku) || !isset($catalog[$sku]) || !is_int($catalog[$sku])) {
        json_response(400, ['error' => 'unknown_sku']);
    }
    if (!is_string($operation) || !preg_match('/^[a-f0-9-]{36}$/D', $operation)) {
        json_response(400, ['error' => 'invalid_operation_id']);
    }
    // Deliberately disabled until the app's entitlement redemption protocol is implemented.
    // A wallet debit without durable entitlement delivery could permanently lose paid coins.
    json_response(503, ['error' => 'spending_not_activated']);
} catch (BillingException $e) {
    json_response($e->httpStatus, ['error' => $e->getMessage()]);
}
