<?php

declare(strict_types=1);

require_once __DIR__ . '/receipt_print_token_common.php';

pc_bootstrap_json_endpoint();
header('Access-Control-Allow-Methods: GET, OPTIONS');

$conn = null;
$payload = null;
try {
    if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'GET') {
        http_response_code(405);
        pc_reject('GET is required.');
    }

    $conn = pc_open_database();
    $session = as_require_session($conn);
    as_assert_session_role($session, ['admin']);

    $sql = "SELECT t.transaction_id, t.student_num, COALESCE(NULLIF(TRIM(CONCAT_WS(' ', NULLIF(s.first_name, ''), NULLIF(s.last_name, ''))), ''), s.Fname) AS student_name, "
        . 't.description AS note, t.amount, t.transaction_type, '
        . 'COALESCE(t.date_time, t.date_created) AS event_time '
        . 'FROM transactions t '
        . 'LEFT JOIN students s ON t.student_num = s.student_num '
        . 'ORDER BY COALESCE(t.date_time, t.date_created) DESC, t.transaction_id DESC';
    $result = $conn->query($sql);
    if (!$result instanceof mysqli_result) {
        throw new RuntimeException('Transaction records could not be loaded.');
    }

    $transactions = [];
    while ($row = $result->fetch_assoc()) {
        $noteWithoutMiddle = receipt_transfer_detail_without_middle(
            $conn,
            (string)($row['note'] ?? '')
        );
        $transactions[] = [
            'id' => (int)($row['transaction_id'] ?? 0),
            'transaction_id' => (int)($row['transaction_id'] ?? 0),
            'name' => receipt_mask_account_name(
                $conn,
                'students',
                (string)($row['student_num'] ?? ''),
                (string)($row['student_name'] ?? '')
            ),
            'note' => receipt_mask_transfer_detail_for_display($conn, $noteWithoutMiddle),
            'amount' => $row['amount'] ?? '0',
            'date' => (string)($row['event_time'] ?? ''),
            'type' => (string)($row['transaction_type'] ?? ''),
        ];
    }
    $result->free();

    as_record_activity(
        $conn,
        $session,
        'admin_transactions_viewed',
        ['transaction_count' => count($transactions)]
    );
    $payload = ['status' => 'success', 'transactions' => $transactions];
} catch (PasswordChangeClientException $error) {
    if (http_response_code() < 400) {
        http_response_code(400);
    }
    $payload = pc_client_error_payload($error->getMessage(), $error->details());
} catch (Throwable $error) {
    error_log('get_all_transactions.php failed: ' . $error->getMessage());
    http_response_code(500);
    $payload = pc_client_error_payload('Transaction records could not be loaded.');
} finally {
    if ($conn instanceof mysqli) {
        $conn->close();
    }
}

pc_respond(is_array($payload) ? $payload : pc_client_error_payload('The request failed.'));
