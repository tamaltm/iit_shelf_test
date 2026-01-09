<?php
/**
 * Get User Transactions
 * Retrieves borrowed, returned, and reserved books for a user
 */

require_once '../../config/database.php';
require_once '../lib/request_cleanup.php';

$database = new Database();
$db = $database->getConnection();

// Clean up expired borrow requests (older than 24 hours)
cleanupExpiredBorrowRequests($db);

// Get user email from request
$input = json_decode(file_get_contents('php://input'), true) ?? $_GET;
$email = isset($input['email']) ? strtolower(trim($input['email'])) : '';
$status = isset($input['status']) ? $input['status'] : 'all'; // all, borrowed, returned, reserved

if ($email === '') {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Email is required.'
    ]);
    exit;
}

try {
    $transactions = [];
    
    // Get borrowed and returned books from Approved_Transactions
    if ($status === 'all' || $status === 'borrowed' || $status === 'returned') {
        $statusFilter = '';
        if ($status === 'borrowed') {
            // Include both Borrowed and Overdue books when fetching borrowed books
            $statusFilter = " AND (at.status = 'Borrowed' OR at.status = 'Overdue')";
        } elseif ($status === 'returned') {
            $statusFilter = " AND at.status = 'Returned'";
        }
        
        $stmt = $db->prepare("
            SELECT 
                at.transaction_id,
                at.copy_id,
                at.issue_date,
                at.due_date,
                at.return_date,
                at.status,
                b.isbn,
                b.title,
                b.author,
                b.pic_path,
                bc.status as copy_status
            FROM Approved_Transactions at
            JOIN Transaction_Requests tr ON at.request_id = tr.request_id
            JOIN Book_Copies bc ON at.copy_id = bc.copy_id
            JOIN Books b ON bc.isbn = b.isbn
            WHERE tr.requester_email = :email $statusFilter
            ORDER BY at.issue_date DESC
        ");
        $stmt->execute([':email' => $email]);
        
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            // Check if book is overdue (borrowed and past due date)
            $isOverdue = false;
            $daysOverdue = 0;
            $actualStatus = $row['status'];
            
            if ($row['status'] === 'Borrowed' && $row['return_date'] === null) {
                $now = new DateTime();
                $dueDate = new DateTime($row['due_date']);
                
                if ($now > $dueDate) {
                    $isOverdue = true;
                    $daysOverdue = $now->diff($dueDate)->days;
                    $actualStatus = 'Overdue';
                }
            }
            
            $transactions[] = [
                'type' => strtolower($actualStatus),
                'transaction_id' => $row['transaction_id'],
                'copy_id' => $row['copy_id'],
                'isbn' => $row['isbn'],
                'title' => $row['title'],
                'author' => $row['author'],
                'pic_path' => $row['pic_path'],
                'issue_date' => $row['issue_date'],
                'due_date' => $row['due_date'],
                'return_date' => $row['return_date'],
                'status' => $actualStatus,
                'is_overdue' => $isOverdue,
                'days_overdue' => $daysOverdue
            ];
        }
    }
    
    // Get reserved books from Reservations
    if ($status === 'all' || $status === 'reserved') {
        $stmt = $db->prepare("
            SELECT 
                r.reservation_id,
                r.isbn,
                r.created_at as reservation_date,
                r.expires_at as expiry_date,
                r.status as reservation_status,
                b.title,
                b.author,
                b.pic_path
            FROM Reservations r
            JOIN Books b ON r.isbn = b.isbn
            WHERE r.user_email = :email AND r.status = 'Active'
            ORDER BY r.created_at DESC
        ");
        $stmt->execute([':email' => $email]);
        
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            $transactions[] = [
                'type' => 'reserved',
                'reservation_id' => $row['reservation_id'],
                'isbn' => $row['isbn'],
                'title' => $row['title'],
                'author' => $row['author'],
                'pic_path' => $row['pic_path'],
                'reservation_date' => $row['reservation_date'],
                'expiry_date' => $row['expiry_date'],
                'status' => $row['reservation_status']
            ];
        }
    }
    
    // Get pending borrow requests from Transaction_Requests
    if ($status === 'all' || $status === 'pending') {
        $stmt = $db->prepare("
            SELECT 
                tr.request_id,
                tr.isbn,
                tr.request_date,
                b.title,
                b.author,
                b.pic_path,
                TIMESTAMPDIFF(HOUR, tr.request_date, NOW()) as hours_old,
                TIMESTAMPDIFF(MINUTE, NOW(), DATE_ADD(tr.request_date, INTERVAL 24 HOUR)) as minutes_until_expiry
            FROM Transaction_Requests tr
            JOIN Books b ON tr.isbn = b.isbn
            WHERE tr.requester_email = :email AND tr.status = 'Pending'
            ORDER BY tr.request_date DESC
        ");
        $stmt->execute([':email' => $email]);
        
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            $minutesRemaining = (int)$row['minutes_until_expiry'];
            $hoursRemaining = floor($minutesRemaining / 60);
            $minsRemaining = $minutesRemaining % 60;
            
            $transactions[] = [
                'type' => 'pending',
                'request_id' => $row['request_id'],
                'isbn' => $row['isbn'],
                'title' => $row['title'],
                'author' => $row['author'],
                'pic_path' => $row['pic_path'],
                'request_date' => $row['request_date'],
                'hours_old' => (int)$row['hours_old'],
                'expires_in_hours' => max(0, $hoursRemaining),
                'expires_in_minutes' => max(0, $minsRemaining),
                'is_expired' => $minutesRemaining <= 0,
                'status' => 'Pending'
            ];
        }
    }
    
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'count' => count($transactions),
        'transactions' => $transactions
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Failed to fetch transactions: ' . $e->getMessage()
    ]);
}
?>
