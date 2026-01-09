<?php
include_once '../../config/database.php';

$database = new Database();
$db = $database->getConnection();

$payload = json_decode(file_get_contents('php://input'));

$reservationId = $payload->reservation_id ?? null;

if (empty($reservationId)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'reservation_id is required',
    ]);
    exit;
}

try {
    $stmt = $db->prepare('UPDATE Reservations SET status = "Cancelled" WHERE reservation_id = :id AND status = "Active"');
    $stmt->bindParam(':id', $reservationId, PDO::PARAM_INT);
    $stmt->execute();

    if ($stmt->rowCount() > 0) {
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'message' => 'Reservation cancelled',
        ]);
    } else {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Reservation not found or already closed',
        ]);
    }
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Unable to cancel reservation: ' . $e->getMessage(),
    ]);
}
?>
