<?php
include_once '../../config/database.php';

$database = new Database();
$db = $database->getConnection();

$data = json_decode(file_get_contents('php://input'));

$transactionId = $data->transaction_id ?? null;
$copyId = $data->copy_id ?? null;

if (empty($transactionId) && empty($copyId)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'transaction_id or copy_id is required',
    ]);
    exit;
}

try {
    $db->beginTransaction();

    // Locate active transaction
    if (!empty($transactionId)) {
        $find = $db->prepare('SELECT transaction_id, copy_id, user_email, issue_date, due_date FROM approved_transactions WHERE transaction_id = :tid AND status = "Borrowed"');
        $find->execute([':tid' => $transactionId]);
    } else {
        $find = $db->prepare('SELECT transaction_id, copy_id, user_email, issue_date, due_date FROM approved_transactions WHERE copy_id = :cid AND status = "Borrowed" ORDER BY issue_date DESC LIMIT 1');
        $find->execute([':cid' => $copyId]);
    }

    $txn = $find->fetch(PDO::FETCH_ASSOC);
    if (!$txn) {
        $db->rollBack();
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Active borrow transaction not found',
        ]);
        exit;
    }

    // Overdue calculation
    $due = new DateTime($txn['due_date']);
    $now = new DateTime();
    $fineAmount = 0;
    $daysOverdue = 0;
    if ($now > $due) {
        $daysOverdue = $now->diff($due)->days;
        $fineAmount = $daysOverdue * 5; // 5 per day
    }

    // Close transaction
    $close = $db->prepare('UPDATE approved_transactions SET status = "Returned", return_date = NOW(), updated_at = NOW() WHERE transaction_id = :tid');
    $close->execute([':tid' => $txn['transaction_id']]);

    // Update copy status
    $copyUpdate = $db->prepare('UPDATE book_copies SET status = "Available", updated_at = NOW() WHERE copy_id = :cid');
    $copyUpdate->execute([':cid' => $txn['copy_id']]);

    // Increment availability on books
    $isbnStmt = $db->prepare('SELECT isbn FROM book_copies WHERE copy_id = :cid');
    $isbnStmt->execute([':cid' => $txn['copy_id']]);
    $isbnRow = $isbnStmt->fetch(PDO::FETCH_ASSOC);
    if ($isbnRow) {
        $bookUpdate = $db->prepare('UPDATE books SET copies_available = copies_available + 1, updated_at = NOW() WHERE isbn = :isbn');
        $bookUpdate->execute([':isbn' => $isbnRow['isbn']]);
    }

    // Record fine if overdue
    $fineId = null;
    if ($fineAmount > 0) {
        $fineInsert = $db->prepare('INSERT INTO fines (
            transaction_id, user_email, amount, fine_type, days_overdue, description, paid, created_at, updated_at
        ) VALUES (
            :transaction_id, :user_email, :amount, "Late Return", :days_overdue, :description, 0, NOW(), NOW()
        )');
        $fineInsert->execute([
            ':transaction_id' => $txn['transaction_id'],
            ':user_email' => $txn['user_email'],
            ':amount' => $fineAmount,
            ':days_overdue' => $daysOverdue,
            ':description' => 'Auto-generated late fee',
        ]);
        $fineId = $db->lastInsertId();
    }

    $db->commit();

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Book returned successfully',
        'fine' => $fineAmount,
        'fine_id' => $fineId,
    ]);
} catch (Exception $e) {
    $db->rollBack();
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Unable to return book: ' . $e->getMessage(),
    ]);
}
?>
