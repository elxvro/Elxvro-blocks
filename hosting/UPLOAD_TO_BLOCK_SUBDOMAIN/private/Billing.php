<?php
declare(strict_types=1);

final class BillingException extends RuntimeException
{
    public function __construct(public readonly int $httpStatus, string $code)
    {
        parent::__construct($code);
    }
}

final class Products
{
    public const CATALOG = [
        'elxvro_supporter_badge' => ['coins' => 0, 'supporter' => true],
    ];

    public static function get(string $id): array
    {
        return self::CATALOG[$id] ?? throw new BillingException(400, 'unknown_product');
    }
}

final class HttpClient
{
    /** @return array{0:int,1:string} */
    public static function request(string $method, string $url, array $headers = [], ?string $body = null): array
    {
        $ch = curl_init($url);
        if (!$ch) throw new RuntimeException('cURL unavailable');
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_CUSTOMREQUEST => $method,
            CURLOPT_CONNECTTIMEOUT => 5,
            CURLOPT_TIMEOUT => 20,
            CURLOPT_SSL_VERIFYPEER => true,
            CURLOPT_SSL_VERIFYHOST => 2,
            CURLOPT_HTTPHEADER => $headers,
            CURLOPT_FOLLOWLOCATION => false,
            CURLOPT_PROTOCOLS => CURLPROTO_HTTPS,
        ]);
        if ($body !== null) curl_setopt($ch, CURLOPT_POSTFIELDS, $body);
        $response = curl_exec($ch);
        $status = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $error = curl_error($ch);
        curl_close($ch);
        if (!is_string($response)) throw new RuntimeException('HTTP transfer: ' . $error);
        return [$status, $response];
    }
}

final class GoogleApi
{
    public function __construct(private readonly array $config) {}

    public function playPurchase(string $token): array
    {
        $pkg = $this->packageName();
        $url = 'https://androidpublisher.googleapis.com/androidpublisher/v3/applications/'
            . rawurlencode($pkg) . '/purchases/productsv2/tokens/' . rawurlencode($token);
        return $this->apiGet($url);
    }

    public function finishPurchase(string $productId, string $token, bool $isSupporter): void
    {
        $prefix = 'https://androidpublisher.googleapis.com/androidpublisher/v3/applications/'
            . rawurlencode($this->packageName()) . '/purchases/products/'
            . rawurlencode($productId) . '/tokens/' . rawurlencode($token);
        $url = $prefix . ($isSupporter ? ':acknowledge' : ':consume');
        [$status, $response] = HttpClient::request('POST', $url,
            ['Authorization: Bearer ' . $this->accessToken(), 'Content-Type: application/json'], '{}');
        if ($status !== 200 && $status !== 204) {
            // Must retry an unfinished acknowledgement; never revoke already-granted coins silently.
            throw new RuntimeException('Google Play finalization failed with HTTP ' . $status);
        }
    }

    public function voided(?string $page): array
    {
        $query=['startTime'=>(string)((time()-29*86400)*1000),'type'=>0,'includeQuantityBasedPartialRefund'=>'true','maxResults'=>1000];
        if($page!==null)$query['token']=$page;
        return $this->apiGet('https://androidpublisher.googleapis.com/androidpublisher/v3/applications/'.rawurlencode($this->packageName()).'/purchases/voidedpurchases?'.http_build_query($query));
    }

    private function apiGet(string $url): array
    {
        [$status, $response] = HttpClient::request('GET', $url,
            ['Authorization: Bearer ' . $this->accessToken(), 'Accept: application/json']);
        if ($status === 404 || $status === 400) throw new BillingException(422, 'purchase_not_found');
        if ($status !== 200) throw new BillingException(503, 'google_play_api_unavailable');
        $data = json_decode($response, true);
        if (!is_array($data)) throw new BillingException(503, 'invalid_google_play_response');
        return $data;
    }

    private function packageName(): string
    {
        $package = $this->config['android_package'] ?? '';
        if (!is_string($package) || !preg_match('/^[a-z][a-z0-9_.]+$/', $package)) {
            throw new BillingException(503, 'invalid_package_configuration');
        }
        return $package;
    }

