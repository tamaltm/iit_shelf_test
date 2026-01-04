<?php
require_once '../../config/database.php';
require_once '../lib/auth_helpers.php';

$database = new Database();
$db = $database->getConnection();

$input = json_input();
$email = isset($input['email']) ? strtolower(trim($input['email'])) : '';
$password = $input['password'] ?? '';

if ($email === '' || $password === '') {
    respond(400, [
        'success' => false,
        'message' => 'Email and password are required.',
    ]);
}

$stmt = $db->prepare('SELECT email, password_hash, role, email_verified_at FROM users WHERE email = :email');
$stmt->execute([':email' => $email]);
$user = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$user) {
    respond(404, [
        'success' => false,
        'message' => 'User not found.',
    ]);
}

if (empty($user['email_verified_at'])) {
    respond(403, [
        'success' => false,
        'message' => 'Please verify your email before signing in.',
    ]);
}

if (!password_verify($password, $user['password_hash'])) {
    respond(401, [
        'success' => false,
        'message' => 'Invalid password.',
    ]);
}

$db->prepare('UPDATE users SET last_login = NOW() WHERE email = :email')->execute([':email' => $email]);

// TODO: issue JWT/session token; returning stub for now
respond(200, [
    'success' => true,
    'message' => 'Login successful.',
    'role' => $user['role'],
    'token' => 'demo-token',
]);
?>
