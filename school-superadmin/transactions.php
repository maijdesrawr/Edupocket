<?php

require_once "db.php";

/* =========================
   FILTER VALUES
========================= */

$studentId = trim($_GET['student_id'] ?? '');
$cashierId = trim($_GET['cashier_id'] ?? '');
$canteenId = trim($_GET['canteen_id'] ?? '');
$date = trim($_GET['date'] ?? '');

/* =========================
   CHECK IF STUDENT EXISTS
========================= */

$studentExists = true;

if ($studentId !== '') {

    $checkStudentQuery = "
        SELECT student_num
        FROM students
        WHERE student_num = ?
    ";

    $checkStudentStmt = $conn->prepare($checkStudentQuery);
    $checkStudentStmt->bind_param("s", $studentId);
    $checkStudentStmt->execute();

    $checkStudentResult = $checkStudentStmt->get_result();

    if ($checkStudentResult->num_rows === 0) {
        $studentExists = false;
    }

    $checkStudentStmt->close();
}

/* =========================
   TOTAL TRANSACTIONS
========================= */

$totalTransactionsQuery = "
    SELECT COUNT(*) AS total_transactions
    FROM transactions
";

$totalTransactionsResult = $conn->query($totalTransactionsQuery);
$totalTransactionsData = $totalTransactionsResult->fetch_assoc();

$totalTransactions = $totalTransactionsData['total_transactions'];


/* =========================
   TRANSACTION QUERY
========================= */

$transactionsQuery = "
    SELECT
        transaction_id,
        student_num,
        amount,
        transaction_type,
        description,
        date_time,
        canteen_id,
        cashier_id
    FROM transactions
    WHERE 1=1
";

$params = [];
$types = "";


/* Student ID filter */

if ($studentId !== '') {

    $transactionsQuery .= "
        AND student_num = ?
    ";

    $params[] = $studentId;
    $types .= "s";
}


/* Cashier ID filter */

if ($cashierId !== '') {

    $transactionsQuery .= "
        AND cashier_id = ?
    ";

    $params[] = $cashierId;
    $types .= "s";
}

if ($canteenId !== '') {

    $transactionsQuery .= "
        AND canteen_id = ?
    ";

    $params[] = $canteenId;
    $types .= "s";
}


/* Date filter */

if ($date !== '') {

    $transactionsQuery .= "
        AND DATE(date_time) = ?
    ";

    $params[] = $date;
    $types .= "s";
}


/* Newest transactions first */

$transactionsQuery .= "
    ORDER BY date_time DESC
";


$stmt = $conn->prepare($transactionsQuery);

if (!empty($params)) {
    $stmt->bind_param($types, ...$params);
}

$stmt->execute();

$transactionsResult = $stmt->get_result();

?>


<!DOCTYPE html>

<html lang="en">

<head>

    <meta charset="UTF-8">

    <meta
        name="viewport"
        content="width=device-width, initial-scale=1.0"
    >

    <title>Transactions - EduPocket</title>

    <link
        rel="stylesheet"
        href="style.css"
    >

</head>


<body>


<div class="app">

