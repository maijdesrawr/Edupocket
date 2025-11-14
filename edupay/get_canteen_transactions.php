<?php
ob_start();
error_reporting(0);
ini_set('display_errors', 0);

header('Content-Type: application/json');

include 'db_connect.php';

if (!isset($_GET['canteen_id']) || empty($_GET['canteen_id'])) {
    ob_clean();
    echo json_encode([
        'status' => 'error',
        'message' => 'Missing canteen_id'
    ]);
    exit;
}

$canteen_id = $_GET['canteen_id'];

$stmt = $conn->prepare("SELECT canteen_id, Fname FROM canteens WHERE canteen_id=?");
$stmt->bind_param("s", $canteen_id);
$stmt->execute();
$canteen_result = $stmt->get_result();

if ($canteen_result->num_rows === 0) {
    ob_clean();
    echo json_encode([
        'status' => 'error',
        'message' => 'Canteen not found'
    ]);
    exit;
}

$canteen = $canteen_result->fetch_assoc();

$txn_stmt = $conn->prepare("
    SELECT t.transaction_id, t.student_num, s.Fname AS student_name,
           t.amount, t.description, t.date_time
    FROM transactions t
    JOIN students s ON t.student_num = s.student_num
    WHERE t.transaction_type IN ('top-up','payment')
    ORDER BY t.date_time DESC
    LIMIT 50
");
$txn_stmt->execute();
$txn_result = $txn_stmt->get_result();

$transactions = [];
$total_balance = 0;

while ($row = $txn_result->fetch_assoc()) {
    $transactions[] = [
        'id' => $row['transaction_id'],                  
        'recipientName' => $row['student_name'],
        'recipientNumber' => $row['student_num'],
        'amount' => floatval($row['amount']),
        'paymentTitle' => $row['description'] ?? '',
        'timestamp' => $row['date_time'],
        'isCompleted' => true
    ];
    $total_balance += floatval($row['amount']);
}

ob_clean();
echo json_encode([
    'status' => 'success',
    'role' => 'canteen',
    'id' => $canteen['canteen_id'],
    'name' => $canteen['Fname'],
    'balance' => number_format($total_balance, 2, '.', ''),
    'transactions' => $transactions
]);

$conn->close();
exit;
