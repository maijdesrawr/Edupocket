<?php
header('Content-Type: application/json');

$servername = "localhost";
$username = "root";
$password = "R@wrah";
$database = "centraldb";

$conn = new mysqli($servername, $username, $password, $database);

if ($conn->connect_error) {
    echo json_encode([
        "status" => "error",
        "message" => "Database connection failed: " . $conn->connect_error
    ]);
    exit();
}

// Fetch all transactions
$query = "
    SELECT 
        t.id,
        s.Fname AS student_name,
        t.payment_title,
        t.amount,
        t.timestamp
    FROM transactions AS t
    LEFT JOIN students AS s 
        ON t.student_id = s.student_num
    ORDER BY t.timestamp DESC
";

$result = $conn->query($query);

if (!$result) {
    echo json_encode([
        "status" => "error",
        "message" => "Query failed: " . $conn->error
    ]);
    exit();
}

$transactions = [];
$totalBalance = 0.0;

while ($row = $result->fetch_assoc()) {
    $amount = floatval($row["amount"]);
    $totalBalance += $amount;

    $transactions[] = [
        "id" => $row["id"],
        "student_name" => $row["student_name"] ?: "N/A",
        "payment_title" => $row["payment_title"] ?: "Payment",
        "amount" => $amount,
        "timestamp" => $row["timestamp"]
    ];
}

echo json_encode([
    "status" => "success",
    "canteen_balance" => round($totalBalance, 2),
    "transactions" => $transactions
]);

$conn->close();
?>
