<?php

error_reporting(E_ALL);
ini_set('display_errors', 1);

require_once "db.php";



$admin_id = trim(
    $_GET["admin_id"] ?? ""
);


if (empty($admin_id)) {

    die("Admin ID is required.");

}



$stmt = $conn->prepare("
    SELECT
        admin_id,
        Fname,
        role,
        username,
        password,
        pin,
        canteen_id,
        profile_photo
    FROM admins
    WHERE admin_id = ?
");

$stmt->bind_param(
    "s",
    $admin_id
);

$stmt->execute();

$result = $stmt->get_result();

$admin = $result->fetch_assoc();


if (!$admin) {

    die("Admin not found.");

}



$canteenName = "None";

if (!empty($admin["canteen_id"])) {

    $canteenStmt = $conn->prepare("
        SELECT Fname
        FROM canteens
        WHERE canteen_id = ?
    ");

    $canteenStmt->bind_param(
        "s",
        $admin["canteen_id"]
    );

    $canteenStmt->execute();

    $canteenResult = $canteenStmt->get_result();

    $canteen = $canteenResult->fetch_assoc();

    if ($canteen) {

        $canteenName = $canteen["Fname"];

    }

    $canteenStmt->close();

}

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
        View Admin
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


        <button
            class="active"
            onclick="window.location.href='admins.php'"
        >
            <span class="nav-icon"></span>

            Admins
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
                Admin Account
            </div>

            <h1>
                Admin Details
            </h1>

        </div>

    </div>




    <section class="card">


        <div style="padding:25px;">

        <?php

        $name = $admin["Fname"];

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
                    $admin["Fname"]
                );

                ?>

            </h2>

        </div>




        <p>

            <strong>
                Admin ID:
            </strong>

            <?php

            echo htmlspecialchars(
                $admin["admin_id"]
            );

            ?>

        </p>




        <p>

            <strong>
                Full Name:
            </strong>

            <?php

            echo htmlspecialchars(
                $admin["Fname"]
            );

            ?>

        </p>




        <p>

            <strong>
                Username:
            </strong>

            <?php

            echo htmlspecialchars(
                $admin["username"]
            );

            ?>

        </p>




        <p>

            <strong>
                Role:
            </strong>

            <?php

            echo htmlspecialchars(
                ucwords($admin["role"])
            );

            ?>

        </p>




        <p>

            <strong>
                Canteen ID:
            </strong>

            <?php

            if (!empty($admin["canteen_id"])) {

                echo htmlspecialchars(
                    $admin["canteen_id"]
                );

            } else {

                echo "None";

            }

            ?>

        </p>




        <p>

            <strong>
                Assigned Canteen:
            </strong>

            <?php

            echo htmlspecialchars(
                $canteenName
            );

            ?>

        </p>




        <p>

            <strong>
                Password:
            </strong>

            ••••••••

        </p>




        <p>

            <strong>
                Security PIN:
            </strong>

            <?php

            if (!empty($admin["pin"])) {

                echo "Set";

            } else {

                echo "Not Set";

            }

            ?>

        </p>




        <p>

            <strong>
                Account Status:
            </strong>

            <span style="color:green;">
                Active
            </span>

        </p>


        </div>

    </section>




    <div style="margin-top:20px;">

        <button
            class="save-btn"
            onclick="window.location.href='admins.php'"
        >
            ← Back to Admins
        </button>

    </div>


</main>


</div>

</body>

</html>