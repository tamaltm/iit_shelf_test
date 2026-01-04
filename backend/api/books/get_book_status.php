<?php
include_once '../../config/database.php';

$database = new Database();
$db = $database->getConnection();

// Get ISBN from query parameter
$isbn = isset($_GET['isbn']) ? $_GET['isbn'] : '';

if (empty($isbn)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'ISBN is required',
    ]);
    exit;
}

try {
    // Get total and available copies from books table
    $bookStmt = $db->prepare('
        SELECT copies_total, copies_available 
        FROM books 
        WHERE isbn = :isbn AND is_deleted = 0
    ');
    $bookStmt->execute([':isbn' => $isbn]);
    $book = $bookStmt->fetch(PDO::FETCH_ASSOC);

    if (!$book) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Book not found',
        ]);
        exit;
    }

    // Count borrowed copies (from approved_transactions)
    $borrowStmt = $db->prepare('
        SELECT COUNT(*) as borrowed_count
        FROM approved_transactions at
        JOIN book_copies bc ON at.copy_id = bc.copy_id
        WHERE bc.isbn = :isbn 
        AND at.status = "Borrowed"
    ');
    $borrowStmt->execute([':isbn' => $isbn]);
    $borrowData = $borrowStmt->fetch(PDO::FETCH_ASSOC);

    // Count reserved copies
    $reserveStmt = $db->prepare('
        SELECT COUNT(*) as reserved_count
        FROM reservations
        WHERE isbn = :isbn 
        AND status = "Active"
    ');
    $reserveStmt->execute([':isbn' => $isbn]);
    $reserveData = $reserveStmt->fetch(PDO::FETCH_ASSOC);

    $copiesTotal = (int)$book['copies_total'];
    $copiesAvailable = (int)$book['copies_available'];
    $borrowedCount = (int)$borrowData['borrowed_count'];
    $reservedCount = (int)$reserveData['reserved_count'];

    // Determine availability
    $available = $copiesAvailable > 0;

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'isbn' => $isbn,
        'copies_total' => $copiesTotal,
        'copies_available' => $copiesAvailable,
        'borrowed_count' => $borrowedCount,
        'reserved_count' => $reservedCount,
        'available' => $available,
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Unable to fetch book status: ' . $e->getMessage(),
    ]);
}
?>
