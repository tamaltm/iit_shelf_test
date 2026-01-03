<?php
include_once '../../config/database.php';

$database = new Database();
$db = $database->getConnection();

$data = json_decode(file_get_contents("php://input"));

if (!empty($data->user_id) && !empty($data->book_id)) {
    
    // Check if book is available
    $check_query = "SELECT available_quantity FROM books WHERE id = :book_id";
    $check_stmt = $db->prepare($check_query);
    $check_stmt->bindParam(":book_id", $data->book_id);
    $check_stmt->execute();
    
    $book = $check_stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($book['available_quantity'] > 0) {
        
        $db->beginTransaction();
        
        try {
            // Create borrow record
            $borrow_query = "INSERT INTO borrowed_books 
                           (user_id, book_id, borrow_date, due_date, status) 
                           VALUES 
                           (:user_id, :book_id, NOW(), DATE_ADD(NOW(), INTERVAL 14 DAY), 'borrowed')";
            
            $borrow_stmt = $db->prepare($borrow_query);
            $borrow_stmt->bindParam(":user_id", $data->user_id);
            $borrow_stmt->bindParam(":book_id", $data->book_id);
            $borrow_stmt->execute();
            
            // Update book quantity
            $update_query = "UPDATE books SET available_quantity = available_quantity - 1 WHERE id = :book_id";
            $update_stmt = $db->prepare($update_query);
            $update_stmt->bindParam(":book_id", $data->book_id);
            $update_stmt->execute();
            
            $db->commit();
            
            http_response_code(201);
            echo json_encode([
                "success" => true,
                "message" => "Book borrowed successfully",
                "borrow_id" => $db->lastInsertId()
            ]);
            
        } catch (Exception $e) {
            $db->rollBack();
            http_response_code(503);
            echo json_encode([
                "success" => false,
                "message" => "Unable to borrow book: " . $e->getMessage()
            ]);
        }
        
    } else {
        http_response_code(400);
        echo json_encode([
            "success" => false,
            "message" => "Book not available"
        ]);
    }
    
} else {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "User ID and Book ID are required"
    ]);
}
?>
