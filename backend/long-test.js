const net = require('net');

const HOST = 'stardust-db-mumbai.cdgcqmimo5cs.ap-south-1.rds.amazonaws.com';
const PORT = 3306;

console.log(`📡 Probing ${HOST}:${PORT} (30s timeout)...`);
const startTime = Date.now();

const client = net.createConnection({ port: PORT, host: HOST }, () => {
    const duration = (Date.now() - startTime) / 1000;
    console.log(`✅ SUCCESS! Connected in ${duration}s`);
    client.end();
});

client.on('error', (err) => {
    console.log(`❌ FAILED: ${err.message}`);
});

setTimeout(() => {
    console.log('⏳ Test timed out after 30s');
    process.exit(0);
}, 30000);
