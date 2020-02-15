<?php
$CONFIG = [];

// nginx always set HTTP_HOST
// CLI if not set
if (!empty($_SERVER['HTTP_HOST'])) {
	if (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on') {
		$CONFIG['overwriteprotocol'] =  'https';
	} else {
		$CONFIG['overwriteprotocol'] =  'http';
	}
	$CONFIG['overwritehost'] = $_SERVER['HTTP_HOST'];
}
