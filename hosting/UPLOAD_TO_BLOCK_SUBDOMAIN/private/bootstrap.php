<?php
declare(strict_types=1);

require_once __DIR__ . '/Billing.php';

set_exception_handler(static function (Throwable $e): void {
    error_log('ELXVRO Billing unhandled: ' . $e->getMessage());
    json_response(500, ['error' => 'internal_error']);
});

function json_response(int $code, array $body): never
{
    http_response_code($code);
    header('Content-Type: application/json; charset=UTF-8');
    header('Cache-Control: no-store');
    header('X-Content-Type-Options: nosniff');
    echo json_encode($body, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_THROW_ON_ERROR);
    exit;
}

function api_config(): array
{
    $file = __DIR__ . '/config.php';
    if (!is_file($file)) {
        json_response(503, ['error' => 'configuration_required']);
    }
    $config = require $file;
    if (!is_array($config)) json_response(503, ['error' => 'invalid_configuration']);
    return $config;
}

function api_start(): array
{
    if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') {
        header('Allow: POST');
        json_response(405, ['error' => 'method_not_allowed']);
    }
    if (stripos($_SERVER['CONTENT_TYPE'] ?? '', 'application/json') !== 0) {
        json_response(415, ['error' => 'json_required']);
    }
    $length = (int) ($_SERVER['CONTENT_LENGTH'] ?? 0);
    if ($length < 1 || $length > 8192) json_response(413, ['error' => 'invalid_body_size']);
    $raw = file_get_contents('php://input', false, null, 0, 8193);
    if ($raw === false || strlen($raw) > 8192) json_response(413, ['error' => 'invalid_body_size']);
    $payload = json_decode($raw, true);
    if (!is_array($payload)) json_response(400, ['error' => 'invalid_json']);
    return $payload;
}

function api_auth_subject(array $config): string
{
    $header = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
    if ($header === '' && function_exists('getallheaders')) {
        foreach (getallheaders() as $key => $value) {
            if (strtolower($key) === 'authorization') $header = (string) $value;
        }
    }
    if (!preg_match('/^Bearer ([A-Za-z0-9_.\-]+)$/', $header, $match)) {
        json_response(401, ['error' => 'google_login_required']);
    }
    try {
        return (new GoogleIdentity($config))->subject($match[1]);
    } catch (Throwable $e) {
        error_log('ELXVRO token rejected: ' . get_class($e));
        json_response(401, ['error' => 'invalid_google_identity']);
    }
}

function api_db(array $config): PDO
{
    foreach (['db_dsn', 'db_user', 'db_password'] as $key) {
        if (!isset($config[$key]) || !is_string($config[$key])) {
            json_response(503, ['error' => 'database_not_configured']);
        }
    }
    try {
        return new PDO($config['db_dsn'], $config['db_user'], $config['db_password'], [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
        ]);
    } catch (Throwable $e) {
        error_log('ELXVRO DB connection: ' . $e->getMessage());
        json_response(503, ['error' => 'database_unavailable']);
    }
}
