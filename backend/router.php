<?php
/**
 * Simple router for the PHP development server
 * Maps requests to api/ subdirectories
 */

// Get the requested path
$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);

// Remove leading slash
$path = ltrim($path, '/');

// Handle the root request
if ($path === '' || $path === '/') {
    echo json_encode(['message' => 'API Server Running']);
    exit;
}

// Map requests to api/ directory
// If request already starts with 'api/', map directly. Otherwise, prefix 'api/'.
if (strpos($path, 'api/') === 0) {
    $file = __DIR__ . '/' . $path;
} else {
    $file = __DIR__ . '/api/' . $path;
}

// Check if file exists
if (is_file($file)) {
    // Change to the api directory so relative includes work correctly
    chdir(dirname($file));
    include $file;
    exit;
}

// Check if this is a serve_image.php request at the root level
if ($path === 'serve_image.php' || strpos($path, 'serve_image.php') === 0) {
    include __DIR__ . '/serve_image.php';
    exit;
}

// 404 - not found
http_response_code(404);
echo json_encode([
    'success' => false,
    'message' => 'Endpoint not found: ' . $path
]);
exit;
