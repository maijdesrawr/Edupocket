<?php
header('Content-Type: application/json');
include 'db_connect.php'; 

$student_num = $_GET['student_num'] ?? '';
$filter = $_GET['filter'] ?? 'Monthly'; 

if (!$student_num) {
    echo json_encode(['status' => 'error', 'message' => 'Student ID missing']);
    exit;
}

switch ($filter) {
    case 'Daily':
        $sql = "
            SELECT DATE(date_time) AS label,
                   SUM(CASE WHEN transaction_type='top-up' THEN amount ELSE 0 END) AS topup,
                   SUM(CASE WHEN transaction_type='payment' THEN amount ELSE 0 END) AS expense
            FROM transactions
            WHERE student_num = ?
            GROUP BY DATE(date_time)
            ORDER BY DATE(date_time)
        ";
        break;

    case 'Weekly':
        $sql = "
            SELECT DATE_SUB(date_time, INTERVAL WEEKDAY(date_time) DAY) AS label,
                   SUM(CASE WHEN transaction_type='top-up' THEN amount ELSE 0 END) AS topup,
                   SUM(CASE WHEN transaction_type='payment' THEN amount ELSE 0 END) AS expense
            FROM transactions
            WHERE student_num = ?
            GROUP BY DATE_SUB(date_time, INTERVAL WEEKDAY(date_time) DAY)
            ORDER BY DATE_SUB(date_time, INTERVAL WEEKDAY(date_time) DAY)
        ";
        break;

    case 'Monthly':
        $sql = "
            SELECT DATE_FORMAT(date_time, '%b %Y') AS label,
                   SUM(CASE WHEN transaction_type='top-up' THEN amount ELSE 0 END) AS topup,
                   SUM(CASE WHEN transaction_type='payment' THEN amount ELSE 0 END) AS expense
            FROM transactions
            WHERE student_num = ?
            GROUP BY YEAR(date_time), MONTH(date_time)
            ORDER BY YEAR(date_time), MONTH(date_time)
        ";
        break;

    case 'Yearly':
        $sql = "
            SELECT YEAR(date_time) AS label,
                   SUM(CASE WHEN transaction_type='top-up' THEN amount ELSE 0 END) AS topup,
                   SUM(CASE WHEN transaction_type='payment' THEN amount ELSE 0 END) AS expense
            FROM transactions
            WHERE student_num = ?
            GROUP BY YEAR(date_time)
            ORDER BY YEAR(date_time)
        ";
        break;

    default:
        echo json_encode(['status' => 'error', 'message' => 'Invalid filter']);
        exit;
}

try {
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("s", $student_num);
    $stmt->execute();
    $result = $stmt->get_result();

    $data = [];
    while ($row = $result->fetch_assoc()) {
        $data[] = [
            'label' => $row['label'],
            'topup' => (float)$row['topup'],
            'expense' => (float)$row['expense']
        ];
    }

    echo json_encode(['status' => 'success', 'data' => $data]);
    $stmt->close();
    $conn->close();
} catch (mysqli_sql_exception $e) {
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage()
    ]);
}
?>
