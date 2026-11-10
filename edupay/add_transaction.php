<?php
header('Content-Type: application/json');
include 'db_connect.php';
require_once __DIR__ . '/app_session_common.php';

$appSession = as_require_session($conn, false);
$processor_role = strtolower(trim((string)($appSession['role'] ?? '')));
$processor_account_source = strtolower(trim(
    (string)($appSession['account_source'] ?? '')
));
$processor_id = trim((string)($appSession['user_id'] ?? ''));

$student_num = $_POST['student_num'] ?? '';
$amount = $_POST['amount'] ?? '';
$transaction_type = $_POST['transaction_type'] ?? 'Top-Up';
$description = $_POST['description'] ?? 'Wallet Top-Up';

if (empty($student_num) || empty($amount)) {
    echo json_encode(['status' => 'error', 'message' => 'Missing required fields']);
    exit;
}

$stmt = $conn->prepare("
    INSERT INTO transactions
        (student_num, amount, transaction_type, description,
         processor_role, processor_account_source, processor_id, date_time)
    VALUES (?, ?, ?, ?, ?, ?, ?, NOW())
");
$stmt->bind_param(
    "sdsssss",
    $student_num,
    $amount,
    $transaction_type,
    $description,
    $processor_role,
    $processor_account_source,
    $processor_id
);

if ($stmt->execute()) {
    echo json_encode(['status' => 'success', 'message' => 'Transaction recorded successfully']);
} else {
    echo json_encode(['status' => 'error', 'message' => 'Failed to record transaction']);
}

$stmt->close();
$conn->close();
?>
