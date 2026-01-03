<?php
include_once '../../config/database.php';

$database = new Database();
$db = $database->getConnection();

$search = isset($_GET['search']) ? $_GET['search'] : '';
$category = isset($_GET['category']) ? $_GET['category'] : '';
$shelf_id = isset($_GET['shelf_id']) ? $_GET['shelf_id'] : '';

$query = "SELECT b.*, s.shelf_name, s.location 
          FROM books b 
          LEFT JOIN shelves s ON b.shelf_id = s.id 
          WHERE 1=1";

if (!empty($search)) {
    $query .= " AND (b.title LIKE :search OR b.author LIKE :search OR b.isbn LIKE :search)";
}

if (!empty($category)) {
    $query .= " AND b.category = :category";
}

if (!empty($shelf_id)) {
    $query .= " AND b.shelf_id = :shelf_id";
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

if (!empty($shelf_id)) {
    $stmt->bindParam(":shelf_id", $shelf_id);
}

$stmt->execute();

$books = [];

while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
    $books[] = [
        "id" => $row['id'],
        "title" => $row['title'],
        "author" => $row['author'],
        "isbn" => $row['isbn'],
        "category" => $row['category'],
        "quantity" => $row['quantity'],
        "available_quantity" => $row['available_quantity'],
        "shelf_name" => $row['shelf_name'],
        "location" => $row['location'],
        "cover_image" => $row['cover_image'],
        "pdf_url" => $row['pdf_url'],
        "description" => $row['description']
    ];
}

http_response_code(200);
echo json_encode([
    "success" => true,
    "count" => count($books),
    "books" => $books
]);
?>
