<?php
include_once '../../config/database.php';

$database = new Database();
$db = $database->getConnection();

$data = json_decode(file_get_contents("php://input"));

if (!empty($data->borrow_id)) {
    
    $db->beginTransaction();
    
    try {
        // Get borrow details
        $check_query = "SELECT book_id, due_date FROM borrowed_books WHERE id = :borrow_id AND status = 'borrowed'";
        $check_stmt = $db->prepare($check_query);
        $check_stmt->bindParam(":borrow_id", $data->borrow_id);
        $check_stmt->execute();
        
        if ($check_stmt->rowCount() > 0) {
            $borrow = $check_stmt->fetch(PDO::FETCH_ASSOC);
            
            // Calculate fine if overdue
            $due_date = new DateTime($borrow['due_date']);
            $return_date = new DateTime();
            $fine = 0;
            
            if ($return_date > $due_date) {
                $days_overdue = $return_date->diff($due_date)->days;
                $fine = $days_overdue * 5; // 5 BDT per day
            }
            
            // Update borrow record
            $update_query = "UPDATE borrowed_books 
                           SET status = 'returned', return_date = NOW(), fine = :fine 
                           WHERE id = :borrow_id";
            $update_stmt = $db->prepare($update_query);
            $update_stmt->bindParam(":borrow_id", $data->borrow_id);
            $update_stmt->bindParam(":fine", $fine);
            $update_stmt->execute();
            
            // Update book quantity
            $book_query = "UPDATE books SET available_quantity = available_quantity + 1 WHERE id = :book_id";
            $book_stmt = $db->prepare($book_query);
            $book_stmt->bindParam(":book_id", $borrow['book_id']);
            $book_stmt->execute();
            
            $db->commit();
            
            http_response_code(200);
            echo json_encode([
                "success" => true,
                "message" => "Book returned successfully",
                "fine" => $fine
            ]);
            
        } else {
            $db->rollBack();
            http_response_code(404);
            echo json_encode([
                "success" => false,
                "message" => "Borrow record not found or already returned"
            ]);
        }
        
    } catch (Exception $e) {
        $db->rollBack();
        http_response_code(503);
        echo json_encode([
            "success" => false,
            "message" => "Unable to return book: " . $e->getMessage()
        ]);
    }
    
} else {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Borrow ID is required"
    ]);
}
?>
