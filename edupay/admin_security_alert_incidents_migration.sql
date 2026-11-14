CREATE TABLE IF NOT EXISTS admin_security_alert_cursors (
    cursor_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    account_role VARCHAR(32) NOT NULL,
    account_source VARCHAR(64) NOT NULL,
    user_id VARCHAR(191) NOT NULL,
    attempt_type ENUM('login_password','payment_pin','topup_pin') NOT NULL,
    last_alerted_attempt_id BIGINT UNSIGNED NOT NULL DEFAULT 0,
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
        ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (cursor_id),
    UNIQUE KEY uq_admin_security_alert_cursor_account
        (account_role, account_source, user_id, attempt_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS admin_security_alert_incidents (
    alert_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    alert_type VARCHAR(40) NOT NULL,
    account_role VARCHAR(32) NOT NULL,
    account_source VARCHAR(64) NOT NULL,
    user_id VARCHAR(191) NOT NULL,
    attempt_type ENUM('login_password','payment_pin','topup_pin') NOT NULL,
    attempt_count INT UNSIGNED NOT NULL,
    first_attempt_id BIGINT UNSIGNED NOT NULL,
    last_attempt_id BIGINT UNSIGNED NOT NULL,
    first_at DATETIME(6) NOT NULL,
    last_at DATETIME(6) NOT NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    email_sent_at DATETIME(6) NULL DEFAULT NULL,
    PRIMARY KEY (alert_id),
    UNIQUE KEY uq_admin_security_alert_incident_tail
        (alert_type, account_role, account_source, user_id, last_attempt_id),
    KEY idx_admin_security_alert_incident_pending (email_sent_at, created_at),
    KEY idx_admin_security_alert_incident_account
        (account_role, account_source, user_id, attempt_type, last_attempt_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS admin_dashboard_alert_dismissals (
    dismissal_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    alert_type VARCHAR(40) NOT NULL,
    account_role VARCHAR(32) NOT NULL,
    account_source VARCHAR(64) NOT NULL,
    user_id VARCHAR(191) NOT NULL,
    alert_id BIGINT UNSIGNED NOT NULL DEFAULT 0,
    dismissed_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (dismissal_id),
    UNIQUE KEY uq_admin_dashboard_alert_dismissal
        (alert_type, account_role, account_source, user_id, alert_id),
    KEY idx_admin_dashboard_alert_dismissed_at (dismissed_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
