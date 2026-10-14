-- MySQL 8+ or MariaDB 10.4+, InnoDB required
CREATE TABLE IF NOT EXISTS player_wallets (
    google_sub VARCHAR(40) CHARACTER SET ascii COLLATE ascii_bin NOT NULL PRIMARY KEY,
    balance BIGINT UNSIGNED NOT NULL DEFAULT 0,
    supporter TINYINT(1) NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS play_purchases (
    token_hmac CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL PRIMARY KEY,
    google_sub VARCHAR(40) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    product_id VARCHAR(70) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    order_id VARCHAR(128) NULL,
    coins_granted INT UNSIGNED NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_player (google_sub),
    CONSTRAINT fk_play_purchase_wallet FOREIGN KEY (google_sub) REFERENCES player_wallets (google_sub)
) ENGINE=InnoDB;
