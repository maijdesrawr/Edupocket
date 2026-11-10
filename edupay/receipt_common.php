<?php

function receipt_prepare(mysqli $conn, string $sql): mysqli_stmt
{
    $statement = $conn->prepare($sql);
    if (!$statement) {
        throw new RuntimeException('Receipt query could not be prepared.');
    }
    return $statement;
}

function receipt_table_exists(mysqli $conn, string $table): bool
{
    $safe = preg_replace('/[^a-zA-Z0-9_]/', '', $table);
    if ($safe === '') {
        return false;
    }
    $result = $conn->query("SHOW TABLES LIKE '$safe'");
    return $result instanceof mysqli_result && $result->num_rows > 0;
}

function receipt_column_exists(mysqli $conn, string $table, string $column): bool
{
    $safeTable = preg_replace('/[^a-zA-Z0-9_]/', '', $table);
    $safeColumn = preg_replace('/[^a-zA-Z0-9_]/', '', $column);
    if ($safeTable === '' || $safeColumn === '') {
        return false;
    }
    $result = $conn->query("SHOW COLUMNS FROM `$safeTable` LIKE '$safeColumn'");
    return $result instanceof mysqli_result && $result->num_rows > 0;
}


function receipt_processed_by(array $transaction): array
{
    $processorId = trim((string)($transaction['processor_id_snapshot'] ?? ''));
    $processorRole = strtolower(trim(
        (string)($transaction['processor_role_snapshot'] ?? '')
    ));
    $processorSource = strtolower(trim(
        (string)($transaction['processor_account_source_snapshot'] ?? '')
    ));
    $processorName = trim((string)($transaction['processor_name_snapshot'] ?? ''));
    if ($processorName !== '') {
        return [
            'id' => $processorId,
            'name' => $processorName,
            'role' => in_array(
                $processorRole,
                ['student', 'parent', 'canteen', 'cashier'],
                true
            ) ? $processorRole : null,
            'account_source' => in_array(
                $processorSource,
                ['students', 'parents', 'canteens', 'cashiers', 'admins'],
                true
            ) ? $processorSource : null,
        ];
    }

    if ($processorId !== '' || $processorRole !== '' || $processorSource !== '') {
        return [
            'id' => $processorId,
            'name' => 'N/A',
            'role' => in_array(
                $processorRole,
                ['student', 'parent', 'canteen', 'cashier'],
                true
            ) ? $processorRole : null,
            'account_source' => in_array(
                $processorSource,
                ['students', 'parents', 'canteens', 'cashiers', 'admins'],
                true
            ) ? $processorSource : null,
        ];
    }

    $cashierName = trim((string)($transaction['cashier_name_snapshot'] ?? ''));
    if ($cashierName !== '') {
        return [
            'id' => trim((string)($transaction['cashier_id_snapshot'] ?? '')),
            'name' => $cashierName,
            'role' => 'cashier',
            'account_source' => null,
        ];
    }

    $canteenName = trim((string)($transaction['canteen_name_snapshot'] ?? ''));
    if ($canteenName !== '') {
        return [
            'id' => trim((string)($transaction['canteen_id_snapshot'] ?? '')),
            'name' => $canteenName,
            'role' => 'canteen',
            'account_source' => 'canteens',
        ];
    }

    return [
        'id' => '',
        'name' => 'N/A',
        'role' => null,
        'account_source' => null,
    ];
}

function receipt_mask_student_name(string $name): string
{
    $normalized = trim((string)(preg_replace('/\s+/u', ' ', $name) ?? $name));
    if ($normalized === '') {
        return 'Unknown User';
    }

    $parts = preg_split('/\s+/u', $normalized, -1, PREG_SPLIT_NO_EMPTY);
    if (!is_array($parts) || $parts === []) {
        return 'Unknown User';
    }

    $initial = static function (string $part): string {
        return function_exists('mb_substr')
            ? mb_substr($part, 0, 1, 'UTF-8')
            : (preg_match('/^./us', $part, $match) === 1
                ? $match[0]
                : substr($part, 0, 1));
    };
    $firstInitial = $initial((string)$parts[0]);

    if (count($parts) === 1) {
        return $firstInitial . '•••';
    }

    $maskedSurname = '';
    foreach (array_slice($parts, 1) as $index => $part) {
        $maskedSurname .= $initial((string)$part)
            . str_repeat('•', $index === 0 ? 4 : 3);
    }

    return $firstInitial . '••• ' . $maskedSurname;
}

