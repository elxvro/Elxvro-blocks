<?php
declare(strict_types=1);
require_once __DIR__ . '/private/bootstrap.php';
try {
    if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'GET') json_response(405, ['error' => 'method_not_allowed']);
    $config = api_config();
    $sub = api_auth_subject($config);
    $db = api_db($config);
    $query = $db->prepare('SELECT balance, supporter FROM player_wallets WHERE google_sub = ?');
    $query->execute([$sub]);
    $row = $query->fetch();
    json_response(200, ['balance' => (int)($row['balance'] ?? 0),
        'supporter' => (bool)($row['supporter'] ?? false), 'source' => 'verified_purchases']);
} catch (BillingException $e) {
    json_response($e->httpStatus, ['error' => $e->getMessage()]);
}
