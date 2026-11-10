<?php
declare(strict_types=1);

require_once __DIR__ . '/receipt_print_token_common.php';
error_reporting(E_ALL);
ini_set('display_errors','0');
$requestOrigin=trim((string)($_SERVER['HTTP_ORIGIN']??''));
if(preg_match('#^http://(?:localhost|127\.0\.0\.1):\d{1,5}$#D',$requestOrigin)===1){header('Access-Control-Allow-Origin: '.$requestOrigin);header('Vary: Origin');}
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store, max-age=0');
if(($_SERVER['REQUEST_METHOD']??'')==='OPTIONS'){http_response_code(204);exit;}
if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'GET') pc_reject('Invalid request method.');

try {
    $conn = pc_open_database();
    $session = as_require_session($conn, false);
    if (($session['role'] ?? '') !== 'admin') {
        pc_reject('Administrator access is required.');
    }

    $period = strtolower(trim((string)($_GET['period'] ?? 'all')));
    $sort = strtolower(trim((string)($_GET['sort'] ?? 'sales')));
    if (!in_array($period, ['all', 'today', 'week', 'month', 'year', 'custom'], true)) $period = 'all';
    if (!in_array($sort, ['sales', 'transactions'], true)) $sort = 'sales';
    $from = trim((string)($_GET['start_date'] ?? ''));
    $to = trim((string)($_GET['end_date'] ?? ''));
    $where = '';
    if ($period === 'today') $where = ' AND DATE(COALESCE(t.date_time,t.date_created)) = CURDATE()';
    elseif ($period === 'week') $where = ' AND DATE(COALESCE(t.date_time,t.date_created)) BETWEEN DATE_SUB(CURDATE(), INTERVAL 6 DAY) AND CURDATE()';
    elseif ($period === 'month') $where = ' AND DATE(COALESCE(t.date_time,t.date_created)) BETWEEN DATE_FORMAT(CURDATE(), "%Y-%m-01") AND CURDATE()';
    elseif ($period === 'year') $where = ' AND DATE(COALESCE(t.date_time,t.date_created)) BETWEEN MAKEDATE(YEAR(CURDATE()), 1) AND CURDATE()';
    elseif ($period === 'custom' && preg_match('/^\d{4}-\d{2}-\d{2}$/D', $from) && preg_match('/^\d{4}-\d{2}-\d{2}$/D', $to)
        && DateTime::createFromFormat('!Y-m-d', $from) !== false
        && DateTime::createFromFormat('!Y-m-d', $to) !== false
        && $from <= $to) {
        $where = " AND DATE(COALESCE(t.date_time,t.date_created)) BETWEEN '" . $conn->real_escape_string($from) . "' AND '" . $conn->real_escape_string($to) . "'";
    }

    $users = [];
    foreach (['admins','students','canteens','cashiers','parents'] as $table) {
        $res = $conn->query("SELECT COUNT(*) AS n FROM `$table`");
        $users[$table] = $res ? (int)$res->fetch_assoc()['n'] : 0;
    }
    $balance = 0.0;
    foreach (['students','canteens'] as $table) {
        $res = $conn->query("SELECT COALESCE(SUM(balance),0) AS n FROM `$table`");
        if ($res) $balance += (float)$res->fetch_assoc()['n'];
    }
    $ops = ['transactions'=>0,'topups'=>0,'payments'=>0,'topup_total'=>0.0,'payment_total'=>0.0];
    $res = $conn->query("SELECT COUNT(*) n, COALESCE(SUM(transaction_type='top-up'),0) topups, COALESCE(SUM(transaction_type='payment'),0) payments, COALESCE(SUM(IF(transaction_type='payment',amount,0)),0) payment_total FROM transactions");
    if ($res) { $r=$res->fetch_assoc(); $ops['transactions']=(int)$r['n']; $ops['topups']=(int)$r['topups']; $ops['payments']=(int)$r['payments']; $ops['payment_total']=(float)$r['payment_total']; }
    $res = $conn->query("SELECT COUNT(*) n, COALESCE(SUM(amount),0) total FROM topups WHERE LOWER(status) IN ('completed','success','successful')");
    if ($res) { $r=$res->fetch_assoc(); $ops['topups']=(int)$r['n']; $ops['topup_total']=(float)$r['total']; }

    $order = $sort === 'transactions' ? 'payment_count DESC, sales DESC' : 'sales DESC, payment_count DESC';
    $canteens=[]; $cashiers=[];
    $paymentRowsSql = "SELECT t.transaction_id, t.amount, t.date_time, t.date_created,
            COALESCE(NULLIF(TRIM(t.canteen_id), ''), NULLIF(TRIM(ca.canteen_id), ''), NULLIF(TRIM(a.canteen_id), '')) canteen_id,
            COALESCE(NULLIF(TRIM(t.cashier_id), ''),
                CASE WHEN LOWER(COALESCE(t.processor_role, '')) = 'cashier'
                    THEN NULLIF(TRIM(t.processor_id), '') END) cashier_id,
            CASE
                WHEN LOWER(COALESCE(t.processor_account_source, '')) IN ('cashiers', 'admins')
                    THEN LOWER(t.processor_account_source)
                WHEN ca.cashier_id IS NOT NULL THEN 'cashiers'
                WHEN a.admin_id IS NOT NULL THEN 'admins'
                ELSE NULL
            END cashier_source
        FROM transactions t
        LEFT JOIN cashiers ca
            ON ca.cashier_id = COALESCE(NULLIF(TRIM(t.cashier_id), ''),
                CASE WHEN LOWER(COALESCE(t.processor_role, '')) = 'cashier'
                    THEN NULLIF(TRIM(t.processor_id), '') END)
            AND (NULLIF(LOWER(TRIM(t.processor_account_source)), '') IS NULL
                OR LOWER(TRIM(t.processor_account_source)) = 'cashiers')
        LEFT JOIN admins a
            ON a.admin_id = COALESCE(NULLIF(TRIM(t.cashier_id), ''),
                CASE WHEN LOWER(COALESCE(t.processor_role, '')) = 'cashier'
                    THEN NULLIF(TRIM(t.processor_id), '') END)
            AND LOWER(COALESCE(a.role, '')) = 'cashier'
            AND (LOWER(COALESCE(t.processor_account_source, '')) = 'admins'
                OR (NULLIF(LOWER(TRIM(t.processor_account_source)), '') IS NULL
                    AND ca.cashier_id IS NULL))
        WHERE t.transaction_type = 'payment'";
    $sql = "SELECT c.canteen_id id, COALESCE(NULLIF(c.Fname,''), CONCAT('Canteen ',c.canteen_id)) name, COALESCE(SUM(t.amount),0) sales, COUNT(t.transaction_id) payment_count FROM canteens c LEFT JOIN ($paymentRowsSql) t ON t.canteen_id=c.canteen_id $where GROUP BY c.canteen_id,c.Fname ORDER BY $order";
    if ($res=$conn->query($sql)) while($r=$res->fetch_assoc()) $canteens[]=['id'=>$r['id'],'name'=>$r['name'],'sales'=>(float)$r['sales'],'payment_count'=>(int)$r['payment_count']];
    $sql = "SELECT t.cashier_id id,
            COALESCE(NULLIF(ca.Fname, ''), NULLIF(a.Fname, ''), CONCAT('Cashier ', t.cashier_id)) name,
            COALESCE(c.Fname, 'Unassigned canteen') canteen,
            COALESCE(SUM(t.amount), 0) sales, COUNT(t.transaction_id) payment_count
        FROM ($paymentRowsSql) t
        LEFT JOIN cashiers ca ON ca.cashier_id = t.cashier_id AND t.cashier_source = 'cashiers'
        LEFT JOIN admins a ON a.admin_id = t.cashier_id
            AND LOWER(COALESCE(a.role, '')) = 'cashier' AND t.cashier_source = 'admins'
        LEFT JOIN canteens c ON c.canteen_id = t.canteen_id
        WHERE NULLIF(TRIM(t.cashier_id), '') IS NOT NULL $where
        GROUP BY t.cashier_id, t.cashier_source, ca.Fname, a.Fname, c.Fname
        ORDER BY $order";
    if ($res=$conn->query($sql)) while($r=$res->fetch_assoc()) $cashiers[]=['id'=>$r['id'],'name'=>$r['name'],'canteen'=>$r['canteen'],'sales'=>(float)$r['sales'],'payment_count'=>(int)$r['payment_count']];

    $needs=[];
    $displayName = static function(string $source, string $id) use ($conn): string {
        $map=['students'=>['student_num','first_name','middle_name','last_name','Fname'],'parents'=>['parent_id','first_name','middle_name','last_name','Fname'],'cashiers'=>['cashier_id','Fname']];
        if(!isset($map[$source])) return 'Account holder';
        [$key]=$map[$source];
        $select=$source==='cashiers' ? "COALESCE(NULLIF(Fname,''),'Cashier') AS n" : "first_name,last_name,Fname AS n";
        $st=$conn->prepare("SELECT $select FROM `$source` WHERE `$key`=? LIMIT 1");
        if(!$st) return 'Account holder'; $st->bind_param('s',$id); $st->execute(); $row=$st->get_result()->fetch_assoc(); $st->close();
        $name=trim((string)($row['n']??'Account holder'));
        return $source==='cashiers' ? $name : receipt_mask_name_parts((string)($row['first_name']??''),(string)($row['last_name']??''));
    };
    if (pc_table_exists($conn,'admin_security_attempts') && pc_table_exists($conn,'admin_dashboard_alert_sends')) {
        $res=$conn->query("SELECT a.account_role,a.account_source,a.user_id,a.attempt_type,COUNT(*) attempts,MAX(a.created_at) last_at,MAX(a.attempt_id) last_attempt_id FROM admin_security_attempts a LEFT JOIN admin_dashboard_alert_sends d ON d.alert_type=CASE WHEN a.attempt_type='login_password' THEN 'login_failures' ELSE 'failed_transactions' END AND d.account_role=a.account_role AND d.account_source=a.account_source AND d.user_id=a.user_id WHERE a.created_at>=DATE_SUB(NOW(),INTERVAL 24 HOUR) AND a.attempt_id>COALESCE(d.last_attempt_id,0) GROUP BY a.account_role,a.account_source,a.user_id,a.attempt_type HAVING COUNT(*)>=3 ORDER BY last_at DESC LIMIT 40");
        if($res) while($r=$res->fetch_assoc()) $needs[]=['type'=>$r['attempt_type']==='login_password'?'login_failures':'failed_transactions','role'=>$r['account_role'],'source'=>$r['account_source'],'user_id'=>$r['user_id'],'attempts'=>(int)$r['attempts'],'last_attempt_id'=>(int)$r['last_attempt_id'],'last_at'=>$r['last_at'],'name'=>$displayName((string)$r['account_source'],(string)$r['user_id']),'label'=>$r['attempt_type']==='login_password'?'Repeated login failures':'Repeated incorrect PIN attempts'];
    }
    if (pc_table_exists($conn,'app_activity_events') && pc_table_exists($conn,'admin_dashboard_alert_sends')) {
        $res=$conn->query("SELECT JSON_UNQUOTE(JSON_EXTRACT(e.metadata_json,'$.student_num')) student_num,e.created_at,a.Fname,a.first_name,a.last_name FROM app_activity_events e JOIN students a ON a.student_num=JSON_UNQUOTE(JSON_EXTRACT(e.metadata_json,'$.student_num')) LEFT JOIN parent_student_link l ON l.student_num=a.student_num LEFT JOIN parents p ON p.parent_id=l.parent_id LEFT JOIN admin_dashboard_alert_sends d ON d.alert_type='account_setup' AND d.account_role='student' AND d.account_source='students' AND d.user_id=a.student_num WHERE e.event_name IN ('student_family_account_created','student_account_created') AND e.created_at<=DATE_SUB(NOW(),INTERVAL 3 DAY) AND (COALESCE(a.password_changed,0)=0 OR COALESCE(p.password_changed,1)=0) AND d.send_id IS NULL ORDER BY e.created_at DESC LIMIT 40");
        if($res) while($r=$res->fetch_assoc()) $needs[]=['type'=>'account_setup','role'=>'student','source'=>'students','user_id'=>$r['student_num'],'last_at'=>$r['created_at'],'label'=>'Awaiting account setup','name'=>receipt_mask_name_parts((string)($r['first_name']??''),(string)($r['last_name']??''))];
    }
    $audit=[];
    if (pc_table_exists($conn,'app_activity_events')) {
        $res=$conn->query("SELECT event_name,role,created_at,metadata_json FROM app_activity_events WHERE event_name IN ('account_deleted','student_account_manually_locked','student_account_manually_unlocked','child_account_frozen_by_parent','child_account_unfrozen_by_parent') ORDER BY created_at DESC LIMIT 12");
        if($res) while($r=$res->fetch_assoc()) {
            $metadata=json_decode((string)$r['metadata_json'],true) ?: [];
            $event=(string)$r['event_name'];
            if($event==='account_deleted') {
                $deletedName=trim((string)($metadata['display_name']??''));
                $title='Admin deleted '.($deletedName!==''?$deletedName:'an account');
            } else {
                $studentNum=(string)($metadata['student_num']??'');
                $masked=$studentNum!==''?$displayName('students',$studentNum):'a student';
                $isFreeze=str_contains($event,'frozen') || str_contains($event,'locked');
                $byParent=str_contains($event,'parent');
                $title=($isFreeze?'Frozen ':'Unfrozen ').$masked.' by '.($byParent?'Parent':'Admin');
            }
            $audit[]=['event'=>$event,'title'=>$title,'created_at'=>$r['created_at']];
        }
    }
    pc_respond(['status'=>'success','total_users'=>array_sum($users),'user_breakdown'=>$users,'total_balance'=>$balance,'operational_summary'=>$ops,'canteen_sales'=>$canteens,'cashier_sales'=>$cashiers,'needs_attention'=>$needs,'system_security'=>$audit,'period'=>$period,'sort'=>$sort]);
} catch (Throwable $e) {
    if ($e instanceof PasswordChangeClientException) http_response_code(400); else http_response_code(500);
    error_log('Admin dashboard endpoint failed: ' . $e->getMessage());
    echo json_encode(['status'=>'error','message'=>$e instanceof PasswordChangeClientException ? $e->getMessage() : 'Dashboard data could not be loaded.']);
}
