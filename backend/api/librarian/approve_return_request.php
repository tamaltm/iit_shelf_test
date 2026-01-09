<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json; charset=UTF-8");

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../lib/notification_helpers.php';

$database = new Database();
$db = $database->getConnection();

$input = json_decode(file_get_contents('php://input'), true);
$requestId = $input['request_id'] ?? null;
$transactionId = $input['transaction_id'] ?? null;

if (!$requestId && !$transactionId) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'request_id or transaction_id is required']);
    exit;
}

try {
    $db->beginTransaction();

    // Load return request
    if ($requestId) {
        $stmt = $db->prepare('SELECT id, transaction_id, requester_email, status FROM Return_Requests WHERE id = :id FOR UPDATE');
        $stmt->execute([':id' => $requestId]);
    } else {
        $stmt = $db->prepare('SELECT id, transaction_id, requester_email, status FROM Return_Requests WHERE transaction_id = :tid FOR UPDATE');
        $stmt->execute([':tid' => $transactionId]);
    }
    $rr = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$rr) {
        $db->rollBack();
        http_response_code(404);
        echo json_encode(['success' => false, 'message' => 'Return request not found']);
        exit;
    }

    if ($rr['status'] !== 'Pending') {
        $db->rollBack();
        http_response_code(409);
        echo json_encode(['success' => false, 'message' => 'Return request is not pending']);
        exit;
    }

    // Mark as Approved
    $upd = $db->prepare('UPDATE Return_Requests SET status = "Approved", approved_at = NOW() WHERE id = :id');
    $upd->execute([':id' => $rr['id']]);

    // Get book title for notification
    $titleStmt = $db->prepare('SELECT b.title FROM Approved_Transactions at JOIN Book_Copies bc ON at.copy_id = bc.copy_id JOIN Books b ON bc.isbn = b.isbn WHERE at.transaction_id = :tid');
    $titleStmt->execute([':tid' => $rr['transaction_id']]);
    $bookTitle = $titleStmt->fetchColumn() ?: 'Book';

    // Notify user
    notifyReturnRequestApproved($db, $rr['requester_email'], $bookTitle);

    $db->commit();

    http_response_code(200);
    echo json_encode(['success' => true, 'message' => 'Return request approved']);
} catch (Exception $e) {
    $db->rollBack();
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Error approving return request: ' . $e->getMessage()]);
}
