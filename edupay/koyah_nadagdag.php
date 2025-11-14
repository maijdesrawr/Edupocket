<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Content-Type: application/json');
include 'db_connect.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(['status' => 'error', 'message' => 'Invalid request method']);
    exit;
}

$category = $_POST['category'] ?? '';

if (empty($category)) {
    echo json_encode(['status' => 'error', 'message' => 'Category is required']);
    exit;
}

function sanitize($conn, $value) {
    return mysqli_real_escape_string($conn, trim($value));
}

file_put_contents('debug_add_user.txt', print_r($_POST, true), FILE_APPEND);

$response = ['status' => 'error', 'message' => 'Unknown error'];

switch ($category) {
case 'student':
    $name = sanitize($conn, $_POST['name'] ?? '');
    $student_num = sanitize($conn, $_POST['student_num'] ?? '');
    $parent_id = sanitize($conn, $_POST['parent_id'] ?? '');
    $balance = isset($_POST['balance']) ? floatval($_POST['balance']) : 0.00;
    $password = $_POST['password'] ?? ''; 

    $qr_code = 'QR_' . $student_num;

    if (empty($name) || empty($student_num)) {
        $response['message'] = 'Name and Student Number are required';
        break;
    }

    $sql = "INSERT INTO students (student_num, Fname, Password, balance, parent_id, qr_code)
            VALUES ('$student_num', '$name', '$password', $balance, '$parent_id', '$qr_code')";

    if (mysqli_query($conn, $sql)) {

        if (!empty($parent_id)) {
            $link_sql = "INSERT INTO parent_student_link (parent_id, student_num)
                         VALUES ('$parent_id', '$student_num')";
            mysqli_query($conn, $link_sql);
        }

        $response = ['status' => 'success', 'message' => 'Student added successfully'];
    } else {
        $response['message'] = mysqli_error($conn);
    }
    break;


case 'parent':
    $name = sanitize($conn, $_POST['name'] ?? '');
    $parent_id = sanitize($conn, $_POST['parent_id'] ?? '');
    $linked_student = sanitize($conn, $_POST['linked_student'] ?? '');
    $email = sanitize($conn, $_POST['email'] ?? '');
    $password = sanitize($conn, $_POST['password'] ?? '');

    if (empty($name) || empty($parent_id) || empty($email) || empty($password)) {
        $response['message'] = 'Name, Parent ID, Email, and Password are required';
        break;
    }

    $linked_student_sql = "NULL";
    if (!empty($linked_student)) {
        $check = mysqli_query($conn, "SELECT student_num FROM students WHERE student_num='$linked_student'");
        if (mysqli_num_rows($check) > 0) {
            $linked_student_sql = "'$linked_student'";
        }
    }

    $sql = "INSERT INTO parents (parent_id, Fname, Password, email, linked_student_num)
            VALUES ('$parent_id', '$name', '$password', '$email', $linked_student_sql)";

    if (mysqli_query($conn, $sql)) {
        $response = ['status' => 'success', 'message' => 'Parent added successfully'];
    } else {
        $response['message'] = mysqli_error($conn);
    }
    break;




case 'pos':
    $name = sanitize($conn, $_POST['name'] ?? '');
    $canteen_id = sanitize($conn, $_POST['canteen_id'] ?? '');
    $location = sanitize($conn, $_POST['location'] ?? '');
    $password = sanitize($conn, $_POST['password'] ?? '');

    if (empty($name) || empty($canteen_id) || empty($password)) {
        $response['message'] = 'Canteen Name, ID, and Password are required';
        break;
    }

    $sql = "INSERT INTO canteens (canteen_id, Fname, Password, location)
            VALUES ('$canteen_id', '$name', '$password', '$location')";

    if (mysqli_query($conn, $sql)) {
        $response = ['status' => 'success', 'message' => 'POS added successfully'];
    } else {
        $response['message'] = mysqli_error($conn);
    }
    break;

}

echo json_encode($response);
?>
