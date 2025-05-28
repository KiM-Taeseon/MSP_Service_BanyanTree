<?php
// available-keys.php
header('Content-Type: application/json');

$keysDir = '/var/www/sshkey/'; // sshkey 디렉토리 경로
$keys = glob($keysDir . '*.pem');

header('Content-Type: application/json');

$files = [];

if (is_dir($keysDir)) {
    $pemFiles = glob($keysDir . '*.pem');
    
    foreach ($pemFiles as $file) {
        $files[] = [
            'filename' => basename($file),
            'createdAt' => date('c', filemtime($file)) // ISO 8601 형식
        ];
    }
    
    // 생성시간 기준으로 내림차순 정렬
    usort($files, function($a, $b) {
        return strtotime($b['createdAt']) - strtotime($a['createdAt']);
    });
}

if ($keys === false) {
    echo json_encode(['error' => 'glob failed']);
    exit;
}

if (empty($keys)) {
    echo json_encode(['message' => 'no pem files found in dir', 'dir' => $keysDir]);
    exit;
}

echo json_encode($files);
?>
