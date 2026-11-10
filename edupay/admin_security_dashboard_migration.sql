CREATE TABLE IF NOT EXISTS admin_security_attempts (
    attempt_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    account_role VARCHAR(32) NOT NULL,
    account_source VARCHAR(64) NOT NULL,
    user_id VARCHAR(191) NOT NULL,
    attempt_type ENUM('login_password','payment_pin','topup_pin') NOT NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (attempt_id),
    KEY idx_admin_security_attempts_user_time (account_role, account_source, user_id, attempt_type, created_at),
    KEY idx_admin_security_attempts_time (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS admin_dashboard_alert_sends (
    send_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    alert_type VARCHAR(40) NOT NULL,
    account_role VARCHAR(32) NOT NULL,
    account_source VARCHAR(64) NOT NULL,
    user_id VARCHAR(191) NOT NULL,
    last_attempt_id BIGINT UNSIGNED NOT NULL DEFAULT 0,
    sent_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (send_id),
    UNIQUE KEY uq_admin_dashboard_alert_account (alert_type, account_role, account_source, user_id),
    KEY idx_admin_dashboard_alert_sent_at (sent_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
