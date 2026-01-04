<?php
include_once '../../config/database.php';

$database = new Database();
$db = $database->getConnection();

$payload = json_decode(file_get_contents('php://input'));

$bookId = $payload->book_id ?? null;
$pdfUrl = $payload->pdf_url ?? '';

if (empty($bookId) || $pdfUrl === '') {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Book ID and pdf_url are required',
    ]);
    exit;
}

try {
    $stmt = $db->prepare('UPDATE books SET pdf_url = :pdf_url, updated_at = NOW() WHERE id = :id');
    $stmt->bindParam(':pdf_url', $pdfUrl);
    $stmt->bindParam(':id', $bookId, PDO::PARAM_INT);
    $stmt->execute();

    if ($stmt->rowCount() > 0) {
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'message' => 'PDF link updated successfully',
        ]);
    } else {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Book not found',
        ]);
    }
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Unable to update PDF: ' . $e->getMessage(),
    ]);
}
?>
