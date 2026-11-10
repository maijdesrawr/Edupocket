<?php

declare(strict_types=1);

require_once __DIR__ . '/app_session_common.php';
require_once __DIR__ . '/email_verification_common.php';

function sap_student_email(array $student): string
{
    $makeLocalPart = static function (string $value): string {
        $ascii = function_exists('iconv')
            ? (iconv('UTF-8', 'ASCII//TRANSLIT//IGNORE', $value) ?: $value)
            : $value;
        return strtolower(preg_replace('/[^a-zA-Z0-9]/', '', $ascii) ?? '');
    };

    $lastName = $makeLocalPart((string)($student['last_name'] ?? ''));
    $firstName = $makeLocalPart((string)($student['first_name'] ?? ''));
    if ($lastName === '' || $firstName === '') {
        throw new InvalidArgumentException('The student roster has an invalid name.');
    }

    $email = $lastName . '.' . $firstName . '@ue.edu.ph';
    if (filter_var($email, FILTER_VALIDATE_EMAIL) === false
        || !str_ends_with($email, '@ue.edu.ph')) {
        throw new InvalidArgumentException('A valid UE student email could not be generated.');
    }
    return $email;
}

function sap_find_dummy_student(mysqli $conn, string $qrValue): ?array
{
    $qrValue = trim($qrValue);
    if ($qrValue === '' || strlen($qrValue) > 255) {
        return null;
    }

    $statement = pc_prepare(
        $conn,
        'SELECT student_num, first_name, middle_name, last_name, suffix, '
            . 'parent_first_name, parent_middle_name, parent_last_name, parent_suffix '
            . 'FROM dummy_student_directory '
            . 'WHERE is_active = 1 AND (student_num = ? OR qr_code = ?) LIMIT 1'
    );
    $statement->bind_param('ss', $qrValue, $qrValue);
    $statement->execute();
    $student = $statement->get_result()->fetch_assoc();
    $statement->close();
    return is_array($student) ? $student : null;
}

function sap_assert_student_not_registered(mysqli $conn, string $studentNumber): void
{
    $statement = pc_prepare(
        $conn,
        'SELECT 1 FROM students WHERE student_num = ? LIMIT 1'
    );
    $statement->bind_param('s', $studentNumber);
    $statement->execute();
    $exists = $statement->get_result()->fetch_row() !== null;
    $statement->close();
    if ($exists) {
        throw new InvalidArgumentException('A student account already exists for this QR.');
    }
}

function sap_assert_student_email_available(
    mysqli $conn,
    string $email,
    array $config
): void {
    $fingerprint = ev_email_fingerprint($email, $config);
    $statement = pc_prepare(
        $conn,
        'SELECT 1 FROM account_verified_emails '
            . 'WHERE email_fingerprint = ? LIMIT 1'
    );
    $statement->bind_param('s', $fingerprint);
    $statement->execute();
    $exists = $statement->get_result()->fetch_row() !== null;
    $statement->close();
    if ($exists) {
        throw new InvalidArgumentException(
            'The generated UE email is already assigned to another account.'
        );
    }
}

function sap_send_student_credentials(
    string $email,
    string $studentName,
    string $studentNumber,
    string $temporaryPassword,
    string $temporaryPin,
    array $config,
    ?string $parentId = null,
    ?string $parentTemporaryPassword = null
): void {
    if (filter_var($email, FILTER_VALIDATE_EMAIL) === false
        || !str_ends_with(strtolower($email), '@ue.edu.ph')) {
        throw new RuntimeException('Student credential email address is invalid.');
    }

    $hasParentCredentials = $parentId !== null && $parentTemporaryPassword !== null;
    $salutation = 'Dear Mr/Ms. ' . $studentName . ',';
    $plainBody = $salutation . "\n\n"
        . "Welcome to EduPocket!\n\n"
        . "Your account has been successfully created. You may now access the EduPocket platform using the credentials provided below.\n\n"
        . "Student Account Credentials\n\n"
        . "Student ID: {$studentNumber}\n"
        . "Temporary Password: {$temporaryPassword}\n"
        . "Temporary PIN: {$temporaryPin}";
    if ($hasParentCredentials) {
        $plainBody .= "\n\nParent Account Credentials\n\n"
            . "Parent Account ID: {$parentId}\n"
            . "Temporary Password: {$parentTemporaryPassword}";
    }
    $plainBody .= "\n\nImportant Security Reminder\n\n"
        . ($hasParentCredentials
            ? "For your account's security, please sign in using your temporary credentials and change both passwords and the student PIN immediately after your first login.\n\n"
            : "For your account's security, please sign in using your temporary credentials and change your password and student PIN immediately after your first login.\n\n")
        . "Please keep your login credentials confidential and do not share them with anyone.\n\n"
        . "If you did not request or expect the creation of this account, please contact your school administrator immediately for assistance.\n\n"
        . "Thank you, and welcome to EduPocket!\n\n"
        . "Best regards,\nEduPocket Administration";

    $escape = static fn(string $value): string => htmlspecialchars(
        $value,
        ENT_QUOTES | ENT_SUBSTITUTE,
        'UTF-8'
    );
    $htmlBody = '<div style="font-family:Arial,sans-serif;line-height:1.6;color:#222">'
        . '<p>' . $escape($salutation) . '</p>'
        . '<p>Welcome to <strong>EduPocket!</strong></p>'
        . '<p>Your account has been successfully created. You may now access the EduPocket platform using the credentials provided below.</p>'
        . '<h3>Student Account Credentials</h3>'
        . '<p><strong>Student ID:</strong> ' . $escape($studentNumber) . '<br>'
        . '<strong>Temporary Password:</strong> ' . $escape($temporaryPassword) . '<br>'
        . '<strong>Temporary PIN:</strong> ' . $escape($temporaryPin) . '</p>';
    if ($parentId !== null && $parentTemporaryPassword !== null) {
        $htmlBody .= '<h3>Parent Account Credentials</h3>'
            . '<p><strong>Parent Account ID:</strong> ' . $escape($parentId) . '<br>'
            . '<strong>Temporary Password:</strong> ' . $escape($parentTemporaryPassword) . '</p>';
    }
    $htmlBody .= '<h3>Important Security Reminder</h3>'
        . '<p>' . ($hasParentCredentials
            ? 'For your account&#39;s security, please sign in using your temporary credentials and change both passwords and the student PIN immediately after your first login.'
            : 'For your account&#39;s security, please sign in using your temporary credentials and change your password and student PIN immediately after your first login.') . '</p>'
        . '<p>Please keep your login credentials confidential and do not share them with anyone.</p>'
        . '<p>If you did not request or expect the creation of this account, please contact your school administrator immediately for assistance.</p>'
        . '<p>Thank you, and welcome to EduPocket!</p>'
        . '<p>Best regards,<br><strong>EduPocket Administration</strong></p></div>';
    $emailConfig = pc_email_config($config);
    $sender = $emailConfig['send_callback'];
    $sent = $sender(
        $email,
        '',
        [
            'purpose' => 'student_account_credentials',
            'student_name' => $studentName,
            'student_number' => $studentNumber,
            'message' => $plainBody,
            'html_message' => $htmlBody,
        ]
    );
    if ($sent !== true) {
        throw new RuntimeException('STUDENT_CREDENTIAL_EMAIL_FAILED');
    }
}
