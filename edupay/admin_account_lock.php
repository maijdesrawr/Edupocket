<?php

declare(strict_types=1);

require_once __DIR__ . '/admin_account_common.php';

header('Content-Type: application/json; charset=utf-8');

try {
    if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') {
        throw new InvalidArgumentException('POST is required.');
    }
    if (!pc_table_exists($conn, 'admin_account_locks')) {
        throw new RuntimeException('Account-lock migration has not been applied.');
    }

    $adminSession = account_admin($conn);
    $category = trim((string)($_POST['category'] ?? ''));
    $userId = trim((string)($_POST['id'] ?? ''));
    $action = trim((string)($_POST['action'] ?? ''));
    $source = trim((string)($_POST['account_source'] ?? ''));

    if (!in_array($category, ['parent', 'pos', 'cashier'], true)) {
        throw new InvalidArgumentException('Choose a parent, canteen, or cashier account.');
    }
    if (!in_array($action, ['lock', 'unlock'], true)) {
        throw new InvalidArgumentException('Invalid account action.');
    }
    if ($userId === '' || strlen($userId) > 191) {
        throw new InvalidArgumentException('A valid account ID is required.');
    }

    $role = match ($category) {
        'parent' => 'parent',
        'pos' => 'canteen',
        'cashier' => 'cashier',
    };
    $expectedSource = match ($category) {
        'parent' => 'parents',
        'pos' => 'canteens',
        'cashier' => $source,
    };
    if (!in_array($expectedSource, $category === 'cashier'
        ? ['cashiers', 'admins']
        : [$expectedSource], true)) {
        throw new InvalidArgumentException('Invalid account source.');
    }

    if (!$conn->begin_transaction()) {
        throw new RuntimeException('Account status could not be updated.');
    }
    $account = pc_fetch_account_from_source_for_update(
        $conn,
        $role,
        $userId,
        $expectedSource
    );
    if ($account === null) {
        throw new InvalidArgumentException('The selected account was not found.');
    }

    $newStatus = $action === 'lock' ? 1 : 0;
    $adminId = (string)$adminSession['user_id'];
    $statement = pc_prepare(
        $conn,
        'INSERT INTO admin_account_locks '
            . '(role, account_source, user_id, is_locked, updated_by) '
            . 'VALUES (?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE '
            . 'is_locked = VALUES(is_locked), updated_by = VALUES(updated_by)'
    );
    $statement->bind_param('sssis', $role, $expectedSource, $userId, $newStatus, $adminId);
    $statement->execute();
    $statement->close();

    if ($newStatus === 1) {
        $revoke = pc_prepare(
            $conn,
            "UPDATE app_sessions SET revoked_at = COALESCE(revoked_at, NOW(6)), "
                . "revocation_reason = CASE WHEN revoked_at IS NULL THEN 'account_locked' ELSE revocation_reason END "
                . 'WHERE role = ? AND account_source = ? AND user_id = ?'
        );
        $revoke->bind_param('sss', $role, $expectedSource, $userId);
        $revoke->execute();
        $revoke->close();

        $release = pc_prepare(
            $conn,
            'UPDATE app_session_accounts SET current_session_id = NULL '
                . 'WHERE role = ? AND account_source = ? AND user_id = ?'
        );
        $release->bind_param('sss', $role, $expectedSource, $userId);
        $release->execute();
        $release->close();
    }

    as_record_activity(
        $conn,
        $adminSession,
        'account_manually_' . ($newStatus === 1 ? 'locked' : 'unlocked'),
        [
            'role' => $role,
            'account_source' => $expectedSource,
            'user_id' => $userId,
        ],
        'server',
        'info'
    );
    $conn->commit();

    echo json_encode([
        'status' => 'success',
        'is_locked' => $newStatus,
        'message' => $newStatus === 1
            ? 'Account locked successfully.'
            : 'Account unlocked successfully.',
    ]);
} catch (Throwable $error) {
    try {
        $conn->rollback();
    } catch (Throwable $rollbackError) {
        error_log('Account-lock rollback failed: ' . $rollbackError->getMessage());
    }
    error_log('Admin account lock failed: ' . $error->getMessage());
    http_response_code($error instanceof InvalidArgumentException ? 400 : 500);
    echo json_encode(['status' => 'error', 'message' => $error->getMessage()]);
}
