<?php
require_once '../../config/database.php';
require_once '../lib/auth_helpers.php';
require_once '../lib/mail_service.php';

$database = new Database();
$db = $database->getConnection();

$input = json_input();
$email = isset($input['email']) ? strtolower(trim($input['email'])) : '';
$password = $input['password'] ?? '';
$name = $input['name'] ?? '';
$role = $input['role'] ?? 'Student';
$phone = $input['phone'] ?? '';

if ($email === '' || $password === '') {
    respond(400, [
        'success' => false,
        'message' => 'Email and password are required.',
    ]);
}

// Check existing user
$stmt = $db->prepare('SELECT email, email_verified_at FROM users WHERE email = :email');
$stmt->execute([':email' => $email]);
$existing = $stmt->fetch(PDO::FETCH_ASSOC);

if ($existing && !empty($existing['email_verified_at'])) {
    respond(400, [
        'success' => false,
        'message' => 'Account already exists and is verified.',
    ]);
}

$hash = password_hash($password, PASSWORD_BCRYPT);

if ($existing) {
    // Update unverified account
    $upd = $db->prepare('UPDATE users SET password_hash = :ph, role = :role, name = :name, phone = :phone, updated_at = NOW() WHERE email = :email');
    $upd->execute([
        ':ph' => $hash,
        ':role' => $role,
        ':name' => $name,
        ':phone' => $phone,
        ':email' => $email,
    ]);
} else {
    // Insert new account (unverified)
    $ins = $db->prepare('INSERT INTO users (email, name, password_hash, role, phone, created_at, updated_at) VALUES (:email, :name, :ph, :role, :phone, NOW(), NOW())');
    $ins->execute([
        ':email' => $email,
        ':name' => $name,
        ':ph' => $hash,
        ':role' => $role,
        ':phone' => $phone,
    ]);
}

$otpResult = issue_otp($db, $email, 'EmailVerification');
if (!$otpResult['ok']) {
    $wait = $otpResult['wait'] ?? 60;
    respond(429, [
        'success' => false,
        'message' => "Please retry after {$wait} seconds.",
    ]);
}

// Send verification email
$emailSent = MailService::sendVerificationEmail($email, $otpResult['otp']);

respond(201, [
    'success' => true, // Always succeed in dev mode so user can proceed
    'message' => 'User registered. Verification code sent to your email. (Check server logs or /tmp/iit_shelf_otp.log)',
    'email' => $email,
    'otp' => $otpResult['otp'], // Return for development testing
]);
?>
