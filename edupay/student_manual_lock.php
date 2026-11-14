
<?php

header('Content-Type: application/json');

require_once __DIR__ . '/admin_account_common.php';

try {
    if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') {
        throw new InvalidArgumentException('POST is required.');
    }

    $session = account_admin($conn);

    $studentNum = trim((string)($_POST['student_num'] ?? ''));
    $action = trim((string)($_POST['action'] ?? ''));

    if ($studentNum === '') {
        throw new InvalidArgumentException('Student number is required.');
    }

    if (!in_array($action, ['lock', 'unlock'], true)) {
        throw new InvalidArgumentException('Invalid account action.');
    }

    $conn->begin_transaction();

    $result = account_query(
        $conn,
        'SELECT student_num, is_locked FROM students WHERE student_num = ? FOR UPDATE',
        [$studentNum]
    );

    $student = $result->get_result()->fetch_assoc();

    if (!$student) {
        throw new InvalidArgumentException('Student account not found.');
    }

    $newStatus = $action === 'lock' ? 1 : 0;

    if ($action === 'unlock') {
        account_query(
            $conn,
            'UPDATE students SET is_locked = 0, failed_attempts = 0 WHERE student_num = ?',
            [$studentNum]
        );
    } else {
        account_query(
            $conn,
            'UPDATE students SET is_locked = 1 WHERE student_num = ?',
            [$studentNum]
        );
    }

    $event = $action === 'lock'
        ? 'student_account_manually_locked'
        : 'student_account_manually_unlocked';

    as_record_activity(
        $conn,
        $session,
        $event,
        [
            'student_num' => $studentNum,
            'previous_status' => (int)$student['is_locked'],
            'new_status' => $newStatus
        ],
        'server'
    );

    $conn->commit();

    echo json_encode([
        'status' => 'success',
        'message' => $action === 'lock'
            ? 'Student account locked successfully.'
            : 'Student account unlocked successfully.',
        'is_locked' => $newStatus
    ]);

} catch (Throwable $e) {

    if ($conn->errno === 0 || $conn->errno > 0) {
        try {
            $conn->rollback();
        } catch (Throwable $rollbackError) {
            error_log('Rollback failed: ' . $rollbackError->getMessage());
        }
    }

    error_log('Student manual lock failed: ' . $e->getMessage());

    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage()
    ]);
}
