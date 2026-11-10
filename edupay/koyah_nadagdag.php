<?php

declare(strict_types=1);

require_once __DIR__ . '/student_account_provisioning_common.php';

error_reporting(E_ALL);
ini_set('display_errors', '0');
pc_bootstrap_json_endpoint();

$conn = null;
try {
    pc_require_post();
    $conn = pc_open_database();
    $adminSession = as_require_session($conn);
    as_assert_session_role($adminSession, ['admin']);
} catch (PasswordChangeClientException $error) {
    if ($conn instanceof mysqli) $conn->close();
    if (http_response_code() < 400) http_response_code(401);
    pc_respond(pc_client_error_payload($error->getMessage(), $error->details()));
} catch (Throwable $error) {
    if ($conn instanceof mysqli) $conn->close();
    error_log('koyah_nadagdag.php authorization failed: ' . $error->getMessage());
    http_response_code(500);
    pc_respond(pc_client_error_payload('User management is temporarily unavailable.'));
}

function generateTempPassword($length = 8) {
    $characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    $password = '';

    for ($i = 0; $i < $length; $i++) {
        $password .= $characters[random_int(0, strlen($characters) - 1)];
    }

    return $password;
}

function generateTempPIN()
{
    return str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);
}

$category = $_POST['category'] ?? '';
$action = $_POST['action'] ?? '';

if (empty($category) && empty($action)) {
    $conn->close();
    pc_respond([
        'status' => 'error',
        'message' => 'Category or action is required'
    ]);
}

function sanitize($conn, $value) {
    return mysqli_real_escape_string($conn, trim($value));
}

function prepareOrThrow(mysqli $conn, string $sql): mysqli_stmt
{
    $stmt = $conn->prepare($sql);
    if (!$stmt) {
        throw new RuntimeException($conn->error, $conn->errno);
    }

    return $stmt;
}

function executeOrThrow(mysqli_stmt $stmt): void
{
    if (!$stmt->execute()) {
        throw new RuntimeException($stmt->error, $stmt->errno);
    }
}


if ($action === 'get_parents') {

    $stmt = prepareOrThrow(
        $conn,
        "SELECT parent_id, first_name, middle_name, last_name, suffix
         FROM parents
         ORDER BY last_name ASC, first_name ASC"
    );

    executeOrThrow($stmt);

    $result = $stmt->get_result();

    $parents = [];

    while ($row = $result->fetch_assoc()) {
        $parents[] = [
            'parent_id' => $row['parent_id'],
            'first_name' => $row['first_name'],
            'middle_name' => $row['middle_name'],
            'last_name' => $row['last_name'],
            'suffix' => $row['suffix'],
        ];
    }

    $stmt->close();

    $conn->close();
    pc_respond([
        'status' => 'success',
        'parents' => $parents
    ]);
}

if ($action === 'lookup_dummy_student') {
    try {
        $student = sap_find_dummy_student(
            $conn,
            pc_post_string('qr_value')
        );
        if ($student === null) {
            http_response_code(404);
            pc_reject('This QR was not found in the dummy student directory.');
        }
        sap_assert_student_not_registered($conn, (string)$student['student_num']);
        $student['email'] = sap_student_email($student);
        $conn->close();
        pc_respond(['status' => 'success', 'student' => $student]);
    } catch (PasswordChangeClientException $error) {
        $conn->close();
        pc_respond(pc_client_error_payload($error->getMessage(), $error->details()));
    } catch (InvalidArgumentException $error) {
        $conn->close();
        http_response_code(404);
        pc_respond(pc_client_error_payload($error->getMessage()));
    } catch (Throwable $error) {
        $conn->close();
        error_log('Dummy student lookup failed: ' . $error->getMessage());
        http_response_code(500);
        pc_respond(pc_client_error_payload('The student roster lookup failed.'));
    }
}


function generateParentID($conn)
{
    $year = date('y');

    $stmt = prepareOrThrow(
        $conn,
        "SELECT parent_id
         FROM parents
         WHERE parent_id LIKE CONCAT(?, '%')
         ORDER BY parent_id DESC
         LIMIT 1
         FOR UPDATE"
    );
    $stmt->bind_param('s', $year);
    executeOrThrow($stmt);
    $result = $stmt->get_result();
    $row = $result ? $result->fetch_assoc() : null;
    $stmt->close();

    if (!empty($row['parent_id'])) {

        $lastSequence = (int) substr($row['parent_id'], 2);

        $nextSequence = str_pad(
            (string) ($lastSequence + 1),
            9,
            '0',
            STR_PAD_LEFT
        );

    } else {

        $nextSequence = '000000001';
    }

    return $year . $nextSequence;
}

