<?php
header('Content-Type: application/json; charset=utf-8');

ob_start();

ini_set('display_errors', 0);
ini_set('display_startup_errors', 0);
error_reporting(0);

set_error_handler(function($errno, $errstr) {
    echo json_encode(['status'=>'error','message'=>$errstr]);
    exit;
});

$host = "localhost";
$user = "root";
$pass = "R@wrah";
$dbname = "centraldb";

$conn = new mysqli($host, $user, $pass, $dbname);

if ($conn->connect_error) {
    echo json_encode(['status'=>'error','message'=>'Database connection failed']);
    exit;
}

$student_num = isset($_POST['student_num']) ? trim($_POST['student_num']) : '';
$pin = isset($_POST['pin']) ? trim($_POST['pin']) : '';
$amount = isset($_POST['amount']) ? floatval($_POST['amount']) : 0;
$description = isset($_POST['description']) ? trim($_POST['description']) : '';

if (empty($student_num) || empty($pin) || $amount <= 0) {
    echo json_encode(['status'=>'error','message'=>'Missing required fields']);
    exit;
}

$stmt = $conn->prepare("SELECT balance, pin FROM students WHERE student_num=?");
$stmt->bind_param("s", $student_num);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    echo json_encode(['status'=>'error','message'=>'Student not found']);
    exit;
}

$row = $result->fetch_assoc();

if ($row['pin'] !== $pin) {
    echo json_encode(['status'=>'error','message'=>'Invalid PIN']);
    exit;
}

$current_balance = floatval($row['balance']);
if ($current_balance < $amount) {
    echo json_encode(['status'=>'error','message'=>'Insufficient balance']);
    exit;
}

$new_balance = $current_balance - $amount;
$update_stmt = $conn->prepare("UPDATE students SET balance=? WHERE student_num=?");
$update_stmt->bind_param("ds", $new_balance, $student_num);
$update_stmt->execute();

$txn_stmt = $conn->prepare("INSERT INTO transactions (student_num, amount, description, date_created) VALUES (?, ?, ?, NOW())");
$txn_stmt->bind_param("sds", $student_num, $amount, $description);
$txn_stmt->execute();

echo json_encode([
    'status' => 'success',
    'new_balance' => number_format($new_balance, 2)
]);

ob_end_flush();
exit;
