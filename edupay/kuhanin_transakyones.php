<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *'); // Allow Flutter requests

// Include your existing database connection
include 'db_connect.php'; // replace with your actual connection file

// Fetch all transactions with student info
$sql = "
    SELECT 
        t.transaction_id,
        t.amount,
        t.transaction_type,
        t.description,
        t.date_time,
        s.Fname AS student_name,
        s.student_num
    FROM transactions t
    JOIN students s ON t.student_num = s.student_num
    ORDER BY t.date_time DESC
";

$result = $conn->query($sql);

$transactions = [];
while ($row = $result->fetch_assoc()) {
    $transactions[] = [
        "id" => $row['transaction_id'],
        "recipientName" => $row['student_name'],
        "recipientNumber" => $row['student_num'],
        "paymentTitle" => ucfirst($row['transaction_type']), // Payment or Top-up
        "amount" => floatval($row['amount']),
        "timestamp" => $row['date_time'],
        "isCompleted" => true // you can later add logic if needed
    ];
}

echo json_encode(["status" => "success", "data" => $transactions]);
?>
