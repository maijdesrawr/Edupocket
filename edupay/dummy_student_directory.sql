CREATE TABLE IF NOT EXISTS `dummy_student_directory` (
  `student_num` varchar(20) NOT NULL,
  `first_name` varchar(50) NOT NULL,
  `middle_name` varchar(50) DEFAULT NULL,
  `last_name` varchar(50) NOT NULL,
  `suffix` varchar(10) DEFAULT NULL,
  `parent_first_name` varchar(50) NOT NULL,
  `parent_middle_name` varchar(50) DEFAULT NULL,
  `parent_last_name` varchar(50) NOT NULL,
  `parent_suffix` varchar(10) DEFAULT NULL,
  `qr_code` varchar(255) NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`student_num`),
  UNIQUE KEY `uq_dummy_student_directory_qr_code` (`qr_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `dummy_student_directory`
  (`student_num`, `first_name`, `middle_name`, `last_name`, `suffix`,
   `parent_first_name`, `parent_middle_name`, `parent_last_name`, `parent_suffix`,
   `qr_code`, `is_active`)
VALUES
  ('00000000001', 'Demo', NULL, 'Student', NULL, 'Maria', NULL, 'Demo', NULL, 'QR_00000000001', 1),
  ('00000000002', 'Sample', NULL, 'Learner', NULL, 'Jose', NULL, 'Sample', NULL, 'QR_00000000002', 1),
  ('00000000003', 'Test', NULL, 'User', NULL, 'Ana', NULL, 'Test', NULL, 'QR_00000000003', 1)
ON DUPLICATE KEY UPDATE
  `first_name` = VALUES(`first_name`),
  `middle_name` = VALUES(`middle_name`),
  `last_name` = VALUES(`last_name`),
  `suffix` = VALUES(`suffix`),
  `qr_code` = VALUES(`qr_code`),
  `parent_first_name` = VALUES(`parent_first_name`),
  `parent_middle_name` = VALUES(`parent_middle_name`),
  `parent_last_name` = VALUES(`parent_last_name`),
  `parent_suffix` = VALUES(`parent_suffix`),
  `is_active` = VALUES(`is_active`);
