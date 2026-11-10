<?php
declare(strict_types=1);
require_once __DIR__ . '/login_otp_common.php';
pc_bootstrap_json_endpoint();
pc_require_post();

try {
    $conn=pc_open_database();
    $session=as_require_session($conn,false);
    if (($session['role']??'')!=='admin') pc_reject('Administrator access is required.');
    $input=json_decode((string)file_get_contents('php://input'),true);
    if(!is_array($input)) $input=$_POST;
    $type=(string)($input['type']??''); $role=(string)($input['role']??''); $source=(string)($input['source']??''); $id=trim((string)($input['user_id']??''));
    if($id==='' || !in_array($type,['login_failures','failed_transactions','account_setup'],true)) pc_reject('Invalid alert request.');
    $name='User';
    if($source==='students' && $role==='student') {
        $st=pc_prepare($conn,'SELECT COALESCE(NULLIF(TRIM(CONCAT_WS(" ",first_name,middle_name,last_name,suffix)),""),Fname,"Student") name FROM students WHERE student_num=? LIMIT 1');
        $st->bind_param('s',$id); $st->execute(); $row=$st->get_result()->fetch_assoc(); $st->close(); if(!$row) pc_reject('The account was not found.'); $name=(string)$row['name'];
    } elseif($source==='parents' && $role==='parent') {
        $st=pc_prepare($conn,'SELECT COALESCE(NULLIF(TRIM(CONCAT_WS(" ",first_name,middle_name,last_name,suffix)),""),Fname,"Parent") name FROM parents WHERE parent_id=? LIMIT 1');
        $st->bind_param('s',$id); $st->execute(); $row=$st->get_result()->fetch_assoc(); $st->close(); if(!$row) pc_reject('The account was not found.'); $name=(string)$row['name'];
    } elseif($source==='cashiers' && $role==='cashier') {
        $st=pc_prepare($conn,'SELECT COALESCE(NULLIF(Fname,""),"Cashier") name FROM cashiers WHERE cashier_id=? LIMIT 1');
        $st->bind_param('s',$id); $st->execute(); $row=$st->get_result()->fetch_assoc(); $st->close(); if(!$row) pc_reject('The account was not found.'); $name=(string)$row['name'];
    } else pc_reject('Invalid account type.');

    $lastAttemptId=0;
    if($type==='account_setup') {
        if($source!=='students' || $role!=='student' || !pc_table_exists($conn,'app_activity_events') || !pc_table_exists($conn,'admin_dashboard_alert_sends')) pc_reject('This account is not eligible for an email reminder.');
        $st=pc_prepare($conn,"SELECT 1 FROM app_activity_events e JOIN students s ON s.student_num=JSON_UNQUOTE(JSON_EXTRACT(e.metadata_json,'$.student_num')) LEFT JOIN parent_student_link l ON l.student_num=s.student_num LEFT JOIN parents p ON p.parent_id=l.parent_id LEFT JOIN admin_dashboard_alert_sends d ON d.alert_type='account_setup' AND d.account_role='student' AND d.account_source='students' AND d.user_id=s.student_num WHERE e.event_name IN ('student_family_account_created','student_account_created') AND s.student_num=? AND e.created_at<=DATE_SUB(NOW(),INTERVAL 3 DAY) AND (COALESCE(s.password_changed,0)=0 OR COALESCE(p.password_changed,1)=0) AND d.send_id IS NULL LIMIT 1"); $st->bind_param('s',$id); $st->execute(); $eligible=(bool)$st->get_result()->fetch_row(); $st->close();
        if(!$eligible) pc_reject('This account no longer needs setup.');
        $subject='EduPocket Account Setup Reminder';
        $body="Hello {$name},\n\nYour EduPocket account was created at least three days ago, but its temporary password has not yet been changed. Please sign in using the credentials sent to your UE email and update your password.\n\nIf you need help, contact the school administration.\n\nBest regards,\nSchool Administration";
    } else {
        if(!pc_table_exists($conn,'admin_security_attempts') || !pc_table_exists($conn,'admin_dashboard_alert_sends')) pc_reject('Security alert history is not configured.');
        $attemptType=$type==='login_failures'?'login_password':($source==='cashiers'?'topup_pin':'payment_pin');
        $st=pc_prepare($conn,"SELECT COUNT(*) n,COALESCE(MAX(a.attempt_id),0) max_id FROM admin_security_attempts a LEFT JOIN admin_dashboard_alert_sends d ON d.alert_type=? AND d.account_role=a.account_role AND d.account_source=a.account_source AND d.user_id=a.user_id WHERE a.account_role=? AND a.account_source=? AND a.user_id=? AND a.attempt_type=? AND a.created_at>=DATE_SUB(NOW(),INTERVAL 24 HOUR) AND a.attempt_id>COALESCE(d.last_attempt_id,0)"); $alertType=$type; $st->bind_param('sssss',$alertType,$role,$source,$id,$attemptType); $st->execute(); $attemptRow=$st->get_result()->fetch_assoc(); $count=(int)($attemptRow['n']??0); $lastAttemptId=(int)($attemptRow['max_id']??0); $st->close();
        if($count<3) pc_reject('The alert threshold has not been reached.');
        if($type==='login_failures') {
            $subject='Security Alert: Unusual Login Activity Detected';
            $body="Hello {$name},\n\nWe've detected unusual activity involving multiple unsuccessful login attempts on your EduPocket account.\n\nThis activity has been flagged for security purposes. If you initiated these attempts, please double-check your Student ID or Parent Account ID and password before trying to sign in again.\n\nIf you do not recognize this activity, we strongly advise you to change your account password immediately and contact the school administration to report the suspicious login attempts and request an account security review.\n\nFor your protection, please use a strong, unique password and keep your login credentials confidential.\n\nBest regards,\nSchool Administration";
        } else {
            $subject='Security Alert: Unusual Activity Detected';
            $body="Hello {$name},\n\nWe've detected unusual activity involving your recent top-up and payment attempts on your EduPocket account.\n\nThis activity has been flagged for security purposes. If you initiated these attempts, please verify your PIN before proceeding with another transaction.\n\nIf you do not recognize this activity, please contact the school administration immediately to report the suspicious attempts and request an account security review.\n\nPlease remain cautious and keep your account credentials and PIN confidential.\n\nBest regards,\nSchool Administration";
        }
    }
    $config=pc_security_config();
    $destination=ev_resolve_verified_email_destination($conn,$config,$role,$source,$id);
    $sender=pc_email_config($config)['send_callback'];
    $sent=$sender($destination,'',['purpose'=>'admin_security_alert','subject'=>$subject,'message'=>$body,'html_message'=>'<div style="font-family:Arial,sans-serif;line-height:1.6">'.nl2br(htmlspecialchars($body,ENT_QUOTES|ENT_SUBSTITUTE,'UTF-8')).'</div>']);
    if($sent!==true) pc_reject('The email could not be sent. Please try again later.');
    $alertType=$type;
    $mark=pc_prepare($conn,'INSERT INTO admin_dashboard_alert_sends (alert_type,account_role,account_source,user_id,last_attempt_id,sent_at) VALUES (?,?,?,?,?,NOW(6)) ON DUPLICATE KEY UPDATE last_attempt_id=VALUES(last_attempt_id),sent_at=NOW(6)');
    $mark->bind_param('ssssi',$alertType,$role,$source,$id,$lastAttemptId); $mark->execute(); $mark->close();
    pc_respond(['status'=>'success','message'=>'Security email sent.']);
} catch(Throwable $e) {
    if($e instanceof PasswordChangeClientException) { http_response_code(400); pc_respond(pc_client_error_payload($e->getMessage())); }
    error_log('Admin security alert email failed: '.$e->getMessage()); http_response_code(500); pc_respond(['status'=>'error','message'=>'The email could not be sent. Please try again later.']);
}