    private function accessToken(): string
    {
        $file = $this->config['service_account_json'] ?? '';
        if (!is_string($file) || !is_file($file)) throw new BillingException(503, 'service_account_missing');
        $json = json_decode((string) file_get_contents($file), true);
        if (!is_array($json) || empty($json['client_email']) || empty($json['private_key'])) {
            throw new BillingException(503, 'invalid_service_account');
        }
        $now = time();
        $header = self::base64url(json_encode(['alg' => 'RS256', 'typ' => 'JWT'], JSON_THROW_ON_ERROR));
        $claims = self::base64url(json_encode([
            'iss' => $json['client_email'],
            'scope' => 'https://www.googleapis.com/auth/androidpublisher',
            'aud' => 'https://oauth2.googleapis.com/token',
            'iat' => $now - 30,
            'exp' => $now + 3000,
        ], JSON_THROW_ON_ERROR));
        $payload = $header . '.' . $claims;
        if (!openssl_sign($payload, $signature, $json['private_key'], OPENSSL_ALGO_SHA256)) {
            throw new BillingException(503, 'service_account_sign_failed');
        }
        $assertion = $payload . '.' . self::base64url($signature);
        [$status, $response] = HttpClient::request('POST', 'https://oauth2.googleapis.com/token',
            ['Content-Type: application/x-www-form-urlencoded'],
            http_build_query(['grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer', 'assertion' => $assertion]));
        $data = json_decode($response, true);
        if ($status !== 200 || !is_array($data) || empty($data['access_token'])) {
            throw new BillingException(503, 'google_service_account_authorization_failed');
        }
        return (string) $data['access_token'];
    }

    public static function base64url(string $str): string
    {
        return rtrim(strtr(base64_encode($str), '+/', '-_'), '=');
    }
}

final class GoogleIdentity
{
    public function __construct(private readonly array $config) {}

    public function subject(string $idToken): string
    {
        $pieces = explode('.', $idToken);
        if (count($pieces) !== 3 || strlen($idToken) > 8192) throw new RuntimeException('JWT format');
        [$encodedHeader, $encodedClaims, $encodedSignature] = $pieces;
        $header = json_decode(self::decode64($encodedHeader), true);
        $claims = json_decode(self::decode64($encodedClaims), true);
        if (!is_array($header) || !is_array($claims) || ($header['alg'] ?? null) !== 'RS256') {
            throw new RuntimeException('JWT algorithm');
        }
        $aud = $this->config['google_oauth_audience'] ?? '';
        if (!is_string($aud) || $aud === '' || ($claims['aud'] ?? null) !== $aud ||
            !in_array($claims['iss'] ?? null, ['accounts.google.com', 'https://accounts.google.com'], true) ||
            !is_int($claims['exp'] ?? null) || $claims['exp'] <= time() ||
            !is_int($claims['iat'] ?? null) || $claims['iat'] > time() + 120 ||
            !is_string($claims['sub'] ?? null) || !preg_match('/^[0-9]{10,32}$/', $claims['sub'])) {
            throw new RuntimeException('JWT claims');
        }
        $kid = $header['kid'] ?? '';
        if (!is_string($kid) || strlen($kid) > 256 || $kid === '') throw new RuntimeException('JWT kid');
        $keys = $this->googleKeys();
        $key = null;
        foreach ($keys['keys'] ?? [] as $candidate) {
            if (($candidate['kid'] ?? null) === $kid && ($candidate['kty'] ?? null) === 'RSA' &&
                ($candidate['alg'] ?? 'RS256') === 'RS256') $key = $candidate;
        }
        if ($key === null) throw new RuntimeException('JWT unknown key');
        $pem = self::jwkToPem($key);
        $signature = self::decode64($encodedSignature);
        if (openssl_verify($encodedHeader . '.' . $encodedClaims, $signature, $pem, OPENSSL_ALGO_SHA256) !== 1) {
            throw new RuntimeException('JWT signature');
        }
        return $claims['sub'];
    }

