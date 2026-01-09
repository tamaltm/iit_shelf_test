<?php
include_once '../../config/database.php';
include_once '../lib/request_cleanup.php';

$database = new Database();
$db = $database->getConnection();

// Clean up expired borrow requests (older than 24 hours)
cleanupExpiredBorrowRequests($db);

$type = $_GET['type'] ?? '';
$search = trim($_GET['search'] ?? '');

function likeClause($field) {
    return "($field LIKE :q)";
}

try {
    if ($type === 'borrow') {
        $sql = "SELECT tr.request_id, tr.isbn, tr.request_date, u.name, u.email, b.title,
                TIMESTAMPDIFF(HOUR, tr.request_date, NOW()) as hours_old,
                TIMESTAMPDIFF(MINUTE, NOW(), DATE_ADD(tr.request_date, INTERVAL 24 HOUR)) as minutes_until_expiry
                FROM Transaction_Requests tr
                JOIN Users u ON u.email = tr.requester_email
                JOIN Books b ON b.isbn = tr.isbn
                WHERE tr.status = 'Pending'";
        if ($search !== '') {
            $sql .= " AND (" . likeClause('u.name') . " OR " . likeClause('u.email') . " OR " . likeClause('b.title') . " OR " . likeClause('tr.isbn') . ")";
        }
        $sql .= " ORDER BY tr.request_date DESC";
        $stmt = $db->prepare($sql);
        if ($search !== '') {
            $like = "%$search%";
            $stmt->bindParam(':q', $like);
        }
        $stmt->execute();
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Add expiration info to each row
        foreach ($rows as &$row) {
            $minutesRemaining = (int)$row['minutes_until_expiry'];
            $row['expires_in_hours'] = max(0, floor($minutesRemaining / 60));
            $row['expires_in_minutes'] = max(0, $minutesRemaining % 60);
            $row['is_expired'] = $minutesRemaining <= 0;
        }
        
        echo json_encode(['success'=>true,'count'=>count($rows),'items'=>$rows]);
        exit;
    }

    if ($type === 'return') {
        // List pending return requests from users
        // Only show transactions that have pending return requests from the user
        $sql = "SELECT at.transaction_id, at.issue_date, at.due_date, tr.isbn, u.name, u.email, b.title,
                       GREATEST(DATEDIFF(NOW(), at.due_date), 0) AS days_overdue,
                       rr.requested_at
                FROM Approved_Transactions at
                JOIN Transaction_Requests tr ON tr.request_id = at.request_id
                JOIN Users u ON u.email = tr.requester_email
                JOIN Book_Copies bc ON bc.copy_id = at.copy_id
                JOIN Books b ON b.isbn = bc.isbn
                INNER JOIN Return_Requests rr ON rr.transaction_id = at.transaction_id AND rr.status = 'Pending'
                WHERE at.status = 'Borrowed'";
        if ($search !== '') {
            $sql .= " AND (" . likeClause('u.name') . " OR " . likeClause('u.email') . " OR " . likeClause('b.title') . " OR " . likeClause('tr.isbn') . ")";
        }
        $sql .= " ORDER BY at.due_date ASC";
        $stmt = $db->prepare($sql);
        if ($search !== '') { $like = "%$search%"; $stmt->bindParam(':q', $like); }
        $stmt->execute();
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
        echo json_encode(['success'=>true,'count'=>count($rows),'items'=>$rows]);
        exit;
    }

    if ($type === 'reserve') {
        $sql = "SELECT r.reservation_id, r.isbn, r.queue_position, r.status, r.created_at,
                       u.name, u.email, b.title
                FROM Reservations r
                JOIN Users u ON u.email = r.user_email
                JOIN Books b ON b.isbn = r.isbn
                WHERE r.status = 'Active'";
        if ($search !== '') {
            $sql .= " AND (" . likeClause('u.name') . " OR " . likeClause('u.email') . " OR " . likeClause('b.title') . " OR " . likeClause('r.isbn') . ")";
        }
        $sql .= " ORDER BY r.created_at DESC";
        $stmt = $db->prepare($sql);
        if ($search !== '') { $like = "%$search%"; $stmt->bindParam(':q', $like); }
        $stmt->execute();
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
        echo json_encode(['success'=>true,'count'=>count($rows),'items'=>$rows]);
        exit;
    }

    if ($type === 'addition') {
        $sql = "SELECT req.request_id, req.title AS requested_title, req.isbn, req.requester_identifier AS email,
                       COALESCE(u.name, 'Unknown') AS name, req.status, req.approved_by, req.approved_at, req.description
                FROM Requests req
                LEFT JOIN Users u ON u.email = req.requester_identifier
                WHERE req.status = 'Pending'";
        if ($search !== '') {
            $sql .= " AND (" . likeClause('u.name') . " OR " . likeClause('req.requester_identifier') . " OR " . likeClause('req.title') . " OR " . likeClause('req.isbn') . ")";
        }
        $sql .= " ORDER BY req.request_id DESC";
        $stmt = $db->prepare($sql);
        if ($search !== '') { $like = "%$search%"; $stmt->bindParam(':q', $like); }
        $stmt->execute();
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
        echo json_encode(['success'=>true,'count'=>count($rows),'items'=>$rows]);
        exit;
    }

    http_response_code(400);
    echo json_encode(['success'=>false,'message'=>'Invalid type']);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success'=>false,'message'=>'Error: '.$e->getMessage()]);
}
