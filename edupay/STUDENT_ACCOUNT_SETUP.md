# Admin student account setup

## Dummy directory

Import `dummy_student_directory.sql` into the same database configured for EduPocket. It creates a development-only roster with synthetic students. Each QR value is `QR_` followed by the 11-digit student number. Sample parent first and last names are included; parent middle name and suffix are nullable and optional.

If `dummy_student_directory` already exists from an earlier version, run `dummy_student_directory_parent_columns.sql` once against that database to add the parent fields and fill the three sample records.

The admin **Add Child** and **Create Family Account** forms scan the QR, load the matching directory record, and use the existing student mailbox in the form `lastname.firstname@ue.edu.ph`. The application does not create or provision UE mailboxes. The server accepts only records in this directory and only sends to the `@ue.edu.ph` domain.

## Email delivery

Student credentials use the existing SMTP sender callback in `C:/xampp/edupocket-config/security.php`; no second set of SMTP credentials is required. The callback must support the `student_account_credentials` message context used by the account-creation endpoint.

The student ID and temporary login password are emailed after the account is created. The email is saved as the student's verified address so the existing email-based login verification can use it. If email delivery fails, the account transaction is rolled back.

Do not enable real email delivery while testing the synthetic roster unless you have confirmed the generated UE mailboxes are controlled test inboxes. Replace the dummy directory with an authorized student roster before production use.