function receipt_mask_name_parts(string $firstName, string $lastName): string
{
    $firstName = trim($firstName);
    $lastName = trim($lastName);
    if ($firstName === '' || $lastName === '') {
        return receipt_mask_student_name(trim($firstName . ' ' . $lastName));
    }
    $initial = static function (string $word): string {
        return function_exists('mb_substr') ? mb_substr($word, 0, 1, 'UTF-8') : substr($word, 0, 1);
    };
    $maskedLast = '';
    $words = preg_split('/\s+/u', $lastName, -1, PREG_SPLIT_NO_EMPTY) ?: [];
    foreach ($words as $index => $word) {
        $maskedLast .= $initial($word) . str_repeat('•', $index === 0 ? 4 : 3);
    }
    return $initial($firstName) . '••• ' . $maskedLast;
}

function receipt_mask_account_name(
    mysqli $conn,
    string $source,
    string $id,
    string $fallback
): string {
    $targets = ['students'=>'student_num','parents'=>'parent_id','admins'=>'admin_id','cashiers'=>'cashier_id','canteens'=>'canteen_id'];
    if (!isset($targets[$source]) || !receipt_column_exists($conn, $source, 'first_name')
        || !receipt_column_exists($conn, $source, 'last_name')) return receipt_mask_student_name($fallback);
    $key = $targets[$source];
    $st = receipt_prepare($conn, "SELECT first_name,last_name FROM `$source` WHERE `$key`=? LIMIT 1");
    $st->bind_param('s', $id); $st->execute(); $row = $st->get_result()->fetch_assoc(); $st->close();
    return is_array($row)
        ? receipt_mask_name_parts((string)($row['first_name']??''),(string)($row['last_name']??''))
        : receipt_mask_student_name($fallback);
}

function receipt_account_name_without_middle(
    mysqli $conn,
    string $source,
    string $id,
    string $fallback
): string {
    $targets = [
        'students' => 'student_num', 'parents' => 'parent_id',
        'admins' => 'admin_id', 'cashiers' => 'cashier_id', 'canteens' => 'canteen_id',
    ];
    if (!isset($targets[$source]) || !receipt_column_exists($conn, $source, 'first_name')
        || !receipt_column_exists($conn, $source, 'last_name')) {
        return trim($fallback);
    }
    $key = $targets[$source];
    $statement = receipt_prepare(
        $conn,
        "SELECT TRIM(CONCAT_WS(' ', NULLIF(first_name, ''), NULLIF(last_name, ''))) AS display_name "
            . "FROM `$source` WHERE `$key` = ? LIMIT 1"
    );
    $statement->bind_param('s', $id);
    $statement->execute();
    $row = $statement->get_result()->fetch_assoc();
    $statement->close();
    $name = trim((string)($row['display_name'] ?? ''));
    return $name !== '' ? $name : trim($fallback);
}

function receipt_transfer_detail_without_middle(mysqli $conn, string $detail): string
{
    if (preg_match('/^(Transfer\\s+(?:sent\\s+to|received\\s+from)\\s+)(.+)$/iu', trim($detail), $matches) !== 1) {
        return $detail;
    }
    $legacyName = trim($matches[2]);
    $statement = receipt_prepare(
        $conn,
        "SELECT TRIM(CONCAT_WS(' ', NULLIF(first_name, ''), NULLIF(last_name, ''))) AS display_name "
            . 'FROM students WHERE Fname = ? LIMIT 1'
    );
    $statement->bind_param('s', $legacyName);
    $statement->execute();
    $row = $statement->get_result()->fetch_assoc();
    $statement->close();
    $name = trim((string)($row['display_name'] ?? ''));
    return $matches[1] . ($name !== '' ? $name : $legacyName);
}

function receipt_mask_transfer_detail_for_display(mysqli $conn, string $detail): string
{
    if (preg_match('/^(Transfer\\s+(?:sent\\s+to|received\\s+from)\\s+)(.+)$/iu', trim($detail), $matches) !== 1) return $detail;
    $name = trim($matches[2]);
    $st = receipt_prepare($conn,
        "SELECT first_name,last_name FROM students WHERE Fname=? "
        . "OR TRIM(CONCAT_WS(' ',NULLIF(first_name,''),NULLIF(last_name,'')))=? LIMIT 1");
    $st->bind_param('ss', $name, $name); $st->execute(); $row = $st->get_result()->fetch_assoc(); $st->close();
    $masked = is_array($row)
        ? receipt_mask_name_parts((string)($row['first_name']??''),(string)($row['last_name']??''))
        : receipt_mask_student_name($name);
    return $matches[1] . $masked;
}

function receipt_mask_student_id(string $studentId): string
{
    if (function_exists('mb_substr')) {
        $visiblePrefix = mb_substr($studentId, 0, 4, 'UTF-8');
    } else {
        preg_match_all('/./us', $studentId, $characters);
        $visiblePrefix = implode('', array_slice($characters[0] ?? [], 0, 4));
    }

    return $visiblePrefix . '••••••';
}

