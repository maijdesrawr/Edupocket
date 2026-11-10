CREATE TABLE IF NOT EXISTS admin_account_locks (
    role VARCHAR(24) NOT NULL,
    account_source VARCHAR(48) NOT NULL,
    user_id VARCHAR(191) NOT NULL,
    is_locked TINYINT(1) NOT NULL DEFAULT 0,
    updated_by VARCHAR(191) NOT NULL,
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
        ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (role, account_source, user_id),
    KEY idx_admin_account_locks_state (is_locked, role)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
