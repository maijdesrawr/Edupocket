ALTER TABLE `dummy_student_directory`
  ADD COLUMN `parent_first_name` varchar(50) NOT NULL DEFAULT '' AFTER `suffix`,
  ADD COLUMN `parent_middle_name` varchar(50) DEFAULT NULL AFTER `parent_first_name`,
  ADD COLUMN `parent_last_name` varchar(50) NOT NULL DEFAULT '' AFTER `parent_middle_name`,
  ADD COLUMN `parent_suffix` varchar(10) DEFAULT NULL AFTER `parent_last_name`;

UPDATE `dummy_student_directory`
SET `parent_first_name` = CASE `student_num`
      WHEN '00000000001' THEN 'Maria'
      WHEN '00000000002' THEN 'Jose'
      WHEN '00000000003' THEN 'Ana'
      ELSE `parent_first_name`
    END,
    `parent_last_name` = CASE `student_num`
      WHEN '00000000001' THEN 'Demo'
      WHEN '00000000002' THEN 'Sample'
      WHEN '00000000003' THEN 'Test'
      ELSE `parent_last_name`
    END
WHERE `student_num` IN ('00000000001', '00000000002', '00000000003');
