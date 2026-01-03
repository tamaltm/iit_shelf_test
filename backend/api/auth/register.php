<?php
include_once '../../config/database.php';

$database = new Database();
$db = $database->getConnection();

$data = json_decode(file_get_contents("php://input"));

if (!empty($data->email) && !empty($data->password) && !empty($data->phone)) {
    
    // Check if email already exists
    $check_query = "SELECT id FROM users WHERE email = :email";
    $check_stmt = $db->prepare($check_query);
    $check_stmt->bindParam(":email", $data->email);
    $check_stmt->execute();
    
    if ($check_stmt->rowCount() > 0) {
        http_response_code(400);
        echo json_encode([
            "success" => false,
            "message" => "Email already exists"
        ]);
        exit();
    }
    
    $query = "INSERT INTO users (email, password, phone, role, created_at) 
              VALUES (:email, :password, :phone, :role, NOW())";
    
    $stmt = $db->prepare($query);
    
    $hashed_password = password_hash($data->password, PASSWORD_BCRYPT);
    $role = isset($data->role) ? $data->role : 'student';
    
    $stmt->bindParam(":email", $data->email);
    $stmt->bindParam(":password", $hashed_password);
    $stmt->bindParam(":phone", $data->phone);
    $stmt->bindParam(":role", $role);
    
    if ($stmt->execute()) {
        $user_id = $db->lastInsertId();
        
        http_response_code(201);
        echo json_encode([
            "success" => true,
            "message" => "User registered successfully",
            "user_id" => $user_id
        ]);
    } else {
        http_response_code(503);
        echo json_encode([
            "success" => false,
            "message" => "Unable to register user"
        ]);
    }
} else {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Incomplete data. Email, password and phone are required"
    ]);
}
?>
