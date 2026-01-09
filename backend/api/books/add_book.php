<?php
include_once '../../config/database.php';

$database = new Database();
$db = $database->getConnection();

// Handle both JSON and multipart/form-data
$contentType = $_SERVER['CONTENT_TYPE'] ?? '';
$picPath = null;
$courseId = null;

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

// Normalize optional course id (used to link books to courses)
if (!empty($data->course_id)) {
    $courseId = trim($data->course_id);
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

// Handle optional provided copy IDs (accept array or JSON string)
$copyIds = [];
if (isset($data->copy_ids)) {
    if (is_array($data->copy_ids)) {
        $copyIds = $data->copy_ids;
    } elseif (is_string($data->copy_ids)) {
        $decoded = json_decode($data->copy_ids, true);
        if (is_array($decoded)) {
            $copyIds = $decoded;
        }
    }
}

$copyIds = array_values(array_filter(array_map('trim', $copyIds ?? []), 'strlen'));

// Handle copy locations (array of location objects per copy)
$copyLocations = [];
if (isset($data->copy_locations)) {
    if (is_array($data->copy_locations)) {
        $copyLocations = $data->copy_locations;
    } elseif (is_string($data->copy_locations)) {
        $decoded = json_decode($data->copy_locations, true);
        if (is_array($decoded)) {
            $copyLocations = $decoded;
        }
    }
}

if (!empty($copyIds)) {
    $copiesFromIds = count($copyIds);

    if ($copiesTotal > 0 && $copiesTotal !== $copiesFromIds) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'copy_ids count must match copies_total',
        ]);
        exit;
    }

    $copiesTotal = $copiesFromIds;

    if (count(array_unique($copyIds)) !== $copiesFromIds) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Duplicate copy_ids provided',
        ]);
        exit;
    }
}

// Default available copies equals total
$copiesAvailable = $copiesTotal;

try {
    $db->beginTransaction();

    // Insert into Books table
    $stmt = $db->prepare('INSERT INTO Books (
        isbn, title, author, category, publisher, publication_year, edition,
        description, pic_path
    ) VALUES (
        :isbn, :title, :author, :category, :publisher, :publication_year, :edition,
        :description, :pic_path
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
    ]);

    // Link book to course if provided
    if (!empty($courseId)) {
        // Ensure course exists
        $courseCheck = $db->prepare('SELECT course_id FROM Courses WHERE course_id = :course_id');
        $courseCheck->execute([':course_id' => $courseId]);

        if ($courseCheck->fetchColumn() === false) {
            $db->rollBack();
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'Course not found for course_id: ' . $courseId,
            ]);
            exit;
        }

        $linkStmt = $db->prepare('INSERT INTO Book_Courses (isbn, course_id) VALUES (:isbn, :course_id)
            ON DUPLICATE KEY UPDATE course_id = VALUES(course_id)');
        $linkStmt->execute([
            ':isbn' => $data->isbn,
            ':course_id' => $courseId,
        ]);
    }

    // Generate copies in Book_Copies
    if ($copiesTotal > 0) {
        $copyInsert = $db->prepare('INSERT INTO Book_Copies (
            copy_id, isbn, shelf_id, compartment_no, subcompartment_no, status, condition_note
        ) VALUES (
            :copy_id, :isbn, :shelf_id, :compartment_no, :subcompartment_no, "Available", :condition_note
        )');

        if (!empty($copyIds)) {
            foreach ($copyIds as $index => $copyId) {
                // Get location for this specific copy if provided
                $location = $copyLocations[$index] ?? null;
                $shelfId = null;
                $compartmentNo = null;
                $subcompartmentNo = null;

                if ($location) {
                    $shelfId = $location['shelf_id'] ?? $location->shelf_id ?? null;
                    $compartmentNo = $location['compartment_no'] ?? $location->compartment_no ?? null;
                    $subcompartmentNo = $location['subcompartment_no'] ?? $location->subcompartment_no ?? null;
                }

                $copyInsert->execute([
                    ':copy_id' => $copyId,
                    ':isbn' => $data->isbn,
                    ':shelf_id' => $shelfId,
                    ':compartment_no' => $compartmentNo,
                    ':subcompartment_no' => $subcompartmentNo,
                    ':condition_note' => $data->condition_note ?? null,
                ]);
            }
        } else {
            // Determine starting sequence number for auto-generated IDs
            $seqStmt = $db->prepare('SELECT COUNT(*) as cnt FROM Book_Copies WHERE isbn = :isbn');
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
    }

    $db->commit();

    http_response_code(201);
    echo json_encode([
        'success' => true,
        'message' => 'Book added successfully',
        'isbn' => $data->isbn,
        'copies_created' => $copiesTotal,
        'course_id' => $courseId,
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
