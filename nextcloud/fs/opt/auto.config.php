<?php
$CONFIG = [];

// nginx always set HTTP_HOST
// CLI if not set
if (!empty($_SERVER['HTTP_HOST'])) {
	if (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on') {
		$CONFIG['overwriteprotocol'] = 'https';
	} else {
		$CONFIG['overwriteprotocol'] = 'http';
	}
	$CONFIG['overwritehost'] = $_SERVER['HTTP_HOST'];
}

$CONFIG = array_replace($CONFIG, array(
	'logfile' => '/var/log/nextcloud/main.log',
	'logdateformat' => '',
	'mysql.utf8mb4' => true,
	'apps_paths' => [
		// Read-only location for apps shipped with Nextcloud and installed by apk.
		[
			'path' => '/usr/share/nextcloud/apps',
			'url' => '/apps',
			'writable' => false,
		],
		// Writable location for apps installed from AppStore.
		[
			'path' => '/var/lib/nextcloud/apps',
			'url' => '/apps-appstore',
			'writable' => true,
		],
	],
	'memcache.local' => '\OC\Memcache\Redis',
	'memcache.locking' => '\OC\Memcache\Redis',
	'redis' => array(
		'host' => '/run/redis/redis.sock',
		'port' => 0,
		'dbindex' => 0,
		'timeout' => 1.5,
	),
));
