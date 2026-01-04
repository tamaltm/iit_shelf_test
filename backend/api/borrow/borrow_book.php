<?php
include_once '../../config/database.php';

$database = new Database();
$db = $database->getConnection();

$data = json_decode(file_get_contents('php://input'));

$userEmail = $data->user_email ?? null;
$isbn = $data->isbn ?? null;
$loanDays = isset($data->loan_days) ? (int)$data->loan_days : 14;

if (empty($isbn) || empty($userEmail)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'isbn and user_email are required',
    ]);
    exit;
}

try {
    // Check available copy
    $copyStmt = $db->prepare('SELECT copy_id FROM book_copies WHERE isbn = :isbn AND status = "Available" AND is_deleted = 0 LIMIT 1');
    $copyStmt->execute([':isbn' => $isbn]);
    $copy = $copyStmt->fetch(PDO::FETCH_ASSOC);

    if (!$copy) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'No available copies for this book',
        ]);
        exit;
    }

    $copyId = $copy['copy_id'];

    $db->beginTransaction();

    // Create approved transaction
    $txn = $db->prepare('INSERT INTO approved_transactions (
        request_id, copy_id, user_email, issue_date, due_date, status, created_at, updated_at
    ) VALUES (
        NULL, :copy_id, :user_email, NOW(), DATE_ADD(NOW(), INTERVAL :loan_days DAY), "Borrowed", NOW(), NOW()
    )');

    $txn->execute([
        ':copy_id' => $copyId,
        ':user_email' => $userEmail,
        ':loan_days' => $loanDays,
    ]);

    // Update copy status
    $copyUpdate = $db->prepare('UPDATE book_copies SET status = "Borrowed", updated_at = NOW() WHERE copy_id = :copy_id');
    $copyUpdate->execute([':copy_id' => $copyId]);

    // Update book availability
    $bookUpdate = $db->prepare('UPDATE books SET copies_available = GREATEST(copies_available - 1, 0), updated_at = NOW() WHERE isbn = :isbn');
    $bookUpdate->execute([':isbn' => $isbn]);

    $db->commit();

    http_response_code(201);
    echo json_encode([
        'success' => true,
        'message' => 'Book borrowed successfully',
        'transaction_id' => $db->lastInsertId(),
        'copy_id' => $copyId,
    ]);
} catch (Exception $e) {
    $db->rollBack();
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Unable to borrow book: ' . $e->getMessage(),
    ]);
}
?>
