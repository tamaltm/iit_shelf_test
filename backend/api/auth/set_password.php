<?php
require_once '../../config/database.php';
require_once '../lib/auth_helpers.php';

$database = new Database();
$db = $database->getConnection();

$input = json_input();
$email = isset($input['email']) ? strtolower(trim($input['email'])) : '';
$newPassword = $input['new_password'] ?? '';
$name = isset($input['name']) ? trim($input['name']) : '';
$phone = isset($input['phone']) ? trim($input['phone']) : '';
$role = isset($input['role']) ? trim($input['role']) : 'Student';

if ($email === '' || $newPassword === '') {
    respond(400, [
        'success' => false,
        'message' => 'Email and new password are required.',
    ]);
}

$stmt = $db->prepare('SELECT email, email_verified_at FROM users WHERE email = :email');
$stmt->execute([':email' => $email]);
$user = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$user) {
    respond(404, [
        'success' => false,
        'message' => 'Account not found.',
    ]);
}

if (empty($user['email_verified_at'])) {
    respond(400, [
        'success' => false,
        'message' => 'Please verify your email before setting a password.',
    ]);
}

$hash = password_hash($newPassword, PASSWORD_BCRYPT);
$upd = $db->prepare('UPDATE users SET password_hash = :ph, name = :name, phone = :phone, role = :role, updated_at = NOW() WHERE email = :email');
$upd->execute([
    ':ph' => $hash,
    ':name' => $name ?: $email, // Use email as name if not provided
    ':phone' => $phone,
    ':role' => $role,
    ':email' => $email,
]);

respond(200, [
    'success' => true,
    'message' => 'Password set successfully. You can now sign in.',
]);
