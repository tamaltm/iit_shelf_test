<?php
require_once '../../config/database.php';
require_once '../lib/auth_helpers.php';

$database = new Database();
$db = $database->getConnection();

$input = json_input();
$email = isset($input['email']) ? strtolower(trim($input['email'])) : '';
$otp = $input['otp'] ?? '';
$newPassword = $input['new_password'] ?? '';

if ($email === '' || $otp === '' || $newPassword === '') {
    respond(400, [
        'success' => false,
        'message' => 'Email, OTP, and new password are required.',
    ]);
}

$check = $db->prepare('SELECT email FROM users WHERE email = :email');
$check->execute([':email' => $email]);
if (!$check->fetch(PDO::FETCH_ASSOC)) {
    respond(404, [
        'success' => false,
        'message' => 'User not found.',
    ]);
}

$valid = validate_otp($db, $email, 'PasswordReset', $otp);
if (!$valid['ok']) {
    respond(400, [
        'success' => false,
        'message' => $valid['message'] ?? 'Invalid OTP.',
    ]);
}

$hash = password_hash($newPassword, PASSWORD_BCRYPT);
$db->prepare('UPDATE users SET password_hash = :ph, updated_at = NOW() WHERE email = :email')
    ->execute([':ph' => $hash, ':email' => $email]);

$db->prepare('DELETE FROM temp_user_verification WHERE email = :email AND purpose = :purpose')
    ->execute([':email' => $email, ':purpose' => 'PasswordReset']);

respond(200, [
    'success' => true,
    'message' => 'Password reset successful.',
]);
?>
