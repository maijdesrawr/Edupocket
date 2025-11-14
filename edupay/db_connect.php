<?php
$servername = "localhost";
$username = "root";
$password = "R@wrah";
$dbname = "centraldb"; 

$conn = mysqli_connect($servername, $username, $password, $dbname);

if (!$conn) {
    die(json_encode([
        "status" => "error",
        "message" => "Database connection failed: " . mysqli_connect_error()
    ]));
}
?>