function receipt_mask_transfer_detail(string $detail): string
{
    if (preg_match(
        '/^(Transfer\s+(?:sent\s+to|received\s+from)\s+)(.+)$/iu',
        trim($detail),
        $matches
    ) !== 1) {
        return $detail;
    }

    return $matches[1] . receipt_mask_student_name(trim($matches[2]));
}

function receipt_assert_viewer_access(
    mysqli $conn,
    array $transaction,
    string $viewerRole,
    string $viewerId
): void {
    if ($viewerId === '') {
        throw new InvalidArgumentException('A receipt viewer ID is required.');
    }
    switch ($viewerRole) {
        case 'student':
            if (!hash_equals((string)$transaction['student_num'], $viewerId)) {
                throw new RuntimeException('This receipt is not available to that account.');
            }
            return;
        case 'canteen':
            if (!hash_equals((string)($transaction['canteen_id'] ?? ''), $viewerId)) {
                throw new RuntimeException('This receipt is not available to that account.');
            }
            return;
        case 'cashier':
            if (!hash_equals((string)($transaction['cashier_id'] ?? ''), $viewerId)) {
                throw new RuntimeException('This receipt is not available to that account.');
            }
            return;
        case 'admin':
            $statement = receipt_prepare(
                $conn,
                'SELECT 1 FROM admins WHERE admin_id = ? '
                    . "AND LOWER(COALESCE(role, '')) <> 'cashier' LIMIT 1"
            );
            $statement->bind_param('s', $viewerId);
            $statement->execute();
            $allowed = $statement->get_result()->fetch_row() !== null;
            $statement->close();
            if (!$allowed) {
                throw new RuntimeException('This receipt is not available to that account.');
            }
            return;
        case 'parent':
            $studentNumber = (string)$transaction['student_num'];
            $statement = receipt_prepare(
                $conn,
                'SELECT 1 FROM parents p '
                    . 'LEFT JOIN parent_student_link psl '
                    . 'ON psl.parent_id = p.parent_id AND psl.student_num = ? '
                    . 'WHERE p.parent_id = ? '
                    . 'AND (psl.id IS NOT NULL OR p.linked_student_num = ?) LIMIT 1'
            );
            $statement->bind_param('sss', $studentNumber, $viewerId, $studentNumber);
            $statement->execute();
            $allowed = $statement->get_result()->fetch_row() !== null;
            $statement->close();
            if (!$allowed) {
                throw new RuntimeException('This receipt is not available to that account.');
            }
            return;
        default:
            throw new InvalidArgumentException('Invalid receipt viewer role.');
    }
}


