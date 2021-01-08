const Server = require('bittorrent-tracker/server');
const { existsSync, unlinkSync, copyFileSync } = require('fs');
const { resolve } = require('path');
const { request } = require('http');

const server = new Server({
	udp: true,
	http: true,
	ws: true,
	stats: true,
	trustProxy: true,
	// filter:  function (infoHash, params, cb) {}
});

server.on('error', function (err) {
	console.error('ERROR: \x1B[2m%s\x1B[0m', err.stack);
});
server.on('warning', function (err) {
	console.log('WARNING: \x1B[2m%s\x1B[0m', err.message);
});
server.on('update', function (addr) {
	// console.log('update: ' + addr);
});
server.on('complete', function (addr) {
	// console.log('complete: ' + addr);
});
server.on('start', function (addr) {
	// console.log('start: ' + addr);
});
server.on('stop', function (addr) {
	// console.log('stop: ' + addr);
});

process.on('SIGINT', () => {
	console.log(' == SIGINT ==');
	beforeQuit(0);
});

const SOCKET_FILE = resolve(__dirname, process.env.SOCKET || '/run/sockets/bittorrent-tracker.sock');
if (existsSync(SOCKET_FILE)) {
	unlinkSync(SOCKET_FILE);
}

const UDP_PORT = 43079;

setTimeout(main, 100);
function main() {
	server.listen(
		{
			http: SOCKET_FILE,
			udp: UDP_PORT,
		},
		function () {
			printAddress('UDP tracker: udp://%s/', server.udp.address());
			printAddress('UDP6 tracker: udp://%s/', server.udp6.address());
			printAddress('HTTP/WebSocket tracker: ws://%s', server.http.address());
			printAddress('Tracker stats: http://%s/stats', server.http.address());

			addNginxFiles();
			Promise.resolve()
				.then(restartNginx)
				.then(() => {
					setTimeout(() => {
						console.log(' Ok, All setup.');
					}, 2000);
				}, die);
		}
	);
}

process.on('uncaughtException', (err) => {
	console.error('!! uncaughtException !!');
	console.error(err.stack);
	process.exit(1);
});
process.on('beforeExit', () => beforeQuit());

function beforeQuit(code = 0) {
	process.removeAllListeners('beforeExit');

	removeNginxFiles();
	Promise.resolve()
		.then(restartNginx)
		.then(
			() => {
				process.exit(code);
			},
			(e) => {
				console.error('[beforeExit] %s', e.message);
				process.exit(1);
			}
		);
}

function die(e) {
	console.error('Fatal%s', e.message);
	beforeQuit(1);
}

async function restartNginx() {
	console.log('=======================\nreload nginx:');
	await new Promise((resolve, reject) => {
		const req = request(
			'http://_/',
			{
				socketPath: '/run/sockets/nginx.reload.sock',
			},
			(res) => {
				res.on('data', (buff) => process.stdout.write(buff));
				res.on('error', (e) => {
					console.error("warning:", e);
				});
				res.on('end', () => resolve());
			}
		);
		req.end();
	});
	console.log('=======================');
}
async function addNginxFiles() {
	copyFileSync(resolve(__dirname, 'nginx-http.conf'), '/run/nginx/vhost.d/torrent-tracker.conf');
	copyFileSync(resolve(__dirname, 'nginx-udp.conf'), '/run/nginx/stream.d/torrent-tracker.conf');
}
async function removeNginxFiles() {
	try {
		unlinkSync('/run/nginx/vhost.d/torrent-tracker.conf');
	} catch (e) {
		console.error('Failed Unlink: ', e.message);
	}
	try {
		unlinkSync('/run/nginx/stream.d/torrent-tracker.conf');
	} catch (e) {
		console.error('Failed Unlink: ', e.message);
	}
}

/**
 * @param {string} message
 * @param {string | import("net").AddressInfo} address
 */
function printAddress(message, address) {
	console.log(message, typeof address === 'string' ? address : `${address.address}:${address.port}`);
}