    private function googleKeys(): array
    {
        $file = __DIR__ . '/cache/jwks.json';
        if (is_file($file) && filemtime($file) > time() - 3600) {
            $cached = json_decode((string)file_get_contents($file), true);
            if (is_array($cached) && !empty($cached['keys'])) return $cached;
        }
        [$status, $body] = HttpClient::request('GET', 'https://www.googleapis.com/oauth2/v3/certs');
        if ($status !== 200) throw new RuntimeException('JWKS unavailable');
        $keys = json_decode($body, true);
        if (!is_array($keys) || empty($keys['keys'])) throw new RuntimeException('Invalid JWKS');
        if (is_dir(dirname($file)) && is_writable(dirname($file))) {
            @file_put_contents($file, json_encode($keys, JSON_THROW_ON_ERROR), LOCK_EX);
        }
        return $keys;
    }

    private static function decode64(string $raw): string
    {
        if ($raw === '' || !preg_match('/^[a-zA-Z0-9_-]+$/', $raw)) throw new RuntimeException('base64url');
        $decoded = base64_decode(strtr($raw, '-_', '+/'), true);
        if (!is_string($decoded)) throw new RuntimeException('base64 decode');
        return $decoded;
    }

    private static function jwkToPem(array $jwk): string
    {
        if (!isset($jwk['n'], $jwk['e'])) throw new RuntimeException('RSA JWK');
        $n = self::decode64((string)$jwk['n']);
        $e = self::decode64((string)$jwk['e']);
        $int = static function (string $value): string {
            if ((ord($value[0]) & 0x80) !== 0) $value = "\x00" . $value;
            return "\x02" . self::length(strlen($value)) . $value;
        };
        $body = $int($n) . $int($e);
        $sequence = "\x30" . self::length(strlen($body)) . $body;
        $bitString = "\x03" . self::length(strlen($sequence) + 1) . "\x00" . $sequence;
        $algorithm = hex2bin('300d06092a864886f70d0101010500');
        $publicKey = $algorithm . $bitString;
        $der = "\x30" . self::length(strlen($publicKey)) . $publicKey;
        return "-----BEGIN PUBLIC KEY-----\n" . chunk_split(base64_encode($der), 64, "\n") . "-----END PUBLIC KEY-----\n";
    }

    private static function length(int $length): string
    {
        if ($length < 128) return chr($length);
        $bin = ltrim(pack('N', $length), "\x00");
        return chr(0x80 | strlen($bin)) . $bin;
    }
}

final class PurchaseRules
{
    public static function verify(array $purchase, string $productId, string $sub): array
    {
        $product = Products::get($productId);
        if (($purchase['purchaseStateContext']['purchaseState'] ?? null) !== 'PURCHASED') {
            throw new BillingException(409, 'payment_not_completed');
        }
        $items = $purchase['productLineItem'] ?? null;
        if (!is_array($items) || count($items) !== 1 ||
            ($items[0]['productId'] ?? null) !== $productId) {
            throw new BillingException(422, 'product_mismatch');
        }
        $details = $items[0]['productOfferDetails'] ?? [];
        // Reject malformed numeric values rather than coercing strings such as '1invalid' to 1.
        $quantity = $details['quantity'] ?? null;
        $refundable = $details['refundableQuantity'] ?? null;
        if (!is_array($details) || !is_int($quantity) || $quantity !== 1 ||
            !is_int($refundable) || $refundable !== 1) {
            throw new BillingException(409, 'quantity_or_refund_mismatch');
        }
        // BillingFlowParams must set this value for every new purchase.
        // A stolen purchase token cannot be claimed by another Google account.
        $expected = hash('sha256', 'elxvro.blocks|' . $sub);
        if (!isset($purchase['obfuscatedExternalAccountId']) ||
            !hash_equals($expected, (string)$purchase['obfuscatedExternalAccountId'])) {
            throw new BillingException(403, 'purchase_account_binding_required');
        }
        return $product;
    }
}

