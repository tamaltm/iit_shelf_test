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
    'language',
    'keywords',
    'copies_total',
    'copies_available',
    'is_deleted',
];

foreach ($allowed as $key) {
    if (isset($payload->$key)) {
        $fields[] = "$key = :$key";
        $params[":$key"] = $payload->$key;
    }
}

if (empty($fields)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'No fields provided to update',
    ]);
    exit;
}

$query = 'UPDATE books SET ' . implode(', ', $fields) . ', updated_at = NOW() WHERE isbn = :where_isbn';
$stmt = $db->prepare($query);

try {
    $stmt->execute($params);
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
