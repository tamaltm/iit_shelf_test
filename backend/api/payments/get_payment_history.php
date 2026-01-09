<?php
header('Content-Type: application/json');
include_once '../../config/database.php';

$database = new Database();
$db = $database->getConnection();

$userEmail = $_GET['user_email'] ?? null;

if (!$userEmail) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'user_email is required',
    ]);
    exit;
}

try {
    // Get payment history for the user (paid fines with their payment details)
    $query = 'SELECT 
        f.fine_id,
        f.amount,
        f.description,
        f.paid,
        f.payment_date,
        p.payment_id,
        p.status as payment_status
    FROM Fines f
    LEFT JOIN fine_payment fp ON f.fine_id = fp.fine_id
    LEFT JOIN Payments p ON fp.payment_id = p.payment_id
    WHERE f.user_email = :email AND f.paid = TRUE
    ORDER BY f.payment_date DESC
    LIMIT 50';

    $stmt = $db->prepare($query);
    $stmt->execute([':email' => $userEmail]);

    $payments = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $payments[] = [
            'fine_id' => (int)$row['fine_id'],
            'amount' => (float)$row['amount'],
            'description' => $row['description'],
            'paid' => (bool)$row['paid'],
            'payment_date' => $row['payment_date'],
            'payment_id' => $row['payment_id'] ? (int)$row['payment_id'] : null,
            'payment_status' => $row['payment_status'] ?? 'Completed',
        ];
    }

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'payment_history' => $payments,
        'total_payments' => count($payments),
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Database error: ' . $e->getMessage(),
    ]);
}
?>
