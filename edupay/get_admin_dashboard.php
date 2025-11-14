<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

include 'db_connect.php';

if (!$conn) {
    echo json_encode(["error" => "Database connection failed"]);
    exit;
}

$total_users_query = $conn->query("SELECT COUNT(*) as total_users FROM students");
$total_users = $total_users_query ? $total_users_query->fetch_assoc()['total_users'] : 0;

$total_balance_query = $conn->query("SELECT SUM(balance) as total_balance FROM students");
$total_balance = $total_balance_query ? $total_balance_query->fetch_assoc()['total_balance'] : 0;

$activity_query = $conn->query("
  SELECT s.Fname AS title,
         t.transaction_type AS subtitle,
         CONCAT(
            IF(t.transaction_type='top-up','+','-'),
            '₱', FORMAT(t.amount,2)
         ) AS amount
  FROM transactions t
  JOIN students s ON s.student_num = t.student_num
  ORDER BY t.date_time DESC
  LIMIT 10
");

$activities = [];
if ($activity_query) {
    while($row = $activity_query->fetch_assoc()) {
        $activities[] = $row;
    }
}

echo json_encode([
  'total_users' => $total_users,
  'total_balance' => $total_balance,
  'activities' => $activities
]);
?>
