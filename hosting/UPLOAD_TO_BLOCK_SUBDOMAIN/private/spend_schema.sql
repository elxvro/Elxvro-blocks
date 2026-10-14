-- Staged only. Not used until server-authoritative entitlement redemption is implemented.
CREATE TABLE IF NOT EXISTS wallet_spend_operations (
  operation_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL PRIMARY KEY,
  google_sub VARCHAR(40) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  sku VARCHAR(80) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  amount INT UNSIGNED NOT NULL,
  entitlement_state ENUM('reserved','fulfilled','refunded') NOT NULL DEFAULT 'reserved',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_spend_user (google_sub),
  CONSTRAINT fk_spend_wallet FOREIGN KEY (google_sub) REFERENCES player_wallets(google_sub)
) ENGINE=InnoDB;
