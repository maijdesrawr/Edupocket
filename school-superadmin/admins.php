<?php

error_reporting(E_ALL);
ini_set('display_errors', 1);

require_once "db.php";


$adminCountQuery = "
    SELECT COUNT(*) AS total_admins
    FROM admins
";

$adminCountResult = $conn->query($adminCountQuery);

$totalAdmins = 0;

if ($adminCountResult) {
    $row = $adminCountResult->fetch_assoc();
    $totalAdmins = $row["total_admins"];
}



$adminsQuery = "
    SELECT
        admin_id,
        Fname,
        role,
        profile_photo
    FROM admins
    ORDER BY admin_id DESC
";

$admins = $conn->query($adminsQuery);

if (!$admins) {
    die("Error loading admins: " . $conn->error);
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

    <title>Admin Accounts</title>

    <link
        rel="stylesheet"
        href="style.css?v=<?php echo time(); ?>"
    >

    <style>


        .modal {
            display: none;
            position: fixed;
            z-index: 9999;
            inset: 0;
            background: rgba(0, 0, 0, 0.45);

            align-items: center;
            justify-content: center;
        }

        .modal-content {
            width: 450px;
            max-width: 90%;
            max-height: 90vh;
            overflow-y: auto;

            background: var(--white);
            border-radius: 16px;
            padding: 24px;

            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
        }

        .modal-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 20px;
        }

        .modal-header h2 {
            margin: 0;
            font-size: 20px;
        }

        .close-modal {
            border: none;
            background: none;
            font-size: 25px;
            cursor: pointer;
            color: #777;
        }

        .form-group {
            margin-bottom: 15px;
        }

        .form-group label {
            display: block;
            margin-bottom: 6px;
            font-size: 14px;
            font-weight: 600;
        }

        .form-group input,
        .form-group select {
            width: 100%;
            padding: 11px 12px;
            border: 1px solid var(--border);
            border-radius: 9px;
            outline: none;
            box-sizing: border-box;
            font-size: 14px;
        }

        .form-group input:focus,
        .form-group select:focus {
            border-color: var(--red);
        }

        .form-actions {
            display: flex;
            justify-content: flex-end;
            gap: 10px;
            margin-top: 20px;
        }

        .cancel-btn {
            border: 1px solid var(--border);
            background: white;
            color: #555;
            padding: 11px 18px;
            border-radius: 9px;
            cursor: pointer;
        }

        .save-btn {
            border: none;
            background: var(--red);
            color: white;
            padding: 11px 18px;
            border-radius: 9px;
            cursor: pointer;
            font-weight: 600;
        }

        .save-btn:hover {
            background: var(--deep-red);
        }

        .cancel-btn:hover {
            background: #f5f5f5;
        }

        .required {
            color: var(--red);
        }

        .canteen-note {
            font-size: 12px;
            color: #777;
            margin-top: 5px;
        }

    </style>

</head>


