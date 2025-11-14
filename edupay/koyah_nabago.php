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
$id = $_POST['id'] ?? '';

if (empty($category) || empty($id)) {
    echo json_encode(['status' => 'error', 'message' => 'Category and ID are required']);
    exit;
}

function sanitize($conn, $value) {
    return mysqli_real_escape_string($conn, trim($value));
}

$response = ['status' => 'error', 'message' => 'Unknown error'];

switch ($category) {
    case 'student':
    $Fname = sanitize($conn, $_POST['Fname'] ?? '');
    $parent_id = trim(sanitize($conn, $_POST['linked_id'] ?? '')); // trim whitespace
    $password = sanitize($conn, $_POST['password'] ?? '');
    $pin = sanitize($conn, $_POST['pin'] ?? '');

    if (empty($Fname)) {
        $response['message'] = 'Name is required';
        break;
    }

    $parent_sql = !empty($parent_id) ? "'$parent_id'" : "NULL";
    $pass_sql = !empty($password) ? "'$password'" : null;
    $pin_sql = !empty($pin) ? "'$pin'" : null;

    $sql = "UPDATE students SET Fname='$Fname', parent_id=$parent_sql"
         . (!empty($password) ? ", Password=$pass_sql" : "")
         . (!empty($pin) ? ", pin=$pin_sql" : "")
         . " WHERE student_num='$id'";

    if (mysqli_query($conn, $sql)) {
        $response = ['status' => 'success', 'message' => 'Student updated successfully'];

        mysqli_query($conn, "DELETE FROM parent_student_link WHERE student_num='$id'");

        if (!empty($parent_id)) {
            $checkParent = mysqli_query($conn, "SELECT parent_id FROM parents WHERE parent_id='$parent_id'");
            if (mysqli_num_rows($checkParent) > 0) {
                $link_sql = "INSERT INTO parent_student_link (parent_id, student_num) VALUES ('$parent_id', '$id')";
                mysqli_query($conn, $link_sql);
            } else {
                file_put_contents('debug_parent_link.txt', "Parent ID '$parent_id' does not exist\n", FILE_APPEND);
            }
        }

    } else {
        $response['message'] = mysqli_error($conn);
    }
    break;


    case 'parent':
        $Fname = sanitize($conn, $_POST['Fname'] ?? '');
        $linked_student_num = sanitize($conn, $_POST['linked_id'] ?? '');
        $password = sanitize($conn, $_POST['password'] ?? '');

        if (empty($Fname)) {
            $response['message'] = 'Name is required';
            break;
        }

        $linked_sql = !empty($linked_student_num) ? "'$linked_student_num'" : "NULL";

        $sql = "UPDATE parents SET Fname='$Fname', linked_student_num=$linked_sql"
             . (!empty($password) ? ", Password='$password'" : "")
             . " WHERE parent_id='$id'";

        if (mysqli_query($conn, $sql)) {
            $response = ['status' => 'success', 'message' => 'Parent updated successfully'];
        } else {
            $response['message'] = mysqli_error($conn);
        }
        break;

    case 'pos':
        $Fname = sanitize($conn, $_POST['Fname'] ?? '');
        $location = sanitize($conn, $_POST['location'] ?? '');
        $password = sanitize($conn, $_POST['password'] ?? '');

        if (empty($Fname)) {
            $response['message'] = 'Canteen Name is required';
            break;
        }

        $location_sql = !empty($location) ? "'$location'" : "NULL";

        $sql = "UPDATE canteens SET Fname='$Fname', location=$location_sql"
             . (!empty($password) ? ", Password='$password'" : "")
             . " WHERE canteen_id='$id'";

        if (mysqli_query($conn, $sql)) {
            $response = ['status' => 'success', 'message' => 'POS updated successfully'];
        } else {
            $response['message'] = mysqli_error($conn);
        }
        break;

    default:
        $response['message'] = 'Invalid category';
        break;
}

echo json_encode($response);
?>
