<?php
include_once '../../config/database.php';

$database = new Database();
$db = $database->getConnection();

$payload = json_decode(file_get_contents('php://input'));

$title = $payload->title ?? '';
$author = $payload->author ?? '';
$category = $payload->category ?? null;
$publisher = $payload->publisher ?? null;
$publication_year = $payload->publication_year ?? null;
$edition = $payload->edition ?? null;
$description = $payload->description ?? null;
$pic_path = $payload->pic_path ?? null;
$pdf_path = $payload->pdf_path ?? null;
$priority = $payload->priority ?? 'Medium';
$userEmail = $payload->user_email ?? null;

if ($title === '' || empty($userEmail)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'title and user_email are required',
    ]);
    exit;
}

try {
    $stmt = $db->prepare('INSERT INTO requests (
        requester_email, isbn, title, author, category, publisher, publication_year,
        edition, description, pic_path, pdf_path, status, priority, created_at
    ) VALUES (
        :requester_email, :isbn, :title, :author, :category, :publisher, :publication_year,
        :edition, :description, :pic_path, :pdf_path, "Pending", :priority, NOW()
    )');

    $stmt->execute([
        ':requester_email' => $userEmail,
        ':isbn' => $payload->isbn ?? null,
        ':title' => $title,
        ':author' => $author,
        ':category' => $category,
        ':publisher' => $publisher,
        ':publication_year' => $publication_year,
        ':edition' => $edition,
        ':description' => $description,
        ':pic_path' => $pic_path,
        ':pdf_path' => $pdf_path,
        ':priority' => $priority,
    ]);

    http_response_code(201);
    echo json_encode([
        'success' => true,
        'message' => 'Book request submitted',
        'request_id' => $db->lastInsertId(),
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Unable to create request: ' . $e->getMessage(),
    ]);
}
?>