<body>


    <aside
        class="sidebar"
        id="sidebar"
    >


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



    <main>


        <div class="topbar">

            <div>

                <div class="eyebrow">
                    User Management
                </div>

                <h1>
                    Admin Accounts
                </h1>

            </div>

        </div>



        <div class="student-summary-row">

            <div class="single-total-card">

                <div class="single-total-info">

                    <div class="stat-label">
                        Total Admins
                    </div>

                    <div class="stat-number">
                        <?php echo number_format($totalAdmins); ?>
                    </div>

                    <div class="stat-trend">
                        Registered admin accounts
                    </div>

                </div>

            </div>


            <button
                class="add-student-btn"
                onclick="openAdminModal()"
            >
                <span>+</span>
                New Admin Account
            </button>

        </div>



        <section class="card table-card">

            <div class="card-header">

                <h2>
                    Registered Admin Accounts
                </h2>

            </div>


            <div class="table-wrapper">

                <table id="adminTable">

                    <thead>

                        <tr>

                            <th>
                                Admin
                            </th>

                            <th>
                                Admin ID
                            </th>

                            <th>
                                Role
                            </th>

                            <th>
                                Actions
                            </th>

                        </tr>

                    </thead>


                    <tbody>

                    <?php

                    if ($admins && $admins->num_rows > 0) {

                        while ($admin = $admins->fetch_assoc()) {

                            $adminID = $admin["admin_id"];
                            $name = $admin["Fname"];
                            $role = $admin["role"];



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

                        <tr>


                            <td>

                                <div class="user-cell">

                                    <div class="avatar">

                                        <?php
                                        echo htmlspecialchars(
                                            $initials
                                        );
                                        ?>

                                    </div>

                                    <div>

                                        <strong>

                                            <?php
                                            echo htmlspecialchars(
                                                $name
                                            );
                                            ?>

                                        </strong>

                                    </div>

                                </div>

                            </td>



                            <td>
                                <?php
                                echo htmlspecialchars(
                                    $adminID
                                );
                                ?>
                            </td>



                            <td>
                                <?php
                                echo htmlspecialchars(
                                    $role
                                );
                                ?>
                            </td>



                            <td class="action-buttons">

                                <button
                                    class="view-btn"
                                    onclick="viewAdmin('<?php echo htmlspecialchars($adminID); ?>')"
                                >
                                    View
                                </button>


                                <button
                                    class="delete-btn"
                                    onclick="deleteAdmin('<?php echo htmlspecialchars($adminID); ?>')"
                                >
                                    Delete
                                </button>

                            </td>

                        </tr>

                    <?php

                        }

                    } else {

                    ?>

                        <tr>

                            <td
                                colspan="6"
                                style="text-align: center;"
                            >
                                No admin accounts found.
                            </td>

                        </tr>

                    <?php

                    }

                    ?>

                    </tbody>

                </table>

            </div>

        </section>

    </main>



    <div
        class="modal"
        id="adminModal"
    >

        <div class="modal-content">

            <div class="modal-header">

                <h2>
                    New Admin Account
                </h2>

                <button
                    type="button"
                    class="close-modal"
                    onclick="closeAdminModal()"
                >
                    ×
                </button>

            </div>


            <form
                id="adminForm"
            >


                <div class="form-group">

                    <label>
                        Admin ID
                        <span class="required">*</span>
                    </label>

                    <input
                        type="text"
                        name="admin_id"
                        placeholder="Example: A3004"
                        required
                    >

                </div>



                <div class="form-group">

                    <label>
                        Full Name
                        <span class="required">*</span>
                    </label>

                    <input
                        type="text"
                        name="name"
                        placeholder="Enter full name"
                        required
                    >

                </div>



                <div class="form-group">

                    <label>
                        Role
                        <span class="required">*</span>
                    </label>

                    <select
                        name="role"
                        required
                    >

                        <option value="">
                            Select role
                        </option>

                        <option value="system admin">
                            System Admin
                        </option>

                        <option value="cashier">
                            Cashier
                        </option>

                        <option value="registrar">
                            Registrar
                        </option>

                    </select>

                </div>



                <div class="form-group">

                    <label>
                        Password
                        <span class="required">*</span>
                    </label>

                    <input
                        type="password"
                        name="password"
                        placeholder="Enter password"
                        required
                    >

                </div>



                <div class="form-actions">

                    <button
                        type="button"
                        class="cancel-btn"
                        onclick="closeAdminModal()"
                    >
                        Cancel
                    </button>


                    <button
                        type="submit"
                        class="save-btn"
                    >
                        Create Admin
                    </button>

                </div>

            </form>

        </div>

    </div>



    <script>


        function openAdminModal() {

            document.getElementById("adminModal").style.display = "flex";

        }



        function closeAdminModal() {

            document.getElementById("adminModal").style.display = "none";

            document.getElementById("adminForm").reset();

        }



        window.addEventListener("click", function(event) {

            const modal = document.getElementById("adminModal");

            if (event.target === modal) {

                closeAdminModal();

            }

        });



        document.getElementById("adminForm").addEventListener(
            "submit",
            function(event) {

                event.preventDefault();

                const form = this;

                const formData = new FormData(form);

                const button = form.querySelector(
                    ".save-btn"
                );

                button.disabled = true;
                button.textContent = "Creating...";


                fetch("add_admin.php", {

                    method: "POST",

                    body: formData

                })

                .then(function(response) {

                    return response.json();

                })

                .then(function(data) {

                    alert(data.message);

                    if (data.success) {

                        closeAdminModal();

                        window.location.reload();

                    }

                })

                .catch(function(error) {

                    console.error(error);

                    alert(
                        "Something went wrong while creating the admin account."
                    );

                })

                .finally(function() {

                    button.disabled = false;
                    button.textContent = "Create Admin";

                });

            }
        );



        function viewAdmin(adminID) {

            window.location.href =
                "view_admin.php?admin_id=" +
                encodeURIComponent(adminID);

        }



        function deleteAdmin(adminID) {

            if (
                !confirm(
                    "Are you sure you want to delete this admin account?"
                )
            ) {

                return;

            }

            window.location.href =
                "delete_admin.php?admin_id=" +
                encodeURIComponent(adminID);

        }



        function searchAdmins(searchValue) {

            const search = searchValue
                .trim()
                .toLowerCase();

            const rows = document.querySelectorAll(
                "#adminTable tbody tr"
            );

            rows.forEach(function(row) {

                const text = row.textContent
                    .toLowerCase();

                if (text.includes(search)) {

                    row.style.display = "";

                } else {

                    row.style.display = "none";

                }

            });

        }

    </script>

</body>

</html>