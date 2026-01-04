<?php
/**
 * Get User Profile
 * Retrieves user profile information including profile image
 */

require_once '../../config/database.php';

$database = new Database();
$db = $database->getConnection();

// Get email from request (JSON or POST)
$input = json_decode(file_get_contents('php://input'), true) ?? $_POST;
$email = isset($input['email']) ? strtolower(trim($input['email'])) : '';

if ($email === '') {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Email is required.'
    ]);
    exit;
}

// Get user profile
$stmt = $db->prepare('
    SELECT email, name, phone, role, profile_image, is_active, email_verified_at, created_at, last_login
    FROM users 
    WHERE email = :email
');
$stmt->execute([':email' => $email]);
$user = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$user) {
    http_response_code(404);
    echo json_encode([
        'success' => false,
        'message' => 'User not found.'
    ]);
    exit;
}

// Build full URL for profile image if it exists
$profileImageUrl = null;
if (!empty($user['profile_image'])) {
    // Image is stored as "uploads/profiles/filename.jpg"
    // API is at /api/auth/get_profile.php
    // So we go up 2 levels: ../../uploads/profiles/filename.jpg
    $profileImageUrl = 'http://localhost:8000/auth/get_image.php?path=' . urlencode($user['profile_image']);
}

// Return user profile
http_response_code(200);
echo json_encode([
    'success' => true,
    'user' => [
        'email' => $user['email'],
        'name' => $user['name'] ?? '',
        'phone' => $user['phone'] ?? '',
        'role' => $user['role'] ?? '',
        'profile_image' => $profileImageUrl,
        'is_active' => (bool)$user['is_active'],
        'email_verified' => !empty($user['email_verified_at']),
        'created_at' => $user['created_at'],
        'last_login' => $user['last_login'] ?? null
    ]
]);
