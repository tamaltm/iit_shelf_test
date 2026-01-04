<?php
include_once '../../config/database.php';

$database = new Database();
$db = $database->getConnection();

$search = isset($_GET['search']) ? $_GET['search'] : '';
$category = isset($_GET['category']) ? $_GET['category'] : '';

$query = "SELECT b.* FROM books b WHERE b.is_deleted = 0";

if (!empty($search)) {
    $query .= " AND (b.title LIKE :search OR b.author LIKE :search OR b.isbn LIKE :search)";
}

if (!empty($category)) {
    $query .= " AND b.category = :category";
}

$query .= " ORDER BY b.created_at DESC";

$stmt = $db->prepare($query);

if (!empty($search)) {
    $search_param = "%{$search}%";
    $stmt->bindParam(":search", $search_param);
}

if (!empty($category)) {
    $stmt->bindParam(":category", $category);
}

$stmt->execute();

$books = [];

while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
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
        'language' => $row['language'],
        'keywords' => $row['keywords'],
        'copies_total' => (int)$row['copies_total'],
        'copies_available' => (int)$row['copies_available'],
        'created_at' => $row['created_at'],
        'updated_at' => $row['updated_at'],
    ];
}

http_response_code(200);
echo json_encode([
    'success' => true,
    'count' => count($books),
    'books' => $books,
]);
?>
