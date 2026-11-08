<?php

$servername = "127.0.0.1";
$username   = "root";
$password   = "R@wrah";
$dbname     = "try";
$port       = 3306;

$conn = new mysqli(
    $servername,
    $username,
    $password,
    $dbname,
    $port
);

if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}