<aside class="sidebar">

        <div class="brand">

            <div class="logo">
                E
            </div>

            <div>

                <div class="brand-title">
                    EduPocket
                </div>

                <span class="brand-subtitle">
                    Super Admin
                </span>

            </div>

        </div>


        <div class="nav-title">
            User Management
        </div>


        <nav class="nav">

            <button
                onclick="window.location.href='index.php'"
            >
                <span class="nav-icon">⌂</span>
                Dashboard
            </button>


            <button
                onclick="window.location.href='students.php'"
            >
                <span class="nav-icon"></span>
                Students
            </button>


            <button
                onclick="window.location.href='parents.php'"
            >
                <span class="nav-icon"></span>
                Parents / Guardians
            </button>


            <button
                onclick="window.location.href='pos_cashiers.php'"
            >
                <span class="nav-icon"></span>
                POS / Cashiers
            </button>

        </nav>


        <div class="nav-title finance-title">
            Transaction Records
        </div>


        <nav class="nav">

            <button
                onclick="window.location.href='topups.php'"
            >
                <span class="nav-icon">₱</span>
                Top-Ups
            </button>


            <button
            class="active"
                onclick="window.location.href='transactions.php'"
            >
                <span class="nav-icon">▥</span>
                Transactions
            </button>

        </nav>


        <div class="sidebar-footer">

            <div class="admin-card">

                <div class="avatar">
                    R
                </div>

                <div>

                    <strong>
                        Rexie
                    </strong>

                    <small>
                        Super Administrator
                    </small>

                </div>

            </div>

        </div>

    </aside>



    <!-- =========================
         MAIN CONTENT
    ========================== -->

    <main style="width:100%;">


        <!-- TOPBAR -->

        <div class="topbar">

            <div>

                <div class="eyebrow">
                    Transaction Records
                </div>

                <h1>
                    Transaction History
                </h1>

            </div>

        </div>



        <!-- =========================
             SUMMARY
        ========================== -->

            <!-- =========================
                 FILTERS
            ========================== -->

            <div
                style="
                    padding: 0px 0px 10px 0px;
                "
            >

                <form
                    method="GET"
                    style="
                        display:flex;
                        gap:10px;
                        align-items:flex-end;
                        flex-wrap:wrap;
                    "
                >


                    <!-- STUDENT ID -->

                    <div
                        class="form-group"
                        style="margin:0;"
                    >

                        <label>
                            Student ID
                        </label>

                        <input
                            type="text"
                            name="student_id"
                            placeholder="Enter Student ID"
                            value="<?php
                                echo htmlspecialchars(
                                    $studentId
                                );
                            ?>"
                        >

                    </div>



                    <!-- CANTEEN ID -->

                    <div
                        class="form-group"
                        style="margin:0;"
                    >

                        <label>
                            Canteen ID
                        </label>

                        <input
                            type="text"
                            name="canteen_id"
                            placeholder="Enter Canteen ID"
                            value="<?php
                                echo htmlspecialchars(
                                    $canteenId
                                );
                            ?>"
                        >

                    </div>


                    <div
                        class="form-group"
                        style="margin:0;"
                    >

                        <label>
                            Cashier ID
                        </label>

                        <input
                            type="text"
                            name="cashier_id"
                            placeholder="Enter Cashier ID"
                            value="<?php
                                echo htmlspecialchars(
                                    $cashierId
                                );
                            ?>"
                        >

                    </div>



                    <!-- DATE -->

                    <div
                        class="form-group"
                        style="margin:0;"
                    >

                        <label>
                            Date
                        </label>

                        <input
                            type="date"
                            name="date"
                            value="<?php
                                echo htmlspecialchars(
                                    $date
                                );
                            ?>"
                        >

                    </div>



                    <!-- FILTER BUTTON -->

                    <button
                        type="submit"
                        class="add-student-btn"
                    >
                        Filter
                    </button>



                    <!-- CLEAR BUTTON -->

                    <a
                        href="transactions.php"
                        class="cancel-btn"
                        style="
                            text-decoration:none;
                            display:flex;
                            align-items:center;
                            justify-content:center;
                            height:48px;
                            box-sizing:border-box;
                        "
                    >
                        Clear
                    </a>


                </form>

            </div>



        <!-- =========================
             TRANSACTION CARD
        ========================== -->

        <section class="card table-card">

            <!-- =========================
                 TABLE
            ========================== -->

            <div class="table-wrapper">

                <table id="usersTable">

                    <thead>

                        <tr>

                            <th>
                                Transaction ID
                            </th>

                            <th>
                                Student ID
                            </th>

                            <th>
                                Cashier ID
                            </th>

                            <th>
                                Canteen ID
                            </th>

                            <th>
                                Type
                            </th>

                            <th>
                                Description
                            </th>

                            <th>
                                Amount
                            </th>

                            <th>
                                Date & Time
                            </th>

                        </tr>

                    </thead>


                    <tbody>


                    <?php if ($transactionsResult->num_rows > 0): ?>


                        <?php while (
                            $transaction =
                                $transactionsResult->fetch_assoc()
                        ): ?>


                            <tr>


                                <!-- TRANSACTION ID -->

                                <td>

                                    <?php
                                    echo htmlspecialchars(
                                        $transaction['transaction_id']
                                    );
                                    ?>

                                </td>



                                <!-- STUDENT ID -->

                                <td>

                                    <?php
                                    echo htmlspecialchars(
                                        $transaction['student_num']
                                    );
                                    ?>

                                </td>



                                <!-- CASHIER ID -->

                                <td>

                                    <?php

                                    echo htmlspecialchars(
                                        $transaction['cashier_id']
                                            ?? 'N/A'
                                    );

                                    ?>

                                </td>

                                <td>

                                    <?php

                                    echo htmlspecialchars(
                                        $transaction['canteen_id']
                                            ?? 'N/A'
                                    );

                                    ?>

                                </td>



                                <!-- TYPE -->

                                <td>

                                    <?php
                                    echo htmlspecialchars(
                                        $transaction['transaction_type']
                                    );
                                    ?>

                                </td>



                                <!-- DESCRIPTION -->

                                <td>

                                    <?php

                                    echo htmlspecialchars(
                                        $transaction['description']
                                            ?? 'N/A'
                                    );

                                    ?>

                                </td>



                                <!-- AMOUNT -->

                                <td>

                                    PHP
                                    <?php

                                    echo number_format(
                                        (float)$transaction['amount'],
                                        2
                                    );

                                    ?>

                                </td>



                                <!-- DATE -->

                                <td>

                                    <?php

                                    echo htmlspecialchars(
                                        $transaction['date_time']
                                    );

                                    ?>

                                </td>


                            </tr>


                        <?php endwhile; ?>


                    <?php else: ?>

    <tr>

        <td
            colspan="8"
            style="
                text-align:center;
                padding:30px;
                color:#777;
            "
        >

            <?php if (!$studentExists): ?>

                Student ID does not exist.

            <?php else: ?>

                No transactions found.

            <?php endif; ?>

        </td>

    </tr>

<?php endif; ?>


                    </tbody>

                </table>

            </div>


        </section>


    </main>


</div>


</body>

</html>