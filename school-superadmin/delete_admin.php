<?php

error_reporting(E_ALL);
ini_set('display_errors', 1);

require_once "db.php";


$adminID = trim($_GET["admin_id"] ?? "");

if ($adminID === "") {
    die("Admin ID is missing.");
}



$checkAdmin = $conn->prepare("
    SELECT admin_id, Fname, role
    FROM admins
    WHERE admin_id = ?
    LIMIT 1
");

if (!$checkAdmin) {
    die("Database error: " . $conn->error);
}

$checkAdmin->bind_param(
    "s",
    $adminID
);

$checkAdmin->execute();

$result = $checkAdmin->get_result();

if ($result->num_rows === 0) {

    $checkAdmin->close();

    die("Admin account not found.");

}

$admin = $result->fetch_assoc();

$checkAdmin->close();



$deleteAdmin = $conn->prepare("
    DELETE FROM admins
    WHERE admin_id = ?
");

if (!$deleteAdmin) {
    die("Database error: " . $conn->error);
}

$deleteAdmin->bind_param(
    "s",
    $adminID
);


if ($deleteAdmin->execute()) {

    $deleteAdmin->close();

    header("Location: admins.php?deleted=1");
    exit;

}



$error = $deleteAdmin->error;

$deleteAdmin->close();

die(
    "Failed to delete admin account: " .
    htmlspecialchars($error)
);

?>