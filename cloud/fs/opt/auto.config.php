<?php
$CONFIG = [];

if (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on') {
	$except_port = 443;
	$CONFIG['overwriteprotocol'] =  'https';
} else {
	$except_port = 80;
	$CONFIG['overwriteprotocol'] =  'http';
}
if ($_SERVER['SERVER_PORT'] === $except_port) {
	$CONFIG['overwritehost'] = $_SERVER['HTTP_HOST'];
} else {
	$CONFIG['overwritehost'] = $_SERVER['HTTP_HOST'] . ':' . $_SERVER['SERVER_PORT'];
}