function receipt_fetch(
    mysqli $conn,
    int $transactionId,
    string $viewerRole,
    string $viewerId
): array {
    if ($transactionId <= 0) {
        throw new InvalidArgumentException('A valid transaction ID is required.');
    }
    $viewerRole = strtolower(trim($viewerRole));
    $viewerId = trim($viewerId);
    if (!receipt_table_exists($conn, 'transaction_receipts')) {
        throw new RuntimeException('The receipt database migration has not been applied.');
    }

    $statement = receipt_prepare(
        $conn,
        'SELECT t.transaction_id, t.student_num, t.canteen_id, t.cashier_id, t.bill_payment_id, '
            . 'COALESCE(t.date_time, t.date_created, NOW()) AS event_time, '
            . 'r.receipt_number, r.issued_at, r.status AS receipt_status, r.currency, '
            . 'r.transaction_type, r.description_snapshot AS description, '
            . 'r.total_amount AS amount, r.legacy_backfilled, '
            . 'r.student_num_snapshot, r.student_name_snapshot, '
            . 'r.canteen_id_snapshot, r.canteen_name_snapshot, '
            . 'r.cashier_id_snapshot, r.cashier_name_snapshot, '
            . 'r.processor_role_snapshot, r.processor_account_source_snapshot, '
            . 'r.processor_id_snapshot, '
            . 'r.processor_name_snapshot, '
            . 'c.location AS canteen_location '
            . 'FROM transactions t '
            . 'JOIN transaction_receipts r ON r.transaction_id = t.transaction_id '
            . 'LEFT JOIN canteens c ON c.canteen_id = t.canteen_id '
            . 'WHERE t.transaction_id = ? LIMIT 1'
    );
    $statement->bind_param('i', $transactionId);
    $statement->execute();
    $transaction = $statement->get_result()->fetch_assoc();
    $statement->close();
    if (!is_array($transaction)) {
        throw new RuntimeException('Receipt not found.');
    }

    receipt_assert_viewer_access($conn, $transaction, $viewerRole, $viewerId);

    if ((string)$transaction['transaction_type'] === 'transfer-out'
        && receipt_table_exists($conn, 'student_transfers')) {
        $recipientStatement = receipt_prepare(
            $conn,
            'SELECT rr.student_num_snapshot, rr.student_name_snapshot '
                . 'FROM student_transfers st '
                . 'JOIN transaction_receipts rr '
                . 'ON rr.transaction_id = st.recipient_transaction_id '
                . 'WHERE st.sender_transaction_id = ? '
                . "AND st.status = 'completed' LIMIT 1"
        );
        $recipientStatement->bind_param('i', $transactionId);
        $recipientStatement->execute();
        $recipient = $recipientStatement->get_result()->fetch_assoc();
        $recipientStatement->close();
        if (is_array($recipient)) {
            $transaction['student_num_snapshot'] = $recipient['student_num_snapshot'];
            $transaction['student_name_snapshot'] = $recipient['student_name_snapshot'];
        }
    }

    $items = [];
    if (receipt_table_exists($conn, 'transaction_items')) {
        $itemNameExpression = receipt_column_exists($conn, 'transaction_items', 'item_name')
            ? "COALESCE(NULLIF(ti.item_name, ''), p.name, CONCAT('Product #', ti.product_id))"
            : "COALESCE(p.name, CONCAT('Product #', ti.product_id))";
        $itemStatement = receipt_prepare(
            $conn,
            "SELECT ti.product_id, $itemNameExpression AS item_name, "
                . 'ti.quantity, ti.price, (ti.quantity * ti.price) AS line_total '
                . 'FROM transaction_items ti '
                . 'LEFT JOIN products p ON p.product_id = ti.product_id '
                . 'WHERE ti.transaction_id = ? ORDER BY ti.id ASC'
        );
        $itemStatement->bind_param('i', $transactionId);
        $itemStatement->execute();
        $result = $itemStatement->get_result();
        while ($row = $result->fetch_assoc()) {
            $items[] = [
                'product_id' => (int)$row['product_id'],
                'name' => (string)$row['item_name'],
                'quantity' => (int)$row['quantity'],
                'unit_price' => number_format((float)$row['price'], 2, '.', ''),
                'line_total' => number_format((float)$row['line_total'], 2, '.', ''),
            ];
        }
        $itemStatement->close();
    }

    $studentName = receipt_account_name_without_middle(
        $conn,
        'students',
        (string)$transaction['student_num_snapshot'],
        (string)$transaction['student_name_snapshot']
    );
    $studentId = (string)$transaction['student_num_snapshot'];
    $description = receipt_transfer_detail_without_middle(
        $conn,
        (string)($transaction['description'] ?? '')
    );
    $processedBy = receipt_processed_by($transaction);
    if (($processedBy['account_source'] ?? '') !== '') {
        $processedBy['name'] = receipt_account_name_without_middle(
            $conn,
            (string)$processedBy['account_source'],
            (string)($processedBy['id'] ?? ''),
            (string)($processedBy['name'] ?? '')
        );
    }
    if ($viewerRole === 'admin') {
        $studentName = receipt_mask_account_name(
            $conn, 'students', (string)$transaction['student_num_snapshot'], $studentName
        );
        $studentId = receipt_mask_student_id($studentId);
        $description = receipt_mask_transfer_detail_for_display($conn, $description);
        foreach ($items as &$item) {
            $item['name'] = receipt_mask_transfer_detail_for_display($conn, (string)$item['name']);
        }
        unset($item);
    }

    return [
        'transaction_id' => (int)$transaction['transaction_id'],
        'receipt_number' => (string)$transaction['receipt_number'],
        'status' => (string)$transaction['receipt_status'],
        'currency' => (string)$transaction['currency'],
        'legacy_backfilled' => (bool)$transaction['legacy_backfilled'],
        'transaction_type' => (string)$transaction['transaction_type'],
        'description' => $description,
        'amount' => number_format((float)$transaction['amount'], 2, '.', ''),
        'date_time' => (string)$transaction['event_time'],
        'issued_at' => (string)$transaction['issued_at'],
        'student' => [
            'id' => $studentId,
            'name' => $studentName,
        ],
        'processed_by' => $processedBy,
        'canteen' => [
            'id' => (string)($transaction['canteen_id_snapshot'] ?? ''),
            'name' => (string)($transaction['canteen_name_snapshot'] ?? ''),
            'location' => (string)($transaction['canteen_location'] ?? ''),
        ],
        'cashier' => [
            'id' => (string)($transaction['cashier_id_snapshot'] ?? ''),
            'name' => (string)($transaction['cashier_name_snapshot'] ?? ''),
        ],
        'items' => $items,
    ];
}
