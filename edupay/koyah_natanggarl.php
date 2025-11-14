<?php
header('Content-Type: application/json');
include 'db_connect.php';

$category = $_POST['category'] ?? '';
$id = $_POST['id'] ?? '';

if (empty($category) || empty($id)) {
    echo json_encode(['status' => 'error', 'message' => 'Category or ID missing']);
    exit;
}

try {
    $conn->begin_transaction();

    switch ($category) {
        case 'student':
            // Delete dependent records first
            $conn->query("DELETE FROM transactions WHERE student_num = '$id'");
            $conn->query("DELETE FROM topups WHERE student_num = '$id'");
            $conn->query("DELETE FROM parent_student_link WHERE student_num = '$id'");
            // Delete student
            $stmt = $conn->query("DELETE FROM students WHERE student_num = '$id'");
            break;

        case 'parent':
            $conn->query("DELETE FROM topups WHERE parent_id = '$id'");
            $conn->query("DELETE FROM parent_student_link WHERE parent_id = '$id'");
            // Delete parent
            $stmt = $conn->query("DELETE FROM parents WHERE parent_id = '$id'");
            break;

        case 'pos':
            $stmt = $conn->query("DELETE FROM canteens WHERE canteen_id = '$id'");
            break;

        default:
            throw new Exception("Invalid category");
    }

    $conn->commit();

    if ($conn->affected_rows > 0) {
        echo json_encode(['status' => 'success', 'message' => 'User deleted successfully']);
    } else {
        echo json_encode(['status' => 'error', 'message' => 'User not found']);
    }
} catch (Exception $e) {
    $conn->rollback();
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
