<?php
header('Content-Type: application/json');
$host = "localhost";
$user = "root";
$pass = "R@wrah";
$db = "centraldb";

$conn = new mysqli($host, $user, $pass, $db);

if ($conn->connect_error) {
    die(json_encode(["status" => "error", "message" => "DB connection failed"]));
}

$student_id = $_GET['student_id'] ?? '';
$filter = $_GET['filter'] ?? 'Monthly';

if (empty($student_id)) {
    echo json_encode(["status" => "error", "message" => "Missing student_id"]);
    exit;
}

$query = "SELECT * FROM transactions WHERE student_num = ?";

switch (strtolower($filter)) {
    case 'daily':
        $query .= " AND DATE(date_time) = CURDATE()";
        break;
    case 'weekly':
        $query .= " AND YEARWEEK(date_time, 1) = YEARWEEK(CURDATE(), 1)";
        break;
    case 'monthly':
    default:
        $query .= " AND MONTH(date_time) = MONTH(CURDATE()) 
                    AND YEAR(date_time) = YEAR(CURDATE())";
        break;
}

$query .= " ORDER BY date_time DESC";

$stmt = $conn->prepare($query);
$stmt->bind_param("s", $student_id);
$stmt->execute();
$result = $stmt->get_result();

$transactions = [];
$total_expense = 0;
$total_balance = 0;

$balance_query = $conn->prepare("SELECT balance FROM students WHERE student_num = ?");
$balance_query->bind_param("s", $student_id);
$balance_query->execute();
$balance_result = $balance_query->get_result();
if ($row = $balance_result->fetch_assoc()) {
    $total_balance = (float)$row['balance'];
}

while ($row = $result->fetch_assoc()) {
    $transactions[] = $row;

    if ($row['transaction_type'] === 'payment') {
        $total_expense += (float)$row['amount'];
    }
}

echo json_encode([
    "status" => "success",
    "total_balance" => $total_balance,
    "total_expense" => $total_expense,
    "transactions" => $transactions
]);

$conn->close();
?>
