# ELXVRO Blocks / block.elxvro.com Billing API Staging

**This package has NOT been deployed.** It contains a fail-closed PHP 8.1+ and MySQL staging verifier for `com.elxvro.elxvro_blocks`.

- Hosted HTTPS entrypoints: `/verify_purchase.php`, `/wallet.php`, `/health.php`.
- Google ID token RS256 verification against Google JWKS + audience/issuer/expiry.
- Google Play Publisher API v2 purchase state verification.
- Purchaser-to-purchase token binding via obfuscatedAccountId.
- MySQL/InnoDB transactional coin ledger with token-level idempotence.
- No secrets included, payments disabled in config by default.
- No automatic user sign-in or gameplay earned-coin synchronization in the existing APK.
- Backend acknowledgement/consumption and refund reconciliation are still TODO before any real-money launch.

See **KURULUM-TELEFONDAN.md** for Turkish mobile/cPanel installation instructions and `SQL/schema.sql` for tables.

This is a staging foundation, **not** a production-ready paid backend. Never set `payments_enabled` to true until the unfinished security and reconciliation work is completed.
