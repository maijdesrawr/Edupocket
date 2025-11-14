<?php
header("Content-Type: application/json");
include "db_connect.php"; 

$id = $_POST['id'] ?? '';
$password = $_POST['password'] ?? '';

if (empty($id) || empty($password)) {
    echo json_encode([
        "status" => "error",
        "message" => "Missing ID or password"
    ]);
    exit();
}

$tables = [
    "students" => ["id_field" => "student_num", "password_field" => "password", "role" => "student"],
    "parents" => ["id_field" => "parent_id", "password_field" => "password", "role" => "parent"],
    "admins" => ["id_field" => "admin_id", "password_field" => "password", "role" => "admin"],
    "canteens" => ["id_field" => "canteen_id", "password_field" => "password", "role" => "canteen"]
];

foreach ($tables as $table => $info) {
    $query = "SELECT {$info['id_field']} AS id, Fname 
              FROM $table 
              WHERE {$info['id_field']} = '$id' 
              AND {$info['password_field']} = '$password' 
              LIMIT 1";
    $result = mysqli_query($conn, $query);

    if ($result && mysqli_num_rows($result) > 0) {
        $user = mysqli_fetch_assoc($result);
        echo json_encode([
            "status" => "success",
            "role" => $info['role'],
            "id" => $user['id'],
            "name" => $user['Fname']
        ]);
        exit();
    }
}

echo json_encode([
    "status" => "error",
    "message" => "Invalid ID or password"
]);
exit();
?>
