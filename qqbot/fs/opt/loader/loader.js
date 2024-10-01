try{
	const { app } = require('electron/main');
	app.disableHardwareAcceleration();
} catch(e) {
	console.error('disableHardwareAcceleration(): %s', e.message);
}

require('/opt/app');
