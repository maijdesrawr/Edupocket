UPDATE transactions t
LEFT JOIN topups tp
    ON tp.transaction_id = t.transaction_id
LEFT JOIN student_transfers transfer_out
    ON transfer_out.sender_transaction_id = t.transaction_id
LEFT JOIN student_transfers transfer_in
    ON transfer_in.recipient_transaction_id = t.transaction_id
LEFT JOIN canteens canteen_account
    ON BINARY canteen_account.canteen_id = BINARY t.canteen_id
LEFT JOIN cashiers cashier_account
    ON BINARY cashier_account.cashier_id = BINARY t.cashier_id
LEFT JOIN admins admin_cashier_account
    ON BINARY admin_cashier_account.admin_id = BINARY t.cashier_id
   AND LOWER(COALESCE(admin_cashier_account.role, '')) = 'cashier'
SET
    t.processor_role = COALESCE(
        NULLIF(LOWER(TRIM(t.processor_role)), ''),
        CASE
            WHEN t.transaction_type IN ('transfer-out', 'transfer-in')
             AND COALESCE(transfer_out.sender_student_num, transfer_in.sender_student_num) IS NOT NULL
                THEN 'student'
            WHEN t.transaction_type = 'payment'
             AND NULLIF(TRIM(t.canteen_id), '') IS NOT NULL
             AND canteen_account.canteen_id IS NOT NULL
                THEN 'canteen'
            WHEN NULLIF(TRIM(t.cashier_id), '') IS NOT NULL
             AND ((cashier_account.cashier_id IS NOT NULL) <> (admin_cashier_account.admin_id IS NOT NULL))
                THEN 'cashier'
            WHEN t.transaction_type = 'top-up'
             AND NULLIF(TRIM(tp.parent_id), '') IS NOT NULL
                THEN 'parent'
            ELSE NULL
        END
    ),
    t.processor_account_source = COALESCE(
        NULLIF(LOWER(TRIM(t.processor_account_source)), ''),
        CASE
            WHEN t.transaction_type IN ('transfer-out', 'transfer-in')
             AND COALESCE(transfer_out.sender_student_num, transfer_in.sender_student_num) IS NOT NULL
                THEN 'students'
            WHEN t.transaction_type = 'payment'
             AND NULLIF(TRIM(t.canteen_id), '') IS NOT NULL
             AND canteen_account.canteen_id IS NOT NULL
                THEN 'canteens'
            WHEN NULLIF(TRIM(t.cashier_id), '') IS NOT NULL
             AND cashier_account.cashier_id IS NOT NULL
             AND admin_cashier_account.admin_id IS NULL
                THEN 'cashiers'
            WHEN NULLIF(TRIM(t.cashier_id), '') IS NOT NULL
             AND admin_cashier_account.admin_id IS NOT NULL
             AND cashier_account.cashier_id IS NULL
                THEN 'admins'
            WHEN t.transaction_type = 'top-up'
             AND NULLIF(TRIM(tp.parent_id), '') IS NOT NULL
                THEN 'parents'
            ELSE NULL
        END
    ),
    t.processor_id = COALESCE(
        NULLIF(TRIM(t.processor_id), ''),
        CASE
            WHEN t.transaction_type IN ('transfer-out', 'transfer-in')
                THEN COALESCE(transfer_out.sender_student_num, transfer_in.sender_student_num)
            WHEN t.transaction_type = 'payment'
             AND NULLIF(TRIM(t.canteen_id), '') IS NOT NULL
             AND canteen_account.canteen_id IS NOT NULL
                THEN t.canteen_id
            WHEN NULLIF(TRIM(t.cashier_id), '') IS NOT NULL
             AND ((cashier_account.cashier_id IS NOT NULL) <> (admin_cashier_account.admin_id IS NOT NULL))
                THEN t.cashier_id
            WHEN t.transaction_type = 'top-up'
             AND NULLIF(TRIM(tp.parent_id), '') IS NOT NULL
                THEN tp.parent_id
            ELSE NULL
        END
    )
WHERE NULLIF(TRIM(t.processor_role), '') IS NULL
  AND NULLIF(TRIM(t.processor_account_source), '') IS NULL
  AND NULLIF(TRIM(t.processor_id), '') IS NULL;
