<?php
include_once '../../config/database.php';

$database = new Database();
$db = $database->getConnection();

// Handle both JSON and multipart/form-data
$contentType = $_SERVER['CONTENT_TYPE'] ?? '';
$picPath = null;

if (stripos($contentType, 'application/json') === 0) {
    $data = json_decode(file_get_contents('php://input')) ?: new stdClass();
} else {
    // Multipart form data (file upload)
    $data = (object)$_POST;

    // Handle file upload
    if (isset($_FILES['image']) && $_FILES['image']['error'] === UPLOAD_ERR_OK) {
        $uploadDir = '../../uploads/books/';
        if (!is_dir($uploadDir)) {
            mkdir($uploadDir, 0755, true);
        }
        
        $fileName = uniqid('book_') . '_' . time() . '.' . pathinfo($_FILES['image']['name'], PATHINFO_EXTENSION);
        $filePath = $uploadDir . $fileName;
        
        if (move_uploaded_file($_FILES['image']['tmp_name'], $filePath)) {
            $picPath = 'uploads/books/' . $fileName;
        }
    }

    // If for some reason fields are empty, try to decode JSON body as fallback
    if (empty($data->title) && empty($data->isbn) && empty($data->author)) {
        $jsonBody = json_decode(file_get_contents('php://input'));
        if ($jsonBody) {
            $data = $jsonBody;
        }
    }
}

// Required fields
$required = ['title', 'author', 'isbn'];
foreach ($required as $field) {
    if (empty($data->$field)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => "$field is required",
        ]);
        exit;
    }
}

$copiesTotal = isset($data->copies_total) ? (int)$data->copies_total : 0;
if ($copiesTotal < 0) {
    $copiesTotal = 0;
}

// Default available copies equals total
$copiesAvailable = $copiesTotal;

try {
    $db->beginTransaction();

    // Insert into books table
    $stmt = $db->prepare('INSERT INTO books (
        isbn, title, author, category, publisher, publication_year, edition,
        description, pic_path, language, keywords, copies_total, copies_available,
        is_deleted, created_at, updated_at
    ) VALUES (
        :isbn, :title, :author, :category, :publisher, :publication_year, :edition,
        :description, :pic_path, :language, :keywords, :copies_total, :copies_available,
        0, NOW(), NOW()
    )');

    $stmt->execute([
        ':isbn' => $data->isbn,
        ':title' => $data->title,
        ':author' => $data->author,
        ':category' => $data->category ?? null,
        ':publisher' => $data->publisher ?? null,
        ':publication_year' => $data->publication_year ?? null,
        ':edition' => $data->edition ?? null,
        ':description' => $data->description ?? null,
        ':pic_path' => $picPath ?? $data->pic_path ?? null,
        ':language' => $data->language ?? 'English',
        ':keywords' => $data->keywords ?? null,
        ':copies_total' => $copiesTotal,
        ':copies_available' => $copiesAvailable,
    ]);

    // Generate copies in book_copies
    if ($copiesTotal > 0) {
        $copyInsert = $db->prepare('INSERT INTO book_copies (
            copy_id, isbn, shelf_id, compartment_no, subcompartment_no, status, condition_note, is_deleted, created_at, updated_at
        ) VALUES (
            :copy_id, :isbn, :shelf_id, :compartment_no, :subcompartment_no, "Available", :condition_note, 0, NOW(), NOW()
        )');

        // Determine starting sequence number
        $seqStmt = $db->prepare('SELECT COUNT(*) as cnt FROM book_copies WHERE isbn = :isbn');
        $seqStmt->execute([':isbn' => $data->isbn]);
        $start = (int)$seqStmt->fetch(PDO::FETCH_ASSOC)['cnt'];

        for ($i = 1; $i <= $copiesTotal; $i++) {
            $seq = $start + $i;
            $copyId = $data->isbn . '-' . str_pad((string)$seq, 4, '0', STR_PAD_LEFT);
            $copyInsert->execute([
                ':copy_id' => $copyId,
                ':isbn' => $data->isbn,
                ':shelf_id' => $data->shelf_id ?? null,
                ':compartment_no' => $data->compartment_no ?? null,
                ':subcompartment_no' => $data->subcompartment_no ?? null,
                ':condition_note' => $data->condition_note ?? null,
            ]);
        }
    }

    $db->commit();

    http_response_code(201);
    echo json_encode([
        'success' => true,
        'message' => 'Book added successfully',
        'isbn' => $data->isbn,
        'copies_created' => $copiesTotal,
    ]);
} catch (Exception $e) {
    $db->rollBack();
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Unable to add book: ' . $e->getMessage(),
    ]);
}
?>
