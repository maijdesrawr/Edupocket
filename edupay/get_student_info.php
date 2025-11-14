<?php
header('Content-Type: application/json');

$servername = "localhost";
$username = "root";
$password = "R@wrah";
$database = "centraldb";

$conn = new mysqli($servername, $username, $password, $database);

if ($conn->connect_error) {
    echo json_encode(["status" => "error", "message" => "Database connection failed."]);
    exit();
}

if (!isset($_GET['student_id'])) {
    echo json_encode(["status" => "error", "message" => "Missing student_id parameter."]);
    exit();
}

$student_id = $conn->real_escape_string($_GET['student_id']);

$query = "
    SELECT 
        student_num AS id,
        Fname AS name,
        balance
    FROM students
    WHERE student_num = '$student_id'
";

$result = $conn->query($query);

if ($result && $result->num_rows > 0) {
    $row = $result->fetch_assoc();

    echo json_encode([
        "status" => "success",
        "role" => "student",
        "id" => $row["id"],
        "name" => $row["name"],
        "balance" => $row["balance"]
    ]);
} else {
    echo json_encode([
        "status" => "error",
        "message" => "Student not found."
    ]);
}

$conn->close();
?>
