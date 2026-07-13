const net = require('net');

console.log('📡 Probing Port 3306...');
const client = new net.Socket();

client.setTimeout(5000);

client.connect(3306, 'stardust-db-mumbai.cdgcqmimo5cs.ap-south-1.rds.amazonaws.com', function() {
	console.log('✅ Port 3306 is reachable from Node.js!');
	client.destroy();
});

client.on('error', function(err) {
	console.log('❌ Node.js cannot reach Port 3306: ' + err.message);
});

client.on('timeout', function() {
	console.log('❌ Connection timed out after 5 seconds.');
	client.destroy();
});