$response = ['status' => 'error', 'message' => 'Unknown error'];

switch ($category) {

case 'student':

    $student_num = sanitize($conn, $_POST['student_num'] ?? '');
    $student_roster = sap_find_dummy_student($conn, $student_num);
    if ($student_roster === null) {
        $response['message'] = 'Scan a student QR from the dummy student directory.';
        break;
    }
    try {
        sap_assert_student_not_registered($conn, (string)$student_roster['student_num']);
        $student_email = sap_student_email($student_roster);
        $email_config = pc_security_config();
        ev_require_schema($conn);
        sap_assert_student_email_available($conn, $student_email, $email_config);
    } catch (Throwable $error) {
        $response['message'] = $error instanceof InvalidArgumentException
            ? $error->getMessage()
            : 'Student email is unavailable. Check the email setup and try again.';
        break;
    }

    $student_num = (string)$student_roster['student_num'];
    $student_first_name = (string)$student_roster['first_name'];
    $student_middle_name = (string)($student_roster['middle_name'] ?? '');
    $student_last_name = (string)$student_roster['last_name'];
    $student_suffix = (string)($student_roster['suffix'] ?? '');

    $parent_first_name = sanitize($conn, $_POST['parent_first_name'] ?? '');
    $parent_middle_name = sanitize($conn, $_POST['parent_middle_name'] ?? '');
    $parent_last_name = sanitize($conn, $_POST['parent_last_name'] ?? '');
    $parent_suffix = sanitize($conn, $_POST['parent_suffix'] ?? '');
      
    $student_name = trim(
        $student_first_name . ' ' .
        $student_middle_name . ' ' .
        $student_last_name . ' ' .
        $student_suffix
    );

    $parent_name = trim(
        $parent_first_name . ' ' .
        $parent_middle_name . ' ' .
        $parent_last_name . ' ' .
        $parent_suffix
    );

    if (
        empty($student_first_name) ||
        empty($student_last_name) ||
        empty($student_num) ||
        empty($parent_first_name) ||
        empty($parent_last_name)
    ) {
        $response['message'] = 'Student and Parent names are required';
        break;
    }

    if (!ctype_digit($student_num) || strlen($student_num) != 11) {
        $response['message'] = 'Student Number must be exactly 11 digits';
        break;
    }

    $balance = 0.00;
    $password_changed = 0;
    $student_temp_password = generateTempPassword();
    $student_password = password_hash($student_temp_password, PASSWORD_DEFAULT);
    $parent_temp_password = generateTempPassword();
    $parent_password = password_hash($parent_temp_password, PASSWORD_DEFAULT);
    $student_temp_pin = generateTempPIN();
    $student_pin = password_hash($student_temp_pin, PASSWORD_DEFAULT);
    $qr_code = 'QR_' . $student_num;

    if (!$conn->begin_transaction()) {
        $response['message'] = 'Account creation could not be started.';
        break;
    }

    try {
        $parent_id = generateParentID($conn);

        $student_stmt = prepareOrThrow(
            $conn,
            "INSERT INTO students (
                student_num, Fname, first_name, middle_name, last_name, suffix,
                Password, pin, balance, parent_id, qr_code, password_changed
             ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
        );
        $student_stmt->bind_param(
            'ssssssssdssi',
            $student_num,
            $student_name,
            $student_first_name,
            $student_middle_name,
            $student_last_name,
            $student_suffix,
            $student_password,
            $student_pin,
            $balance,
            $parent_id,
            $qr_code,
            $password_changed
        );
        executeOrThrow($student_stmt);
        $student_stmt->close();

        $parent_stmt = prepareOrThrow(
            $conn,
            "INSERT INTO parents (
                parent_id, Fname, first_name, middle_name, last_name, suffix,
                Password, linked_student_num, password_changed
             ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)"
        );
        $parent_stmt->bind_param(
            'ssssssssi',
            $parent_id,
            $parent_name,
            $parent_first_name,
            $parent_middle_name,
            $parent_last_name,
            $parent_suffix,
            $parent_password,
            $student_num,
            $password_changed
        );
        executeOrThrow($parent_stmt);
        $parent_stmt->close();

        $link_stmt = prepareOrThrow(
            $conn,
            'INSERT INTO parent_student_link (parent_id, student_num) VALUES (?, ?)'
        );
        $link_stmt->bind_param('ss', $parent_id, $student_num);
        executeOrThrow($link_stmt);
        $link_stmt->close();

        ev_save_verified_email(
            $conn,
            'student',
            'students',
            $student_num,
            $student_email,
            $email_config
        );
        try {
            sap_send_student_credentials(
                $student_email,
                $student_name,
                $student_num,
                $student_temp_password,
                $student_temp_pin,
                $email_config,
                $parent_id,
                $parent_temp_password
            );
        } catch (Throwable $emailError) {
            error_log('Student credential email delivery failed: ' . $emailError->getMessage());
            throw new RuntimeException('STUDENT_CREDENTIAL_EMAIL_FAILED', 0, $emailError);
        }

        as_record_activity($conn, $adminSession, 'student_family_account_created', [
            'student_num' => $student_num,
            'parent_id' => $parent_id,
            'category' => $category,
        ], 'server', 'success', $email_config);
        if (!$conn->commit()) {
            throw new RuntimeException('Student account creation could not be committed.');
        }

        $response = [
            'status' => 'success',
            'message' => 'Account created. Login credentials have been sent to the student email.'
        ];
    } catch (Throwable $error) {
        $conn->rollback();
        $diagnostic = preg_replace(
            '/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/i',
            '[email]',
            $error->getMessage()
        ) ?? 'unknown error';
        $diagnostic = preg_replace('/\b\d{7,}\b/', '[id]', $diagnostic) ?? $diagnostic;
        error_log(
            'Student account creation failed (' . get_class($error) . ':'
                . $error->getCode() . '): ' . $diagnostic
        );
        if ($error->getMessage() === 'STUDENT_CREDENTIAL_EMAIL_FAILED') {
            $response['message'] = 'The email does not exist. Please try again later.';
            $response['error_code'] = 'email_delivery_failed';
        } else {
            $response['message'] = $error->getCode() === 1062
                ? 'Student Number already exists'
                : 'The student account could not be created.';
        }
    }
    break;

