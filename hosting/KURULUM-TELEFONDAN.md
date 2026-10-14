# ELXVRO Blocks v0.28.3

PHP 8.1+ (PDO MySQL, cURL, OpenSSL), MySQL 8+/MariaDB InnoDB.
This package is code, not proof of a live deployment. Live Google account,
service-account permissions, cron and device purchases must be tested before sales.

## Existing installation
1. Back up your database and existing private/config.php privately.
2. Upload UPLOAD_TO_BLOCK_SUBDOMAIN contents over the existing app API.
   There is deliberately NO config.php, service-account JSON or secret in this ZIP.
3. Run SQL/schema.sql then SQL/v0283.sql in phpMyAdmin. Both are additive CREATE
   TABLE IF NOT EXISTS migrations; existing player_wallets/play_purchases survive.
4. Copy private/deployment.example.php to private/deployment.php privately. Set
   token_encryption_key to base64 of 32 random bytes (PHP random_bytes). Keep it
   backed up alongside purchase_token_hmac_secret; changing either loses lookup
   or decryption ability. Do not paste keys into chat, GitHub or downloadable files.
5. Keep existing Google audience/package/DB/service-account configuration. The
   service account needs Google Play purchase read and order management rights.
6. Schedule private/reconcile.php with the host's PHP CLI every minute. It is
   CLI-only, uses a MySQL advisory lock, scans paginated voided purchases with
   overlap, validates purchases and retries consume/ack after durable fulfilment.
7. Verify /private/config.php, /private/deployment.php, service-account JSON and
   /private/cache are inaccessible by HTTP. Apache .htaccess must be enabled;
   Nginx requires an equivalent deny rule. HTTPS is mandatory; redirect HTTP at
   the virtual-host level before activation.
8. Set payments_enabled=true only for an approved test environment, and
   billing_mode=test. live_security_approved remains false. Test-card purchases
   can be fulfilled; real purchase callbacks are refused in test mode.
9. The distributed signed build has ELXVRO_BILLING_ENABLED=false. After device
   tests and explicit release approval, build with that flag true and configure
   live mode. Do not merely toggle the backend or a Console product and assume
   security is verified.

A stale/failed reconciliation worker disables checkout and spending after five
minutes. Monitor cron errors and alert on a stale billing_worker_state timestamp.
The 200-receipt batch needs load testing before substantial sales; scale worker
throughput so acknowledgements complete within Google's deadline. No guarantee
of instant refund detection is made: Google event visibility and the cron period
bound the detection delay. Consumed refunds are handled by the voided API.

## API
All requests use Authorization: Bearer <fresh Google ID token>. Server verifies
RS256 signature, issuer, audience, expiry and subject, never a client player ID.

GET /wallet.php returns protocol:3, source:"verified_purchases", balance,
revision, supporter, debt, inventory:{undo,refresh,special}, themes:[...],
checkoutEnabled, billingMode.

POST /verify_purchase.php JSON:
{"platform":"google_play","productId":"elxvro_coins_500","purchaseToken":"..."}
Response adds verified:true and productId to the wallet. This does NOT mint coins
locally. Invalid/pending/cancelled/refunded/account-mismatched tokens fail closed.
The app sets applicationUserName to SHA256("elxvro.blocks|" + Google subject).

POST /spend.php JSON:
{"action":"buy","sku":"undo_3","operationId":"UUID-v4"}
Other SKUs: refresh_3, special_3, power_bundle, theme:night, theme:marble,
theme:fire, theme:nature, theme:aurora. Prices match the existing game:
120/120/180/300 and 300/500/700/700/1000 respectively.
Use action:"use", sku:"undo"|"refresh"|"special" to consume paid inventory.
Response is the current complete wallet. Reuse the same operationId on uncertain
network failure; reuse with a different action/SKU is rejected. HTTP 409 means a
state conflict/insufficient funds, 401 login, 503 unavailable or safety gate.

Paid assets are separate from locally earned offline rewards. Existing earned
coins and powers are preserved and spent first; there is no upload of a trusted
client-provided balance. If local coins are insufficient, the complete purchase
price is charged to the paid wallet; balances are not combined. Paid inventory
requires internet and restores on another device with the same Google account.
Offline earned rewards remain local (no new cloud save for offline progression).
Refunds remove available balance; spent amounts become debt. Further paid spending
and paid inventory access are blocked until debt is cleared. Refunds remove the
supporter badge unless another unrevoked badge purchase exists.

## Build configuration
Branch work-v0.28.3, version 0.28.3+57. Original workflows/signing secrets unchanged.
New version workflow reuses the existing successful restore/Android/signing steps.
ELXVRO_GOOGLE_WEB_CLIENT_ID must be the same web OAuth audience as the server.
Android OAuth must contain com.elxvro.elxvro_blocks and Play app-signing SHA-1.
ELXVRO_BILLING_VERIFY_URL defaults to https://block.elxvro.com/verify_purchase.php.
The wallet/spend base defaults to https://block.elxvro.com. If changing the
verifier host, configure ELXVRO_BILLING_API_BASE to the matching HTTPS API base.

## Pending external acceptance
Real Google signature/permissions, license-test successful/declined/pending
purchases for all products, badge restore, same-account two-device concurrent
spending, refunds after spend, cron restart/failure, HTTPS/private-file denial,
production database backup/migration and load testing require the live environment.
No hosting configuration or live database was modified by this code change.
