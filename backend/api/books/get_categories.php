<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

include_once '../../config/database.php';

$database = new Database();
$db = $database->getConnection();

try {
    $sql = "SELECT DISTINCT category 
            FROM Books 
            WHERE category IS NOT NULL 
            AND category != '' 
            AND title NOT LIKE '[DELETED]%'
            ORDER BY category";
    
    $stmt = $db->prepare($sql);
    $stmt->execute();
    
    $categories = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $categories[] = $row['category'];
    }
    
    echo json_encode([
        'success' => true,
        'categories' => $categories
    ]);
    
} catch (PDOException $e) {
    error_log("Database error in get_categories.php: " . $e->getMessage());
    echo json_encode([
        'success' => false,
        'message' => 'Database error',
        'categories' => []
    ]);
}

