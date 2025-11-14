<?php
header('Content-Type: application/json');

error_reporting(E_ALL);
ini_set('display_errors', 1);

include 'db_connect.php';

if (!$conn) {
    echo json_encode(['status' => 'error', 'message' => 'Database connection failed: ' . $conn->connect_error]);
    exit;
}

$parent_id = $_POST['parent_id'] ?? '';
$child_id = $_POST['child_id'] ?? '';
$amount = $_POST['amount'] ?? '';
$method = $_POST['method'] ?? 'Bank'; 

if (empty($parent_id) || empty($child_id) || empty($amount)) {
    echo json_encode(['status' => 'error', 'message' => 'Missing required fields']);
    exit;
}

if (!is_numeric($amount)) {
    echo json_encode(['status' => 'error', 'message' => 'Invalid amount']);
    exit;
}

$amount = floatval($amount); 

$verifyChild = $conn->prepare("
    SELECT * FROM parent_student_link 
    WHERE parent_id = ? AND student_num = ?
");

if (!$verifyChild) {
    echo json_encode(['status' => 'error', 'message' => 'Prepare failed (verify child): ' . $conn->error]);
    exit;
}

$verifyChild->bind_param("ss", $parent_id, $child_id);
$verifyChild->execute();
$result = $verifyChild->get_result();

if ($result->num_rows === 0) {
    echo json_encode(['status' => 'error', 'message' => 'This child is not linked to the parent.']);
    exit;
}

$verifyChild->close();

$transaction_type = 'top-up';
$description = 'Wallet Top-up';
$date_time = date('Y-m-d H:i:s');

$insertTransaction = $conn->prepare("
    INSERT INTO transactions (student_num, amount, transaction_type, description, date_time)
    VALUES (?, ?, ?, ?, ?)
");

if (!$insertTransaction) {
    echo json_encode(['status' => 'error', 'message' => 'Prepare failed (transactions): ' . $conn->error]);
    exit;
}

$insertTransaction->bind_param("sdsss", $child_id, $amount, $transaction_type, $description, $date_time);

if (!$insertTransaction->execute()) {
    echo json_encode(['status' => 'error', 'message' => 'Transaction insert failed: ' . $insertTransaction->error]);
    exit;
}

$insertTransaction->close();

$status = 'Completed';

$insertTopup = $conn->prepare("
    INSERT INTO topups (parent_id, student_num, amount, method, status, date_time)
    VALUES (?, ?, ?, ?, ?, ?)
");

if (!$insertTopup) {
    echo json_encode(['status' => 'error', 'message' => 'Prepare failed (topups): ' . $conn->error]);
    exit;
}

$insertTopup->bind_param("ssdsss", $parent_id, $child_id, $amount, $method, $status, $date_time);

if (!$insertTopup->execute()) {
    echo json_encode(['status' => 'error', 'message' => 'Top-up insert failed: ' . $insertTopup->error]);
    exit;
}

$insertTopup->close();

$updateBalance = $conn->prepare("
    UPDATE students SET balance = balance + ? WHERE student_num = ?
");

if (!$updateBalance) {
    echo json_encode(['status' => 'error', 'message' => 'Prepare failed (update balance): ' . $conn->error]);
    exit;
}

$updateBalance->bind_param("ds", $amount, $child_id);

if (!$updateBalance->execute()) {
    echo json_encode(['status' => 'error', 'message' => 'Balance update failed: ' . $updateBalance->error]);
    exit;
}

$updateBalance->close();

$getBalance = $conn->prepare("
    SELECT balance FROM students WHERE student_num = ?
");

if (!$getBalance) {
    echo json_encode(['status' => 'error', 'message' => 'Prepare failed (get balance): ' . $conn->error]);
    exit;
}

$getBalance->bind_param("s", $child_id);
$getBalance->execute();
$balanceResult = $getBalance->get_result();

if ($balanceResult->num_rows === 0) {
    echo json_encode(['status' => 'error', 'message' => 'Failed to fetch updated balance']);
    exit;
}

$row = $balanceResult->fetch_assoc();
$new_balance = floatval($row['balance']);
$getBalance->close();
$conn->close();

echo json_encode([
    'status' => 'success',
    'message' => 'Top-up successfully recorded and balance updated',
    'student_num' => $child_id,
    'amount' => $amount,
    'method' => $method,
    'new_balance' => $new_balance
]);
?>
