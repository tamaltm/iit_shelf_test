<?php
require_once '../../config/database.php';
require_once '../lib/auth_helpers.php';
require_once '../lib/mail_service.php';

$database = new Database();
$db = $database->getConnection();

$input = json_input();
$email = isset($input['email']) ? strtolower(trim($input['email'])) : '';
$phone = $input['phone'] ?? '';
$role = $input['role'] ?? 'Student';
$name = $input['name'] ?? '';

if ($email === '') {
    respond(400, [
        'success' => false,
        'message' => 'Email is required.',
    ]);
}

// Check existing user
$stmt = $db->prepare('SELECT email, email_verified_at FROM users WHERE email = :email');
$stmt->execute([':email' => $email]);
$user = $stmt->fetch(PDO::FETCH_ASSOC);

if ($user && !empty($user['email_verified_at'])) {
    respond(400, [
        'success' => false,
        'message' => 'Account already exists and is verified. Please sign in.',
    ]);
}

// Use placeholder password until user sets one after verification
$placeholderHash = password_hash(bin2hex(random_bytes(8)), PASSWORD_BCRYPT);

if ($user) {
    // Update unverified account metadata only
    $upd = $db->prepare('UPDATE users SET role = :role, phone = :phone, name = :name, updated_at = NOW() WHERE email = :email');
    $upd->execute([
        ':role' => $role,
        ':phone' => $phone,
        ':name' => $name,
        ':email' => $email,
    ]);
} else {
    // Insert new unverified account with placeholder password
    $ins = $db->prepare('INSERT INTO users (email, name, password_hash, role, phone, created_at, updated_at) VALUES (:email, :name, :ph, :role, :phone, NOW(), NOW())');
    $ins->execute([
        ':email' => $email,
        ':name' => $name,
        ':ph' => $placeholderHash,
        ':role' => $role,
        ':phone' => $phone,
    ]);
}

$otpResult = issue_otp($db, $email, 'EmailVerification');
if (!$otpResult['ok']) {
    $wait = $otpResult['wait'] ?? 60;
    respond(429, [
        'success' => false,
        'message' => "Please wait ${wait}s before requesting another code.",
        'retry_after' => $wait,
    ]);
}

// Send verification email
$emailSent = MailService::sendVerificationEmail($email, $otpResult['otp']);

respond(200, [
    'success' => true, // Always succeed in dev mode so user can proceed
    'message' => 'Verification code sent to your email. (Check server logs or /tmp/iit_shelf_otp.log)',
    'email' => $email,
    'otp' => $otpResult['otp'], // Return for development testing
]);
