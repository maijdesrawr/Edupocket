<?php
header('Content-Type: application/json');
include 'db_connect.php';

$parent_id = $_GET['parent_id'] ?? '';

if (empty($parent_id)) {
    echo json_encode(['status' => 'error', 'message' => 'Missing parent_id']);
    exit;
}

$children_query = $conn->prepare("
    SELECT DISTINCT 
        s.student_num AS child_id,   
        s.Fname AS child_name, 
        s.balance,
        COALESCE(SUM(CASE WHEN t.transaction_type = 'payment' THEN t.amount ELSE 0 END), 0) AS expense
    FROM parent_student_link l
    INNER JOIN students s ON l.student_num = s.student_num
    LEFT JOIN transactions t ON s.student_num = t.student_num
    WHERE l.parent_id = ?
    GROUP BY s.student_num
");
$children_query->bind_param('s', $parent_id);
$children_query->execute();
$children_result = $children_query->get_result();

$children = [];
$total_balance = 0;
$total_expense = 0;

while ($row = $children_result->fetch_assoc()) {
    $row['balance'] = (float)$row['balance'];
    $row['expense'] = (float)$row['expense'];

    $total_balance += $row['balance'];
    $total_expense += $row['expense'];
    $children[] = $row;
}

$activity_query = $conn->prepare("
    SELECT 
        s.student_num AS child_id,   
        s.Fname AS name,
        CONCAT('₱', FORMAT(t.amount, 2)) AS amount,
        DATE(t.date_time) AS date,
        CASE
            WHEN t.transaction_type = 'top-up' THEN 'Top-Up (Completed)'
            ELSE t.description
        END AS note
    FROM transactions t
    INNER JOIN students s ON t.student_num = s.student_num
    INNER JOIN parent_student_link l ON s.student_num = l.student_num
    WHERE l.parent_id = ?
    ORDER BY t.date_time DESC
    LIMIT 50                   
");
$activity_query->bind_param('s', $parent_id);
$activity_query->execute();
$activity_result = $activity_query->get_result();

$activities = [];
while ($row = $activity_result->fetch_assoc()) {
    $activities[] = $row;
}

echo json_encode([
    'status' => 'success',
    'total_balance' => $total_balance,
    'total_expense' => $total_expense,
    'children' => $children,
    'activities' => $activities
], JSON_UNESCAPED_UNICODE);
?>
