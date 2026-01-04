<?php
require_once '../../config/database.php';
require_once '../lib/auth_helpers.php';
require_once '../lib/otp_attempt_tracker.php';

$database = new Database();
$db = $database->getConnection();

$input = json_input();
$email = isset($input['email']) ? strtolower(trim($input['email'])) : '';
$otp = $input['otp'] ?? '';

if ($email === '' || $otp === '') {
    respond(400, [
        'success' => false,
        'message' => 'Email and OTP are required.',
    ]);
}

// Check if account is locked due to failed attempts
$lockout = OtpAttemptTracker::isLockedOut($email, 'EmailVerification');
if ($lockout['locked']) {
    OtpAttemptTracker::logAttempt($email, 'EmailVerification', false, 'Account locked - too many attempts');
    respond(429, [
        'success' => false,
        'message' => $lockout['message'],
        'retry_after' => $lockout['retry_after'],
    ]);
}

$validate = validate_otp($db, $email, 'EmailVerification', $otp);
if (!$validate['ok']) {
    $remaining = OtpAttemptTracker::getRemainingAttempts($email, 'EmailVerification');
    OtpAttemptTracker::logAttempt($email, 'EmailVerification', false, $validate['message'] ?? 'Invalid OTP');
    respond(400, [
        'success' => false,
        'message' => $validate['message'] ?? 'Invalid OTP.',
        'remaining_attempts' => $remaining,
    ]);
}

$upd = $db->prepare('UPDATE users SET email_verified_at = NOW() WHERE email = :email');
$upd->execute([':email' => $email]);

$db->prepare('DELETE FROM temp_user_verification WHERE email = :email AND purpose = :purpose')
    ->execute([':email' => $email, ':purpose' => 'EmailVerification']);

OtpAttemptTracker::logAttempt($email, 'EmailVerification', true, 'Email verified');

respond(200, [
    'success' => true,
    'message' => 'Email verified successfully.',
]);
?>
