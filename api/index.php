<?php
header('Content-Type: application/json');

// Configuration du projet
$config = [
    'type' => 'api',
    'backend' => 'php',
    'backend_version' => '8.4',
    'webserver' => 'apache',
    'database' => [
        'type' => 'mysql',
        'version' => 'latest',
        'name' => 'test',
        'user' => 'admin'
    ],
    'services' => [
        'mailpit' => 'true',
        'websocket' => 'false',
        'websocket_type' => 'socketio'
    ],
    'runtime' => [
        'php_version' => phpversion(),
        'server' => $_SERVER['SERVER_SOFTWARE'] ?? 'Unknown',
        'timestamp' => date('Y-m-d H:i:s')
    ]
];

echo json_encode([
    'message' => 'Hello from PHP API!',
    'config' => $config
], JSON_PRETTY_PRINT);
