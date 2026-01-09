<?php
include_once '../../config/database.php';
include_once '../lib/enhanced_notification_helpers.php';

$database = new Database();
$db = $database->getConnection();

$data = json_decode(file_get_contents('php://input'));
$transactionId = $data->transaction_id ?? null;
$userEmail = $data->user_email ?? null;

if (empty($transactionId) || empty($userEmail)) {
  http_response_code(400);
  echo json_encode(['success'=>false,'message'=>'transaction_id and user_email are required']);
  exit;
}

try {
  // Ensure supporting table exists
  $db->exec("CREATE TABLE IF NOT EXISTS Return_Requests (
    id INT PRIMARY KEY AUTO_INCREMENT,
    transaction_id INT NOT NULL,
    requester_email VARCHAR(150) NOT NULL,
    requested_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status ENUM('Pending','Processed','Rejected') DEFAULT 'Pending',
    processed_at DATETIME,
    INDEX idx_rr_transaction (transaction_id),
    INDEX idx_rr_status (status)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;");

  // Validate transaction exists and belongs to user and is borrowed
  $stmt = $db->prepare("SELECT at.transaction_id
    FROM Approved_Transactions at
    JOIN Transaction_Requests tr ON tr.request_id = at.request_id
    WHERE at.transaction_id = :tid AND tr.requester_email = :email AND at.status = 'Borrowed'");
  $stmt->execute([':tid'=>$transactionId, ':email'=>$userEmail]);
  $row = $stmt->fetch(PDO::FETCH_ASSOC);
  if (!$row) {
    http_response_code(404);
    echo json_encode(['success'=>false,'message'=>'Active borrowed transaction not found for user']);
    exit;
  }

  // Prevent duplicate pending requests
  $check = $db->prepare('SELECT id FROM Return_Requests WHERE transaction_id = :tid AND status = "Pending"');
  $check->execute([':tid'=>$transactionId]);
  if ($check->fetch(PDO::FETCH_ASSOC)) {
    http_response_code(400);
    echo json_encode(['success'=>false,'message'=>'A pending return request already exists']);
    exit;
  }

  // Insert new request
  $ins = $db->prepare('INSERT INTO Return_Requests (transaction_id, requester_email) VALUES (:tid, :email)');
  $ins->execute([':tid'=>$transactionId, ':email'=>$userEmail]);
  
  // Get book title for notification
  $bookStmt = $db->prepare("
    SELECT b.title 
    FROM Approved_Transactions at
    JOIN Book_Copies bc ON at.copy_id = bc.copy_id
    JOIN Books b ON bc.isbn = b.isbn
    WHERE at.transaction_id = :tid
  ");
  $bookStmt->execute([':tid'=>$transactionId]);
  $book = $bookStmt->fetch(PDO::FETCH_ASSOC);
  $bookTitle = $book['title'] ?? 'Unknown Book';
  
  // Notify librarians about new return request
  notifyLibrarianReturnRequest($db, $userEmail, $bookTitle, $transactionId);

  echo json_encode(['success'=>true,'message'=>'Return request submitted. Waiting for librarian approval.', 'request_id'=>$db->lastInsertId()]);
} catch (Exception $e) {
  http_response_code(500);
  echo json_encode(['success'=>false,'message'=>'Error submitting return request: '.$e->getMessage()]);
}
