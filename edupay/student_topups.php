<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");
include("db_connect.php");

if (!isset($_GET['student_id'])) {
    echo json_encode(["status" => "error", "message" => "Missing student_id parameter"]);
    exit;
}

$student_num = $_GET['student_id'];

$sql_topups = "
    SELECT amount, method, status, date_time
    FROM topups
    WHERE student_num = ?
    ORDER BY date_time DESC
";
$stmt = $conn->prepare($sql_topups);
$stmt->bind_param("s", $student_num);
$stmt->execute();
$result = $stmt->get_result();

$topups = [];
while ($row = $result->fetch_assoc()) {
    $topups[] = $row;
}
$stmt->close();

$sql_balance = "
    SELECT IFNULL(SUM(amount), 0) AS total_balance
    FROM topups
    WHERE student_num = ? AND status = 'Completed'
";
$stmt = $conn->prepare($sql_balance);
$stmt->bind_param("s", $student_num);
$stmt->execute();
$result = $stmt->get_result();
$row = $result->fetch_assoc();
$total_balance = $row['total_balance'] ?? 0;
$stmt->close();

$sql_expenses = "
    SELECT IFNULL(SUM(amount), 0) AS total_expenses
    FROM transactions
    WHERE student_num = ?
";
if ($stmt = $conn->prepare($sql_expenses)) {
    $stmt->bind_param("s", $student_num);
    $stmt->execute();
    $result = $stmt->get_result();
    $row = $result->fetch_assoc();
    $total_expenses = $row['total_expenses'] ?? 0;
    $stmt->close();
} else {
    $total_expenses = 0;
}

$conn->close();

echo json_encode([
    "status" => "success",
    "total_balance" => $total_balance,
    "total_expenses" => $total_expenses,
    "topups" => $topups
]);
?>
