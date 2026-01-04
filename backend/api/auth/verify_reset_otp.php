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
$lockout = OtpAttemptTracker::isLockedOut($email, 'PasswordReset');
if ($lockout['locked']) {
    OtpAttemptTracker::logAttempt($email, 'PasswordReset', false, 'Account locked - too many attempts');
    respond(429, [
        'success' => false,
        'message' => $lockout['message'],
        'retry_after' => $lockout['retry_after'],
    ]);
}

$valid = validate_otp($db, $email, 'PasswordReset', $otp);
if (!$valid['ok']) {
    $remaining = OtpAttemptTracker::getRemainingAttempts($email, 'PasswordReset');
    OtpAttemptTracker::logAttempt($email, 'PasswordReset', false, $valid['message'] ?? 'Invalid OTP');
    respond(400, [
        'success' => false,
        'message' => $valid['message'] ?? 'Invalid OTP.',
        'remaining_attempts' => $remaining,
    ]);
}

OtpAttemptTracker::logAttempt($email, 'PasswordReset', true, 'Reset OTP verified');

respond(200, [
    'success' => true,
    'message' => 'OTP is valid.',
]);
?>
