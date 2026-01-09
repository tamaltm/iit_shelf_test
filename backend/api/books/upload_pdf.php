<?php
include_once '../../config/database.php';

$database = new Database();
$db = $database->getConnection();

$payload = json_decode(file_get_contents('php://input'));

$isbn = $payload->isbn ?? null;
$pdfPath = $payload->pdf_path ?? '';
$fileName = $payload->file_name ?? 'document.pdf';

if (empty($isbn) || $pdfPath === '') {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'ISBN and pdf_path are required',
    ]);
    exit;
}

try {
    $stmt = $db->prepare('INSERT INTO Digital_Resources (
        isbn, file_name, file_path, resource_type, uploaded_at
    ) VALUES (
        :isbn, :file_name, :file_path, "PDF", NOW()
    )');
    $stmt->execute([
        ':isbn' => $isbn,
        ':file_name' => $fileName,
        ':file_path' => $pdfPath,
    ]);

    http_response_code(201);
    echo json_encode([
        'success' => true,
        'message' => 'PDF resource added successfully',
        'resource_id' => $db->lastInsertId(),
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
