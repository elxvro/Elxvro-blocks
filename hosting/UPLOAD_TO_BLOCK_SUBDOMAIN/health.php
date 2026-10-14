<?php
declare(strict_types=1);
require_once __DIR__ . '/private/bootstrap.php';
$file = __DIR__ . '/private/config.php';
$config = is_file($file) ? (require $file) : [];
json_response(200, [
    'service' => 'ELXVRO Blocks purchase verification',
    'version' => '0.1.0-staging',
    'status' => is_array($config) && !empty($config['android_package']) ? 'configured_staging' : 'setup_required',
    'real_payments' => false, // deliberately avoid exposing or asserting live readiness
]);
