<?php
declare(strict_types=1);

require_once __DIR__ . '/login_otp_common.php';
pc_bootstrap_json_endpoint();
pc_require_post();

try {
    $conn = pc_open_database();
    $session = as_require_session($conn, false);
    if (($session['role'] ?? '') !== 'admin') {
        pc_reject('Administrator access is required.');
    }

    if (!pc_table_exists($conn, 'admin_dashboard_alert_dismissals')) {
        pc_reject('Alert deletion is not configured.');
    }

    $input = json_decode((string)file_get_contents('php://input'), true);
    if (!is_array($input)) $input = $_POST;
    $alerts = $input['alerts'] ?? null;
    if (!is_array($alerts) || count($alerts) < 1 || count($alerts) > 100) {
        pc_reject('Select between 1 and 100 alerts to delete.');
    }

    $dismissed = 0;
    $skipped = 0;
    foreach ($alerts as $alert) {
        if (!is_array($alert)) {
            $skipped++;
            continue;
        }

        $type = (string)($alert['type'] ?? '');
        $role = (string)($alert['role'] ?? '');
        $source = (string)($alert['source'] ?? '');
        $userId = trim((string)($alert['user_id'] ?? ''));
        $alertId = (int)($alert['alert_id'] ?? 0);
        if ($userId === '' || !in_array($type, ['login_failures', 'failed_transactions', 'account_setup'], true)) {
            $skipped++;
            continue;
        }

        if ($type === 'account_setup') {
            if ($role !== 'student' || $source !== 'students') {
                $skipped++;
                continue;
            }
            $alertId = 0;
        } else {
            if ($alertId < 1 || !pc_table_exists($conn, 'admin_security_alert_incidents')) {
                $skipped++;
                continue;
            }
            $check = pc_prepare(
                $conn,
                'SELECT 1 FROM admin_security_alert_incidents '
                    . 'WHERE alert_id = ? AND alert_type = ? AND account_role = ? '
                    . 'AND account_source = ? AND user_id = ? AND email_sent_at IS NULL LIMIT 1'
            );
            $check->bind_param('issss', $alertId, $type, $role, $source, $userId);
            $check->execute();
            $isPending = (bool)$check->get_result()->fetch_row();
            $check->close();
            if (!$isPending) {
                $skipped++;
                continue;
            }
        }

        $insert = pc_prepare(
            $conn,
            'INSERT IGNORE INTO admin_dashboard_alert_dismissals '
                . '(alert_type, account_role, account_source, user_id, alert_id) VALUES (?, ?, ?, ?, ?)'
        );
        $insert->bind_param('ssssi', $type, $role, $source, $userId, $alertId);
        $insert->execute();
        if ($insert->affected_rows === 1) {
            $dismissed++;
        } else {
            $skipped++;
        }
        $insert->close();
    }

    pc_respond([
        'status' => 'success',
        'dismissed' => $dismissed,
        'skipped' => $skipped,
    ]);
} catch (Throwable $e) {
    if ($e instanceof PasswordChangeClientException) {
        http_response_code(400);
        pc_respond(pc_client_error_payload($e->getMessage()));
    }
    error_log('Admin security alerts could not be deleted: ' . $e->getMessage());
    http_response_code(500);
    pc_respond(['status' => 'error', 'message' => 'The selected alerts could not be deleted.']);
}
