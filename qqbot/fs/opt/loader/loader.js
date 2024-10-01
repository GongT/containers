try{
	const { app } = require('electron/main');
	app.disableHardwareAcceleration();
	console.error('successfully disabled GPU acceleration');
} catch(e) {
	console.error('disableHardwareAcceleration(): %s', e.message);
}

console.error('loading LiteLoaderQQNT');
require('/opt/app');
console.error('LiteLoaderQQNT load complete!!');
