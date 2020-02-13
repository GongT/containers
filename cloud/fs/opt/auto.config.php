<?php
$CONFIG = [];

if (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on') {
	$CONFIG['overwriteprotocol'] =  'https';
} else {
	$CONFIG['overwriteprotocol'] =  'http';
}
$CONFIG['overwritehost'] = $_SERVER['HTTP_HOST'];
