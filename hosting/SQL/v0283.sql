-- Additive migration. Never drops or rewrites existing wallets or purchases.
CREATE TABLE IF NOT EXISTS billing_accounts (
 google_sub VARCHAR(40) CHARACTER SET ascii COLLATE ascii_bin PRIMARY KEY,
 debt BIGINT UNSIGNED NOT NULL DEFAULT 0,
 revision BIGINT UNSIGNED NOT NULL DEFAULT 0,
 FOREIGN KEY(google_sub) REFERENCES player_wallets(google_sub)
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS billing_receipts (
 token_hmac CHAR(64) CHARACTER SET ascii COLLATE ascii_bin PRIMARY KEY,
 order_id VARCHAR(128) CHARACTER SET ascii COLLATE ascii_bin NULL UNIQUE,
 encrypted_token TEXT NOT NULL,
 revoked TINYINT NOT NULL DEFAULT 0,
 finalized TINYINT NOT NULL DEFAULT 0,
 checked_at TIMESTAMP NULL,
 FOREIGN KEY(token_hmac) REFERENCES play_purchases(token_hmac)
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS billing_inventory (
 google_sub VARCHAR(40) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 sku VARCHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 quantity INT UNSIGNED NOT NULL DEFAULT 0,
 PRIMARY KEY(google_sub,sku),
 FOREIGN KEY(google_sub) REFERENCES player_wallets(google_sub)
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS billing_operations (
 google_sub VARCHAR(40) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 operation_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 action VARCHAR(80) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 PRIMARY KEY(google_sub,operation_id),
 FOREIGN KEY(google_sub) REFERENCES player_wallets(google_sub)
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS billing_worker_state (
 id INT PRIMARY KEY,
 last_success BIGINT NOT NULL DEFAULT 0
) ENGINE=InnoDB;
INSERT IGNORE INTO billing_worker_state (id) VALUES(1);
