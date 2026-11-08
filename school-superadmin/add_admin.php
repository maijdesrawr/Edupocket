<?php

error_reporting(E_ALL);
ini_set('display_errors', 0);

header('Content-Type: application/json');

require_once "db.php";


$response = [
    "success" => false,
    "message" => "Something went wrong."
];


/* =========================================
   CHECK REQUEST METHOD
========================================= */

if ($_SERVER["REQUEST_METHOD"] !== "POST") {

    $response["message"] = "Invalid request method.";

    echo json_encode($response);
    exit;

}


/* =========================================
   GET FORM DATA
========================================= */

$admin_id = trim($_POST["admin_id"] ?? "");
$name = trim($_POST["name"] ?? "");
$role = trim($_POST["role"] ?? "");
$password = $_POST["password"] ?? "";


/* =========================================
   VALIDATE REQUIRED FIELDS
========================================= */

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


/* =========================================
   VALIDATE ROLE
========================================= */

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


/* =========================================
   CHECK ADMIN ID
========================================= */

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


/* =========================================
   HASH PASSWORD
========================================= */

$hashedPassword = password_hash(
    $password,
    PASSWORD_DEFAULT
);


/* =========================================
   INSERT ADMIN
========================================= */

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


/* =========================================
   BIND VALUES
========================================= */

$stmt->bind_param(
    "ssss",
    $admin_id,
    $name,
    $role,
    $hashedPassword
);


/* =========================================
   EXECUTE INSERT
========================================= */

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


/* =========================================
   CLOSE
========================================= */

$stmt->close();

$conn->close();


/* =========================================
   RETURN JSON
========================================= */

echo json_encode($response);

?>