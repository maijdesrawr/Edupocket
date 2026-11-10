<?php

error_reporting(E_ALL);
ini_set('display_errors', 1);

require_once "db.php";


$student_num = trim(
    $_GET["student_num"] ?? ""
);


if (empty($student_num)) {

    die("Student number is required.");

}

$stmt = $conn->prepare("
    SELECT
        student_num,
        Fname,
        first_name,
        middle_name,
        last_name,
        suffix,
        balance,
        transaction_limit,
        transaction_limit_period,
        parent_id,
        qr_code,
        is_frozen,
        is_locked
    FROM students
    WHERE student_num = ?
");

$stmt->bind_param(
    "s",
    $student_num
);

$stmt->execute();

$result = $stmt->get_result();

$student = $result->fetch_assoc();


if (!$student) {

    die("Student not found.");

}

$transactionStmt = $conn->prepare("
    SELECT
        transaction_id,
        amount,
        transaction_type,
        description,
        date_time,
        canteen_id,
        cashier_id
    FROM transactions
    WHERE student_num = ?
    ORDER BY date_time DESC
");

$transactionStmt->bind_param(
    "s",
    $student_num
);

$transactionStmt->execute();

$transactions =
    $transactionStmt->get_result();

?>

<!DOCTYPE html>
<html lang="en">

<head>

    <meta charset="UTF-8">

    <meta
        name="viewport"
        content="width=device-width, initial-scale=1.0"
    >

    <title>
        View Student
    </title>

    <link
        rel="stylesheet"
        href="style.css?v=<?php echo time(); ?>"
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
                class="active"
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

    <main style="width:100%;">

        <div class="topbar">

            <div>

                <div class="eyebrow">
                    Student Account
                </div>

                <h1>
                    Student Details
                </h1>

            </div>

        </div>


        <section class="card">


            <div style="padding:25px;">

            <?php
$name = $student["Fname"];

$words = explode(" ", trim($name));
$initials = "";

foreach ($words as $word) {
    if (!empty($word)) {
        $initials .= strtoupper(substr($word, 0, 1));
    }
}

$initials = substr($initials, 0, 2);
?>

            <div class="user-cell">
    <div class="avatar">
        <?php echo htmlspecialchars($initials); ?>
    </div>

    <h2>
        <?php echo htmlspecialchars($student["Fname"]); ?>
    </h2>
</div>
            
                <p>
                    <strong>
                        Student Number:
                    </strong>

                    <?php
                    echo htmlspecialchars(
                        $student["student_num"]
                    );
                    ?>

                </p>


                <p>
                    <strong>
                        First Name:
                    </strong>

                    <?php
                    echo htmlspecialchars(
                        $student["first_name"]
                    );
                    ?>

                </p>


                <p>
                    <strong>
                        Middle Name:
                    </strong>

                    <?php
                    echo htmlspecialchars(
                        $student["middle_name"] ?? ""
                    );
                    ?>

                </p>


                <p>
                    <strong>
                        Last Name:
                    </strong>

                    <?php
                    echo htmlspecialchars(
                        $student["last_name"]
                    );
                    ?>

                </p>


                <p>
                    <strong>
                        Balance:
                    </strong>

                    ₱<?php
                    echo number_format(
                        (float)$student["balance"],
                        2
                    );
                    ?>

                </p>


                <p>
                    <strong>
                        Parent ID:
                    </strong>

                    <?php

                    echo htmlspecialchars(
                        $student["parent_id"] ?? "None"
                    );

                    ?>

                </p>


                <p>
                    <strong>
                        Transaction Limit:
                    </strong>

                    ₱<?php

                    echo number_format(
                        (float)$student["transaction_limit"],
                        2
                    );

                    ?>

                    /
                    <?php

                    echo htmlspecialchars(
                        $student["transaction_limit_period"]
                    );

                    ?>

                </p>


                <p>

                    <strong>
                        Account Status:
                    </strong>

                    <?php

                    if ($student["is_frozen"]) {

                        echo '<span style="color:#f59e0b;">
                                Frozen
                              </span>';
                    }
                    elseif ($student["is_locked"]) {
                        echo '<span style="color:#ef4444;">
                                Locked
                            </span>';
                    }

                    else {

                        echo '<span style="color:green;">
                                Active
                              </span>';

                    }

                    ?>

                </p>

            </div>

        </section>



        <section
            class="card"
            style="margin-top:20px;"
        >

            <div class="card-header">

                <h2>
                    Transaction History
                </h2>

            </div>


            <div class="table-wrapper">

                <table>

                    <thead>

                        <tr>

                            <th>
                                Transaction ID
                            </th>

                            <th>
                                Amount
                            </th>

                            <th>
                                Type
                            </th>

                            <th>
                                Description
                            </th>

                            <th>
                                Date
                            </th>

                        </tr>

                    </thead>


                    <tbody>

                    <?php

                    if ($transactions->num_rows > 0) {

                        while (
                            $transaction =
                            $transactions->fetch_assoc()
                        ) {

                    ?>

                    <tr>

                        <td>

                            <?php
                            echo htmlspecialchars(
                                $transaction["transaction_id"]
                            );
                            ?>

                        </td>


                        <td>

                            ₱<?php

                            echo number_format(
                                (float)$transaction["amount"],
                                2
                            );

                            ?>

                        </td>


                        <td>

                            <?php
                            echo htmlspecialchars(
                                $transaction["transaction_type"]
                            );
                            ?>

                        </td>


                        <td>

                            <?php
                            echo htmlspecialchars(
                                $transaction["description"] ?? ""
                            );
                            ?>

                        </td>


                        <td>

                            <?php
                            echo htmlspecialchars(
                                $transaction["date_time"]
                            );
                            ?>

                        </td>

                    </tr>

                    <?php

                        }

                    } else {

                    ?>

                    <tr>

                        <td
                            colspan="5"
                            style="text-align:center;"
                        >
                            No transactions found.
                        </td>

                    </tr>

                    <?php

                    }

                    ?>

                    </tbody>

                </table>

            </div>

        </section>


        <div style="margin-top:20px;">

            <button
                class="save-btn"
                onclick="window.location.href='students.php'"
            >
                ← Back to Students
            </button>

        </div>

    </main>

</div>

</body>

</html>