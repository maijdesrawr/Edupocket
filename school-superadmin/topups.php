<?php

require_once "db.php";

$parentId = trim($_GET['parent_id'] ?? '');
$studentId = trim($_GET['student_id'] ?? '');
$cashierId = trim($_GET['cashier_id'] ?? '');
$date = trim($_GET['date'] ?? '');

$totalTopupsQuery = "
    SELECT COUNT(*) AS total_topups
    FROM topups
";

$totalTopupsResult = $conn->query($totalTopupsQuery);
$totalTopupsData = $totalTopupsResult->fetch_assoc();

$totalTopups = $totalTopupsData['total_topups'];

$topupsQuery = "
    SELECT
        t.topup_id,
        t.transaction_id,
        t.parent_id,
        tr.cashier_id,
        t.student_num,
        t.amount,
        t.method,
        t.status,
        t.date_time
    FROM topups t
    LEFT JOIN transactions tr
        ON t.transaction_id = tr.transaction_id
    WHERE 1=1
";

$params = [];
$types = "";

if ($parentId !== '') {
    $topupsQuery .= " AND t.parent_id = ?";
    $params[] = $parentId;
    $types .= "s";
}


if ($studentId !== '') {
    $topupsQuery .= " AND t.student_num = ?";
    $params[] = $studentId;
    $types .= "s";
}

if ($cashierId !== '') {
    $topupsQuery .= " AND tr.cashier_id = ?";
    $params[] = $cashierId;
    $types .= "s";
}

if ($date !== '') {
    $topupsQuery .= " AND DATE(t.date_time) = ?";
    $params[] = $date;
    $types .= "s";
}


$topupsQuery .= " ORDER BY t.date_time DESC";

$stmt = $conn->prepare($topupsQuery);

if (!empty($params)) {
    $stmt->bind_param($types, ...$params);
}

$stmt->execute();
$topupsResult = $stmt->get_result();

?>

<!DOCTYPE html>

<html lang="en">

<head>

    <meta charset="UTF-8">

    <meta
        name="viewport"
        content="width=device-width, initial-scale=1.0"
    >

    <title>Top-Ups - EduPocket</title>

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
                class="active"
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
                    Transaction Records
                </div>

                <h1>
                    Top-Up History
                </h1>

            </div>

        </div>


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

                <div
                    class="form-group"
                    style="margin:0;"
                >

                    <label>
                        Parent ID
                    </label>

                    <input
                        type="text"
                        name="parent_id"
                        placeholder="Enter Parent ID"
                        value="<?php

                            echo htmlspecialchars(
                                $parentId
                            );

                        ?>"
                    >

                </div>

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
                        value="<?php echo htmlspecialchars($cashierId); ?>"
                    >
                </div>

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

                <button
                    type="submit"
                    class="add-student-btn"
                >
                    Filter
                </button>

                <a
                    href="topups.php"
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

        <section class="card table-card">


            <div class="table-wrapper">

                <table id="usersTable">

                    <thead>

                        <tr>

                            <th>
                                Top-Up ID
                            </th>

                            <th>
                                Parent ID
                            </th>

                            <th>
                                Student ID
                            </th>

                            <th>
                                Cashier ID
                            </th>

                            <th>
                                Amount
                            </th>

                            <th>
                                Method
                            </th>

                            <th>
                                Status
                            </th>

                            <th>
                                Date & Time
                            </th>

                        </tr>

                    </thead>


                    <tbody>


                    <?php if ($topupsResult->num_rows > 0): ?>


                        <?php while (
                            $topup =
                                $topupsResult->fetch_assoc()
                        ): ?>


                            <tr>



                                <td>

                                    <?php

                                    echo htmlspecialchars(
                                        $topup['topup_id']
                                    );

                                    ?>

                                </td>




                                <td>

                                    <?php

                                    echo htmlspecialchars(
                                        $topup['parent_id']
                                            ?? 'N/A'
                                    );

                                    ?>

                                </td>




                                <td>

                                    <?php

                                    echo htmlspecialchars(
                                        $topup['student_num']
                                    );

                                    ?>

                                </td>

                                <td>

                                    <?php

                                    echo htmlspecialchars($topup['cashier_id'] ?? 'N/A');

                                    ?>

                                </td>




                                <td>

                                    PHP
                                    <?php

                                    echo number_format(
                                        (float)$topup['amount'],
                                        2
                                    );

                                    ?>

                                </td>




                                <td>

                                    <?php

                                    echo htmlspecialchars(
                                        $topup['method']
                                    );

                                    ?>

                                </td>




                                <td>

                                    <?php

                                    echo htmlspecialchars(
                                        $topup['status']
                                    );

                                    ?>

                                </td>




                                <td>

                                    <?php

                                    echo htmlspecialchars(
                                        $topup['date_time']
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

                                No top-ups found.

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