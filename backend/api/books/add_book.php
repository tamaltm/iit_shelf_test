<?php
include_once '../../config/database.php';

$database = new Database();
$db = $database->getConnection();

$data = json_decode(file_get_contents("php://input"));

if (!empty($data->title) && !empty($data->author) && !empty($data->isbn)) {
    
    $query = "INSERT INTO books 
              (title, author, isbn, category, quantity, available_quantity, shelf_id, cover_image, pdf_url, description, created_at) 
              VALUES 
              (:title, :author, :isbn, :category, :quantity, :available_quantity, :shelf_id, :cover_image, :pdf_url, :description, NOW())";
    
    $stmt = $db->prepare($query);
    
    $available_quantity = isset($data->available_quantity) ? $data->available_quantity : $data->quantity;
    
    $stmt->bindParam(":title", $data->title);
    $stmt->bindParam(":author", $data->author);
    $stmt->bindParam(":isbn", $data->isbn);
    $stmt->bindParam(":category", $data->category);
    $stmt->bindParam(":quantity", $data->quantity);
    $stmt->bindParam(":available_quantity", $available_quantity);
    $stmt->bindParam(":shelf_id", $data->shelf_id);
    $stmt->bindParam(":cover_image", $data->cover_image);
    $stmt->bindParam(":pdf_url", $data->pdf_url);
    $stmt->bindParam(":description", $data->description);
    
    if ($stmt->execute()) {
        $book_id = $db->lastInsertId();
        
        http_response_code(201);
        echo json_encode([
            "success" => true,
            "message" => "Book added successfully",
            "book_id" => $book_id
        ]);
    } else {
        http_response_code(503);
        echo json_encode([
            "success" => false,
            "message" => "Unable to add book"
        ]);
    }
} else {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Incomplete data. Title, author and ISBN are required"
    ]);
}
?>
