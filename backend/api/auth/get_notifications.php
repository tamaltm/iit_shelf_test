<?php
/**
 * Get Notifications for a User
 * Retrieves notifications for the authenticated user
 */

require_once '../../config/database.php';
require_once '../lib/notification_helpers.php';

$database = new Database();
$db = $database->getConnection();

// Get user email from request
$input = json_decode(file_get_contents('php://input'), true) ?? $_GET;
$email = isset($input['email']) ? strtolower(trim($input['email'])) : '';
$limit = isset($input['limit']) ? (int)$input['limit'] : 50;

if ($email === '') {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Email is required.'
    ]);
    exit;
}

try {
    $notifications = getUserNotifications($db, $email, $limit);
    
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'count' => count($notifications),
        'notifications' => $notifications
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Failed to fetch notifications: ' . $e->getMessage()
    ]);
}
?>
