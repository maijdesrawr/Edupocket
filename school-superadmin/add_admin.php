<?php

error_reporting(E_ALL);
ini_set('display_errors', 0);

header('Content-Type: application/json');

require_once "db.php";


$response = [
    "success" => false,
    "message" => "Something went wrong."
];



if ($_SERVER["REQUEST_METHOD"] !== "POST") {

    $response["message"] = "Invalid request method.";

    echo json_encode($response);
    exit;

}



$admin_id = trim($_POST["admin_id"] ?? "");
$name = trim($_POST["name"] ?? "");
$role = trim($_POST["role"] ?? "");
$password = $_POST["password"] ?? "";



if (
    empty($admin_id) ||
    empty($name) ||
    empty($role) ||
    empty($password)
) {

    $response["message"] =
        "Admin ID, Name, Role, and Password are required.";

    echo json_encode($response);
    exit;

}



$allowedRoles = [
    "system admin",
    "cashier",
    "registrar"
];

if (!in_array($role, $allowedRoles, true)) {

    $response["message"] = "Invalid admin role.";

    echo json_encode($response);
    exit;

}



$stmt = $conn->prepare("
    SELECT admin_id
    FROM admins
    WHERE admin_id = ?
");

if (!$stmt) {

    $response["message"] =
        "Database error: " . $conn->error;

    echo json_encode($response);
    exit;

}

$stmt->bind_param(
    "s",
    $admin_id
);

$stmt->execute();

$result = $stmt->get_result();

if ($result->num_rows > 0) {

    $response["message"] =
        "Admin ID already exists.";

    $stmt->close();

    echo json_encode($response);
    exit;

}

$stmt->close();



$hashedPassword = password_hash(
    $password,
    PASSWORD_DEFAULT
);



$stmt = $conn->prepare("
    INSERT INTO admins
    (
        admin_id,
        Fname,
        role,
        password
    )
    VALUES
    (
        ?,
        ?,
        ?,
        ?
    )
");


if (!$stmt) {

    $response["message"] =
        "Database error while preparing insert: " .
        $conn->error;

    echo json_encode($response);
    exit;

}



$stmt->bind_param(
    "ssss",
    $admin_id,
    $name,
    $role,
    $hashedPassword
);



if ($stmt->execute()) {

    $response = [
        "success" => true,
        "message" => "Admin account created successfully."
    ];

} else {

    $response["message"] =
        "Database error while creating admin: " .
        $stmt->error;

}



$stmt->close();

$conn->close();



echo json_encode($response);

?>