<?php
declare(strict_types=1);
require_once __DIR__ . '/receipt_print_token_common.php';
pc_bootstrap_json_endpoint();
pc_require_post();
try {
    $conn=pc_open_database();
    $session=as_require_session($conn,false);
    as_assert_session_role($session,['parent']);
    $parentId=trim((string)($_POST['parent_id']??'')); $studentNum=trim((string)($_POST['student_num']??'')); $action=trim((string)($_POST['action']??''));
    as_assert_session_identity($session,'parent',$parentId);
    if($studentNum==='' || !in_array($action,['freeze','unfreeze'],true)) pc_reject('Invalid account action.');
    $conn->begin_transaction();
    $check=pc_prepare($conn,'SELECT 1 FROM parent_student_link WHERE parent_id=? AND student_num=? LIMIT 1 FOR UPDATE');
    $check->bind_param('ss',$parentId,$studentNum); $check->execute(); $linked=(bool)$check->get_result()->fetch_row(); $check->close();
    if(!$linked) pc_reject('Student is not linked to this parent.');
    $status=$action==='freeze'?1:0;
    $update=pc_prepare($conn,'UPDATE students SET is_frozen=? WHERE student_num=?'); $update->bind_param('is',$status,$studentNum); $update->execute(); $update->close();
    as_record_activity($conn,$session,$status?'child_account_frozen_by_parent':'child_account_unfrozen_by_parent',['student_num'=>$studentNum,'parent_id'=>$parentId,'is_frozen'=>$status]);
    $conn->commit();
    pc_respond(['status'=>'success','message'=>'Account updated','is_frozen'=>$status]);
} catch(Throwable $e) {
    if(isset($conn) && $conn instanceof mysqli) $conn->rollback();
    if($e instanceof PasswordChangeClientException) { http_response_code(400); pc_respond(pc_client_error_payload($e->getMessage(),$e->details())); }
    error_log('Parent freeze action failed: '.$e->getMessage()); http_response_code(500); pc_respond(['status'=>'error','message'=>'Account update failed.']);
}
