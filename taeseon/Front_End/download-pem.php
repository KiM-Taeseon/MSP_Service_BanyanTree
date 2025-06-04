<?php
// download-pem.php
$filename = $_GET['file'] ?? '';
$filepath = '/var/www/sshkey/' . basename($filename);

if (!file_exists($filepath)) {
    http_response_code(404);
    echo "❌ 파일을 찾을 수 없습니다.";
    exit;
}

header('Content-Description: File Transfer');
header('Content-Type: application/octet-stream');
header('Content-Disposition: attachment; filename="' . basename($filepath) . '"');
header('Expires: 0');
header('Cache-Control: must-revalidate');
header('Pragma: public');
header('Content-Length: ' . filesize($filepath));
flush();
readfile($filepath);
exit;
?>

