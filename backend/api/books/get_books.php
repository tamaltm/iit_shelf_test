<?php
include_once '../../config/database.php';

$database = new Database();
$db = $database->getConnection();

$search = isset($_GET['search']) ? $_GET['search'] : '';
$category = isset($_GET['category']) ? $_GET['category'] : '';
$courseId = isset($_GET['course_id']) ? $_GET['course_id'] : '';
$semester = isset($_GET['semester']) ? $_GET['semester'] : '';
$availability = isset($_GET['availability']) ? $_GET['availability'] : '';
$bookType = isset($_GET['book_type']) ? $_GET['book_type'] : '';

// Join with Book_Courses to include course_id and Digital_Resources for PDF
// Also join with Courses table to filter by semester
$query = "SELECT DISTINCT b.*, bc.course_id, dr.file_path as pdf_path, c.semester
          FROM Books b 
          LEFT JOIN Book_Courses bc ON b.isbn = bc.isbn 
          LEFT JOIN Courses c ON bc.course_id = c.course_id
          LEFT JOIN Digital_Resources dr ON b.isbn = dr.isbn AND dr.resource_type = 'PDF'
          WHERE 1=1 AND b.title NOT LIKE '[DELETED]%'";

if (!empty($search)) {
    $query .= " AND (b.title LIKE :search OR b.author LIKE :search OR b.isbn LIKE :search)";
}

if (!empty($category)) {
    $query .= " AND b.category = :category";
}

if (!empty($courseId)) {
    $query .= " AND bc.course_id = :course_id";
}

if (!empty($semester)) {
    $query .= " AND c.semester = :semester";
}

// Availability filter will be applied after fetching results
// Book type filter: Physical = has copies, Digital = has PDF
if (!empty($bookType)) {
    if ($bookType === 'Digital') {
        $query .= " AND dr.file_path IS NOT NULL";
    } elseif ($bookType === 'Physical') {
        $query .= " AND EXISTS (SELECT 1 FROM Book_Copies WHERE Book_Copies.isbn = b.isbn)";
    }
}

$query .= " ORDER BY b.title ASC";

$stmt = $db->prepare($query);

if (!empty($search)) {
    $search_param = "%{$search}%";
    $stmt->bindParam(":search", $search_param);
}

if (!empty($category)) {
    $stmt->bindParam(":category", $category);
}

if (!empty($courseId)) {
    $stmt->bindParam(":course_id", $courseId);
}

if (!empty($semester)) {
    $stmt->bindParam(":semester", $semester);
}

$stmt->execute();

$books = [];

while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
    // Count available copies
    $copiesStmt = $db->prepare('SELECT COUNT(*) as cnt FROM Book_Copies WHERE isbn = :isbn AND status = "Available"');
    $copiesStmt->execute([':isbn' => $row['isbn']]);
    $copiesAvailable = (int)$copiesStmt->fetch(PDO::FETCH_ASSOC)['cnt'];
    
    // Count total copies
    $totalCopiesStmt = $db->prepare('SELECT COUNT(*) as cnt FROM Book_Copies WHERE isbn = :isbn');
    $totalCopiesStmt->execute([':isbn' => $row['isbn']]);
    $totalCopies = (int)$totalCopiesStmt->fetch(PDO::FETCH_ASSOC)['cnt'];
    
    // Apply availability filter
    if (!empty($availability)) {
        if ($availability === 'Available' && $copiesAvailable === 0) {
            continue; // Skip books with no available copies
        } elseif ($availability === 'Not Available' && $copiesAvailable > 0) {
            continue; // Skip books with available copies
        }
    }
    
    // Build PDF URL if pdf_path exists
    $pdfUrl = null;
    if (!empty($row['pdf_path'])) {
        $pdfUrl = 'http://localhost:8000/serve_image.php?path=' . urlencode($row['pdf_path']);
    }
    
    $books[] = [
        'isbn' => $row['isbn'],
        'title' => $row['title'],
        'author' => $row['author'],
        'category' => $row['category'],
        'publisher' => $row['publisher'],
        'publication_year' => $row['publication_year'],
        'edition' => $row['edition'],
        'description' => $row['description'],
        'pic_path' => $row['pic_path'],
        'copies_available' => $copiesAvailable,
        'copies_total' => $totalCopies,
        'course_id' => $row['course_id'] ?? null,
        'pdf_url' => $pdfUrl,
    ];
}

http_response_code(200);
echo json_encode([
    'success' => true,
    'count' => count($books),
    'books' => $books,
]);
?>
