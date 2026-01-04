<?php
include_once '../../config/database.php';

$database = new Database();
$db = $database->getConnection();

$payload = json_decode(file_get_contents('php://input'));

$isbn = $payload->isbn ?? null;

if (empty($isbn)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'ISBN is required',
    ]);
    exit;
}

try {
    $db->beginTransaction();

    // Soft delete the book
    $stmt = $db->prepare('UPDATE books SET is_deleted = 1, updated_at = NOW() WHERE isbn = :isbn');
    $stmt->bindParam(':isbn', $isbn);
    $stmt->execute();

    // Mark all copies as discarded
    $copyStmt = $db->prepare('UPDATE book_copies SET is_deleted = 1, status = "Discarded", updated_at = NOW() WHERE isbn = :isbn');
    $copyStmt->bindParam(':isbn', $isbn);
    $copyStmt->execute();

    if ($stmt->rowCount() > 0) {
        $db->commit();
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'message' => 'Book removed (soft delete) successfully',
        ]);
    } else {
        $db->rollBack();
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Book not found',
        ]);
    }
} catch (Exception $e) {
    $db->rollBack();
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Unable to delete book: ' . $e->getMessage(),
    ]);
}
?>
