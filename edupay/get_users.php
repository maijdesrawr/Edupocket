<?php
header('Content-Type: application/json');
include 'db_connect.php';

$category = $_GET['category'] ?? '';

try {
    $data = [];

    if ($category === 'student') {
        $query = $conn->query("
            SELECT s.student_num, s.Fname AS name, s.balance, p.Fname AS parent_name
            FROM students s
            LEFT JOIN parents p ON s.parent_id = p.parent_id
        ");
    } elseif ($category === 'parent') {
        $query = $conn->query("
            SELECT p.parent_id, p.Fname AS name, s.Fname AS student_name
            FROM parents p
            LEFT JOIN students s ON s.parent_id = p.parent_id
        ");
    } elseif ($category === 'pos') {
        $query = $conn->query("SELECT canteen_id, Fname AS name, location FROM canteens");
    } else {
        throw new Exception("Invalid category");
    }

    while ($row = $query->fetch_assoc()) {
        $data[] = $row;
    }

    echo json_encode([
        'status' => 'success',
        'data' => $data
    ]);
} catch (Exception $e) {
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage()
    ]);
}
?>