case 'child':

    $parent_id = sanitize($conn, $_POST['parent_id'] ?? '');
    $student_num = sanitize($conn, $_POST['student_num'] ?? '');
    $student_roster = sap_find_dummy_student($conn, $student_num);
    if ($student_roster === null) {
        $response['message'] = 'Scan a student QR from the dummy student directory.';
        break;
    }
    try {
        sap_assert_student_not_registered($conn, (string)$student_roster['student_num']);
        $student_email = sap_student_email($student_roster);
        $email_config = pc_security_config();
        ev_require_schema($conn);
        sap_assert_student_email_available($conn, $student_email, $email_config);
    } catch (Throwable $error) {
        $response['message'] = $error instanceof InvalidArgumentException
            ? $error->getMessage()
            : 'Student email is unavailable. Check the email setup and try again.';
        break;
    }

    $student_num = (string)$student_roster['student_num'];
    $student_first_name = (string)$student_roster['first_name'];
    $student_middle_name = (string)($student_roster['middle_name'] ?? '');
    $student_last_name = (string)$student_roster['last_name'];
    $student_suffix = (string)($student_roster['suffix'] ?? '');

    $student_name = trim(
        $student_first_name . ' ' .
        $student_middle_name . ' ' .
        $student_last_name . ' ' .
        $student_suffix
    );

    if (
    empty($parent_id) ||
    empty($student_first_name) ||
    empty($student_last_name) ||
    empty($student_num)
) {
    $response['message'] = 'Missing required fields';
    break;
}


