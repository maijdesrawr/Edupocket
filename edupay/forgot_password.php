<?php

declare(strict_types=1);

require_once __DIR__ . '/password_change_common.php';
require_once __DIR__ . '/email_verification_common.php';

pc_bootstrap_json_endpoint();

function fp_reply(array $payload): void
{
    pc_respond($payload);
}

try {
    pc_require_post();
    $action = pc_post_string('action');
    $config = pc_security_config();
    $conn = pc_open_database();
    ev_require_schema($conn);
    if (!pc_table_exists($conn, 'forgot_password_challenges')) {
        throw new RuntimeException('Forgot-password migration is missing.');
    }

    if ($action === 'send_otp') {
        $email = ev_normalize_email(pc_post_string('email'));
        $fingerprint = ev_email_fingerprint($email, $config);
        $lookup = pc_prepare(
            $conn,
            'SELECT role, account_source, user_id FROM account_verified_emails '
                . 'WHERE email_fingerprint = ? LIMIT 1'
        );
        $lookup->bind_param('s', $fingerprint);
        $lookup->execute();
        $account = $lookup->get_result()->fetch_assoc();
        $lookup->close();
        if (!is_array($account)) {
            pc_reject('Enter a registered email address.');
        }

        $role = pc_normalize_role((string)$account['role']);
        $source = (string)$account['account_source'];
        $userId = (string)$account['user_id'];
        $registered = ev_verified_email_record($conn, $role, $source, $userId);
        if (!is_array($registered)) {
            pc_reject('The registered email address could not be verified.');
        }
        $actualEmail = ev_decrypt_verified_email(
            (string)$registered['email_encrypted'], $role, $source, $userId, $config
        );
        if (!hash_equals($email, $actualEmail)) {
            pc_reject('The registered email address could not be verified.');
        }

        $accountRateHash = ev_rate_scope_hash('forgot-email' . "\0" . $fingerprint, $config);
        $ipHash = ev_remote_ip_hash($config);
        ev_consume_rate_limit($conn, 'preauth_account', $accountRateHash, 3, 900);
        ev_consume_rate_limit($conn, 'preauth_ip', $ipHash, 20, 3600);

        $cancel = pc_prepare(
            $conn,
            "UPDATE forgot_password_challenges SET status = 'expired' "
                . "WHERE role = ? AND account_source = ? AND user_id = ? AND status IN ('pending', 'verified')"
        );
        $cancel->bind_param('sss', $role, $source, $userId);
        $cancel->execute();
        $cancel->close();

        $token = pc_new_challenge_token();
        $code = pc_generate_email_otp();
        $otpHash = pc_email_otp_hash($token['hash'], $code, $config);
        $insert = pc_prepare(
            $conn,
            "INSERT INTO forgot_password_challenges "
                . '(challenge_token_hash, role, account_source, user_id, otp_hash, expires_at) '
                . "VALUES (?, ?, ?, ?, ?, DATE_ADD(NOW(6), INTERVAL 5 MINUTE))"
        );
        $insert->bind_param('sssss', $token['hash'], $role, $source, $userId, $otpHash);
        $insert->execute();
        $insert->close();
        if (!pc_send_email_otp($config, $email, $code, [
            'purpose' => 'forgot_password',
            'role' => $role,
            'user_id' => $userId,
        ])) {
            pc_reject('The verification code could not be sent. Please try again later.');
        }
        fp_reply(['status' => 'success', 'challenge_token' => $token['token']]);
    }

    $token = pc_post_string('challenge_token');
    $tokenHash = pc_challenge_token_hash($token);
    if ($action === 'verify_otp') {
        $code = pc_post_string('code');
        $challenge = pc_prepare(
            $conn,
            'SELECT challenge_id, otp_hash, failed_attempts, status, '
                . '(expires_at <= NOW(6)) AS expired FROM forgot_password_challenges '
                . 'WHERE challenge_token_hash = ? LIMIT 1'
        );
        $challenge->bind_param('s', $tokenHash);
        $challenge->execute();
        $row = $challenge->get_result()->fetch_assoc();
        $challenge->close();
        if (!is_array($row) || $row['status'] !== 'pending' || (int)$row['expired'] === 1) {
            pc_reject('This verification code expired. Request a new one.');
        }
        $valid = preg_match('/^\d{6}$/', $code) === 1
            && hash_equals((string)$row['otp_hash'], pc_email_otp_hash($tokenHash, $code, $config));
        if (!$valid) {
            $attempts = (int)$row['failed_attempts'] + 1;
            $status = $attempts >= 5 ? 'failed' : 'pending';
            $update = pc_prepare(
                $conn,
                'UPDATE forgot_password_challenges SET failed_attempts = ?, status = ? WHERE challenge_id = ?'
            );
            $challengeId = (int)$row['challenge_id'];
            $update->bind_param('isi', $attempts, $status, $challengeId);
            $update->execute();
            $update->close();
            pc_reject($attempts >= 5
                ? 'Too many incorrect attempts. Request a new verification code.'
                : 'The verification code is incorrect.');
        }
        $challengeId = (int)$row['challenge_id'];
        $update = pc_prepare(
            $conn,
            "UPDATE forgot_password_challenges SET status = 'verified', verified_at = NOW(6) "
                . 'WHERE challenge_id = ? AND status = \'pending\''
        );
        $update->bind_param('i', $challengeId);
        $update->execute();
        $update->close();
        fp_reply(['status' => 'success']);
    }

    if ($action === 'reset_password') {
        $newPassword = pc_post_string('password', false);
        pc_validate_strong_password($newPassword);
        if (!$conn->begin_transaction()) {
            throw new RuntimeException('Password reset could not start.');
        }
        $statement = pc_prepare(
            $conn,
            "SELECT role, account_source, user_id FROM forgot_password_challenges "
                . "WHERE challenge_token_hash = ? AND status = 'verified' "
                . 'AND verified_at > DATE_SUB(NOW(6), INTERVAL 10 MINUTE) FOR UPDATE'
        );
        $statement->bind_param('s', $tokenHash);
        $statement->execute();
        $account = $statement->get_result()->fetch_assoc();
        $statement->close();
        if (!is_array($account)) {
            $conn->rollback();
            pc_reject('Verify your email code again before resetting the password.');
        }
        $role = pc_normalize_role((string)$account['role']);
        $source = (string)$account['account_source'];
        $userId = (string)$account['user_id'];
        $current = pc_fetch_account_for_update($conn, $role, $userId, $source);
        pc_assert_password_not_reused(
            $conn, $role, $source, $userId, $newPassword, (string)$current['password_value']
        );
        $newHash = pc_hash_password($newPassword);
        $oldHash = pc_is_password_hash((string)$current['password_value'])
            ? (string)$current['password_value']
            : pc_hash_password((string)$current['password_value']);
        pc_record_password_history($conn, $role, $source, $userId, $oldHash);
        pc_record_password_history($conn, $role, $source, $userId, $newHash);
        pc_update_account_password($conn, $role, $source, $userId, $newHash);
        $revoke = pc_prepare(
            $conn,
            "UPDATE app_sessions SET revoked_at = COALESCE(revoked_at, NOW(6)), "
                . "revocation_reason = CASE WHEN revoked_at IS NULL THEN 'password_reset' ELSE revocation_reason END "
                . 'WHERE role = ? AND account_source = ? AND user_id = ?'
        );
        $revoke->bind_param('sss', $role, $source, $userId);
        $revoke->execute();
        $revoke->close();
        $release = pc_prepare(
            $conn,
            'UPDATE app_session_accounts SET current_session_id = NULL '
                . 'WHERE role = ? AND account_source = ? AND user_id = ?'
        );
        $release->bind_param('sss', $role, $source, $userId);
        $release->execute();
        $release->close();
        $used = pc_prepare(
            $conn,
            "UPDATE forgot_password_challenges SET status = 'used' "
                . 'WHERE challenge_token_hash = ?'
        );
        $used->bind_param('s', $tokenHash);
        $used->execute();
        $used->close();
        $conn->commit();
        fp_reply(['status' => 'success']);
    }

    pc_reject('Unknown password recovery action.');
} catch (PasswordChangeClientException $error) {
    fp_reply(['status' => 'error', 'message' => $error->getMessage()]);
} catch (Throwable $error) {
    error_log('forgot_password.php failed: ' . $error->getMessage());
    if (isset($conn) && $conn instanceof mysqli) {
        @$conn->rollback();
    }
    fp_reply(['status' => 'error', 'message' => 'Password recovery could not be completed.']);
}
