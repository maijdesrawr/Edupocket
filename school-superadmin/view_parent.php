<?php

error_reporting(E_ALL);
ini_set('display_errors', 1);

require_once "db.php";



$parent_id = trim(
    $_GET["parent_id"] ?? ""
);


if (empty($parent_id)) {

    die("Parent ID is required.");

}



$stmt = $conn->prepare("
    SELECT
        parent_id,
        Fname,
        first_name,
        middle_name,
        last_name,
        suffix,
        email
    FROM parents
    WHERE parent_id = ?
");

$stmt->bind_param(
    "s",
    $parent_id
);

$stmt->execute();

$result = $stmt->get_result();

$parent = $result->fetch_assoc();


if (!$parent) {

    die("Parent not found.");

}



$studentStmt = $conn->prepare("
    SELECT
        s.student_num,
        s.Fname,
        s.first_name,
        s.middle_name,
        s.last_name,
        s.suffix,
        s.balance,
        s.transaction_limit,
        s.transaction_limit_period,
        s.is_frozen
    FROM parent_student_link l
    INNER JOIN students s
        ON l.student_num = s.student_num
    WHERE l.parent_id = ?
    ORDER BY s.student_num ASC
");

$studentStmt->bind_param(
    "s",
    $parent_id
);

$studentStmt->execute();

$students = $studentStmt->get_result();



$name = $parent["Fname"];

$words = explode(
    " ",
    trim($name)
);

$initials = "";

foreach ($words as $word) {

    if (!empty($word)) {

        $initials .= strtoupper(
            substr($word, 0, 1)
        );

    }

}

$initials = substr(
    $initials,
    0,
    2
);

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
        View Parent
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
                <span class="nav-icon">
                    ⌂
                </span>

                Dashboard
            </button>


            <button
                onclick="window.location.href='students.php'"
            >
                <span class="nav-icon"></span>

                Students
            </button>


            <button
                class="active"
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
                <span class="nav-icon">
                    ₱
                </span>

                Top-Ups
            </button>


            <button
                onclick="window.location.href='transactions.php'"
            >
                <span class="nav-icon">
                    ▥
                </span>

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
                    Parent / Guardian Account
                </div>

                <h1>
                    Parent Details
                </h1>

            </div>

        </div>



        <section class="card">


            <div style="padding:25px;">



                <div class="user-cell">

                    <div class="avatar">

                        <?php

                        echo htmlspecialchars(
                            $initials
                        );

                        ?>

                    </div>


                    <h2>

                        <?php

                        echo htmlspecialchars(
                            $parent["Fname"]
                        );

                        ?>

                    </h2>

                </div>



                <p>

                    <strong>
                        Parent ID:
                    </strong>

                    <?php

                    echo htmlspecialchars(
                        $parent["parent_id"]
                    );

                    ?>

                </p>



                <p>

                    <strong>
                        First Name:
                    </strong>

                    <?php

                    echo htmlspecialchars(
                        $parent["first_name"]
                    );

                    ?>

                </p>



                <p>

                    <strong>
                        Middle Name:
                    </strong>

                    <?php

                    echo htmlspecialchars(
                        $parent["middle_name"] ?? ""
                    );

                    ?>

                </p>



                <p>

                    <strong>
                        Last Name:
                    </strong>

                    <?php

                    echo htmlspecialchars(
                        $parent["last_name"]
                    );

                    ?>

                </p>



                <p>

                    <strong>
                        Suffix:
                    </strong>

                    <?php

                    echo htmlspecialchars(
                        $parent["suffix"] ?? ""
                    );

                    ?>

                </p>



                <p>

                    <strong>
                        Email:
                    </strong>

                    <?php

                    echo htmlspecialchars(
                        $parent["email"] ?? ""
                    );

                    ?>

                </p>



                <p>

                    <strong>
                        Linked Students:
                    </strong>

                    <?php

                    echo $students->num_rows;

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
                    Linked Students
                </h2>

            </div>


            <div class="table-wrapper">

                <table>

                    <thead>

                        <tr>

                            <th>
                                Student Number
                            </th>

                            <th>
                                Student Name
                            </th>

                            <th>
                                Balance
                            </th>

                            <th>
                                Transaction Limit
                            </th>

                            <th>
                                Account Status
                            </th>

                        </tr>

                    </thead>


                    <tbody>


                    <?php

                    if ($students->num_rows > 0) {

                        while (
                            $student =
                            $students->fetch_assoc()
                        ) {

                            $studentName =
                                $student["Fname"];

                    ?>


                    <tr>



                        <td>

                            <?php

                            echo htmlspecialchars(
                                $student["student_num"]
                            );

                            ?>

                        </td>



                        <td>

                            <?php

                            echo htmlspecialchars(
                                $studentName
                            );

                            ?>

                        </td>



                        <td>

                            ₱<?php

                            echo number_format(
                                (float)$student["balance"],
                                2
                            );

                            ?>

                        </td>



                        <td>

                            ₱<?php

                            echo number_format(
                                (float)$student["transaction_limit"],
                                2
                            );

                            ?>


                            /


                            <?php

                            echo htmlspecialchars(
                                $student[
                                    "transaction_limit_period"
                                ]
                            );

                            ?>

                        </td>



                        <td>

                            <?php

                            if (
                                $student["is_frozen"]
                            ) {

                                echo '
                                    <span
                                        style="
                                            color:#f59e0b;
                                            font-weight:600;
                                        "
                                    >
                                        Frozen
                                    </span>
                                ';

                            } else {

                                echo '
                                    <span
                                        style="
                                            color:green;
                                            font-weight:600;
                                        "
                                    >
                                        Active
                                    </span>
                                ';

                            }

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

                            No linked students found.

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
                onclick="window.location.href='parents.php'"
            >
                ← Back to Parents
            </button>

        </div>


    </main>

</div>

</body>

</html>