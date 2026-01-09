<?php
include_once '../../config/database.php';

$database = new Database();
$db = $database->getConnection();

$payload = json_decode(file_get_contents('php://input')) ?: new stdClass();

// Require an identifier. Prefer ISBN since the books table has ISBN as primary key.
if (empty($payload->isbn)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'ISBN is required',
    ]);
    exit;
}

$fields = [];
$params = [':where_isbn' => $payload->isbn];

$allowed = [
    'title',
    'author',
    'isbn',
    'category',
    'publisher',
    'publication_year',
    'edition',
    'description',
    'pic_path',
];

foreach ($allowed as $key) {
    if (isset($payload->$key)) {
        $fields[] = "$key = :$key";
        $params[":$key"] = $payload->$key;
    }
}

if (empty($fields) && (empty($payload->course_id))) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'No fields provided to update',
    ]);
    exit;
}

// Update Books table fields if any are provided
if (!empty($fields)) {
    $query = 'UPDATE Books SET ' . implode(', ', $fields) . ' WHERE isbn = :where_isbn';
    $stmt = $db->prepare($query);

    try {
        $stmt->execute($params);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Unable to update book: ' . $e->getMessage(),
        ]);
        exit;
    }
}

try {
    // Handle course_id update via Book_Courses junction table
    if (isset($payload->course_id) && !empty($payload->course_id)) {
        // Delete existing course associations for this book
        $deleteStmt = $db->prepare('DELETE FROM Book_Courses WHERE isbn = :isbn');
        $deleteStmt->execute([':isbn' => $payload->isbn]);

        // Insert new course association
        $insertStmt = $db->prepare('INSERT INTO Book_Courses (isbn, course_id) VALUES (:isbn, :course_id)');
        $insertStmt->execute([
            ':isbn' => $payload->isbn,
            ':course_id' => $payload->course_id
        ]);
    }

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Book updated successfully',
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Unable to update book: ' . $e->getMessage(),
    ]);
}
?>