if (!ctype_digit($student_num) || strlen($student_num) != 11) {
    $response['message'] = 'Student Number must be exactly 11 digits';
    break;
}

    $check_parent = prepareOrThrow(
        $conn,
        'SELECT parent_id FROM parents WHERE parent_id = ? LIMIT 1'
    );
    $check_parent->bind_param('s', $parent_id);
    executeOrThrow($check_parent);
    $parent_exists = $check_parent->get_result();
    $check_parent->close();

    if (!$parent_exists || $parent_exists->num_rows === 0) {
        $response['message'] = 'Parent ID does not exist';
        break;
    }

    $balance = 0.00;
    $password_changed = 0;
    $student_temp_password = generateTempPassword();
    $student_password = password_hash($student_temp_password, PASSWORD_DEFAULT);
    $student_temp_pin = generateTempPIN();
    $student_pin = password_hash($student_temp_pin, PASSWORD_DEFAULT);

    if (!$conn->begin_transaction()) {
        $response['message'] = 'Account creation could not be started.';
        break;
    }

    $qr_code = 'QR_' . $student_num;

    try {
        $student_stmt = prepareOrThrow(
            $conn,
            "INSERT INTO students (
                student_num, Fname, first_name, middle_name, last_name, suffix,
                Password, pin, balance, parent_id, qr_code, password_changed
             ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
        );
        $student_stmt->bind_param(
            'ssssssssdssi',
            $student_num,
            $student_name,
            $student_first_name,
            $student_middle_name,
            $student_last_name,
            $student_suffix,
            $student_password,
            $student_pin,
            $balance,
            $parent_id,
            $qr_code,
            $password_changed
        );
        executeOrThrow($student_stmt);
        $student_stmt->close();

        $link_stmt = prepareOrThrow(
            $conn,
            'INSERT INTO parent_student_link (parent_id, student_num) VALUES (?, ?)'
        );
        $link_stmt->bind_param('ss', $parent_id, $student_num);
        executeOrThrow($link_stmt);
        $link_stmt->close();

        ev_save_verified_email(
            $conn,
            'student',
            'students',
            $student_num,
            $student_email,
            $email_config
        );
        try {
            sap_send_student_credentials(
                $student_email,
                $student_name,
                $student_num,
                $student_temp_password,
                $student_temp_pin,
                $email_config
            );
        } catch (Throwable $emailError) {
            error_log('Student credential email delivery failed: ' . $emailError->getMessage());
            throw new RuntimeException('STUDENT_CREDENTIAL_EMAIL_FAILED', 0, $emailError);
        }

        as_record_activity($conn, $adminSession, 'student_account_created', [
            'student_num' => $student_num,
            'parent_id' => $parent_id,
            'category' => $category,
        ], 'server', 'success', $email_config);
        if (!$conn->commit()) {
            throw new RuntimeException('Student account creation could not be committed.');
        }

        $response = [
            'status' => 'success',
            'message' => 'Account created. Login credentials have been sent to the student email.'
        ];
    } catch (Throwable $error) {
        $conn->rollback();
        $diagnostic = preg_replace(
            '/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/i',
            '[email]',
            $error->getMessage()
        ) ?? 'unknown error';
        $diagnostic = preg_replace('/\b\d{7,}\b/', '[id]', $diagnostic) ?? $diagnostic;
        error_log(
            'Child account creation failed (' . get_class($error) . ':'
                . $error->getCode() . '): ' . $diagnostic
        );
        if ($error->getMessage() === 'STUDENT_CREDENTIAL_EMAIL_FAILED') {
            $response['message'] = 'The email does not exist. Please try again later.';
            $response['error_code'] = 'email_delivery_failed';
        } else {
            $response['message'] = $error->getCode() === 1062
                ? 'Student already exists'
                : 'The student account could not be created.';
        }
    }

break;


case 'pos':
    $name = sanitize($conn, $_POST['name'] ?? '');
    $canteen_id = sanitize($conn, $_POST['canteen_id'] ?? '');
    $location = sanitize($conn, $_POST['location'] ?? '');
    $password_raw = $_POST['password'] ?? '';

    if (empty($name) || empty($canteen_id) || empty($password_raw)) {
        $response['message'] = 'Canteen Name, ID, and Password are required';
        break;
    }

    $password = password_hash($password_raw, PASSWORD_DEFAULT);

    $sql = "INSERT INTO canteens (canteen_id, Fname, Password, location)
            VALUES ('$canteen_id', '$name', '$password', '$location')";

    if (mysqli_query($conn, $sql)) {
        $response = ['status' => 'success', 'message' => 'POS added successfully'];
    } else {
        $response['message'] = mysqli_error($conn);
    }
    break;

case 'cashier':
    $name = sanitize($conn, $_POST['name'] ?? '');
    $cashier_id = sanitize($conn, $_POST['cashier_id'] ?? '');
    $username = sanitize($conn, $_POST['username'] ?? '');
    $password_raw = $_POST['password'] ?? '';

    if (empty($name) || empty($cashier_id) || empty($username) || empty($password_raw)) {
        $response['message'] = 'Name, Cashier ID, Username, and Password are required';
        break;
    }

    $password = password_hash($password_raw, PASSWORD_DEFAULT);

    $sql = "INSERT INTO cashiers (cashier_id, Fname, username, password)
            VALUES ('$cashier_id', '$name', '$username', '$password')";

    if (mysqli_query($conn, $sql)) {
        $response = ['status' => 'success', 'message' => 'Cashier added successfully'];
    } else {
        $response['message'] = mysqli_error($conn);
    }
    break;

}

$conn->close();
pc_respond($response);
?>
