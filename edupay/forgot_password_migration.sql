CREATE TABLE IF NOT EXISTS forgot_password_challenges (
    challenge_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    challenge_token_hash CHAR(64) NOT NULL,
    role VARCHAR(24) NOT NULL,
    account_source VARCHAR(48) NOT NULL,
    user_id VARCHAR(191) NOT NULL,
    otp_hash CHAR(64) NOT NULL,
    failed_attempts TINYINT UNSIGNED NOT NULL DEFAULT 0,
    status ENUM('pending', 'verified', 'used', 'expired', 'failed') NOT NULL DEFAULT 'pending',
    expires_at DATETIME(6) NOT NULL,
    verified_at DATETIME(6) NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (challenge_id),
    UNIQUE KEY uq_forgot_password_token (challenge_token_hash),
    KEY idx_forgot_password_account (role, account_source, user_id, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
